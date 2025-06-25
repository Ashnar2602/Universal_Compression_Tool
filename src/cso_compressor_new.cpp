#include "cso_compressor.h"
#include <iostream>
#include <cstring>
#include <algorithm>
#include <zlib.h>
#include <filesystem>

// Se disponibile, includi LZ4
#ifdef HAVE_LZ4
#include <lz4.h>
#include <lz4hc.h>
#endif

namespace UniversalCompressor {

CSOCompressor::CSOCompressor(const CSOConfig& config)
    : config_(config), inputFile_(nullptr), outputFile_(nullptr),
      inputSize_(0), outputPos_(0), totalSectors_(0), currentSector_(0) {
    
    // Calcola dimensione blocco se auto
    if (config_.blockSize == 0) {
        config_.blockSize = CalculateBlockSize();
    }
    
    // Assicurati che sia potenza di 2 e almeno SECTOR_SIZE
    if (config_.blockSize < SECTOR_SIZE) {
        config_.blockSize = SECTOR_SIZE;
    }
    
    // Prepara buffer
    inputBuffer_.resize(config_.blockSize);
    outputBuffer_.resize(config_.blockSize * 2); // Spazio extra per compressione
}

CSOCompressor::~CSOCompressor() {
    CleanupCompression();
}

void CSOCompressor::SetProgressCallback(ProgressCallback callback) {
    progressCallback_ = callback;
}

TaskStatus CSOCompressor::Compress(const std::string& inputFile, const std::string& outputFile) {
    // Inizializza compressione
    if (!InitializeCompression(inputFile, outputFile)) {
        CleanupCompression();
        return TASK_ERROR;
    }

    UpdateProgress("Iniziando compressione CSO...");

    // Calcola numero totale di settori
    totalSectors_ = static_cast<uint32_t>((inputSize_ + SECTOR_SIZE - 1) / SECTOR_SIZE);
    
    // Scrivi header
    if (!WriteHeader()) {
        CleanupCompression();
        return TASK_ERROR;
    }

    // Riserva spazio per indice
    uint32_t indexSize = (totalSectors_ + 1) * sizeof(uint32_t);
    indexTable_.resize(totalSectors_ + 1);
    
    // Salta spazio per indice (lo scriveremo alla fine)
    outputPos_ = sizeof(CSOHeader) + indexSize;
    if (fseek(outputFile_, outputPos_, SEEK_SET) != 0) {
        CleanupCompression();
        return TASK_ERROR;
    }

    // Comprimi settori uno alla volta
    for (currentSector_ = 0; currentSector_ < totalSectors_; ++currentSector_) {
        // Segna posizione nell'indice
        indexTable_[currentSector_] = static_cast<uint32_t>(outputPos_);
        
        // Leggi settore
        if (!ReadInputSector(currentSector_, inputBuffer_.data())) {
            CleanupCompression();
            return TASK_ERROR;
        }

        // Controlla se è settore vuoto
        if (IsEmptySector(inputBuffer_.data(), SECTOR_SIZE)) {
            // Settore vuoto - salva come non compresso
            if (!WriteUncompressedSector(inputBuffer_.data(), currentSector_)) {
                CleanupCompression();
                return TASK_ERROR;
            }
        } else if (ShouldCompress(inputBuffer_.data(), SECTOR_SIZE)) {
            // Prova compressione
            int bestCompressedSize = -1;
            int bestAlgorithm = 0;
            
            // Prova Zlib se abilitato
            if (config_.algorithms & CSO_ALG_ZLIB) {
                int zlibSize = CompressWithZlib(inputBuffer_.data(), SECTOR_SIZE, 
                                              outputBuffer_.data(), outputBuffer_.size());
                if (zlibSize > 0 && (bestCompressedSize == -1 || zlibSize < bestCompressedSize)) {
                    bestCompressedSize = zlibSize;
                    bestAlgorithm = CSO_ALG_ZLIB;
                }
            }
            
            #ifdef HAVE_LZ4
            // Prova LZ4 se abilitato
            if (config_.algorithms & CSO_ALG_LZ4) {
                int lz4Size = CompressWithLZ4(inputBuffer_.data(), SECTOR_SIZE,
                                            outputBuffer_.data(), outputBuffer_.size());
                if (lz4Size > 0 && (bestCompressedSize == -1 || lz4Size < bestCompressedSize)) {
                    bestCompressedSize = lz4Size;
                    bestAlgorithm = CSO_ALG_LZ4;
                }
            }
            #endif

            // Usa risultato compresso se conveniente (almeno 10% di risparmio)
            if (bestCompressedSize > 0 && bestCompressedSize < SECTOR_SIZE * 0.9) {
                if (!WriteCompressedSector(outputBuffer_.data(), bestCompressedSize, currentSector_)) {
                    CleanupCompression();
                    return TASK_ERROR;
                }
            } else {
                // Compressione non conveniente, salva non compresso
                if (!WriteUncompressedSector(inputBuffer_.data(), currentSector_)) {
                    CleanupCompression();
                    return TASK_ERROR;
                }
            }
        } else {
            // Non comprimere questo settore
            if (!WriteUncompressedSector(inputBuffer_.data(), currentSector_)) {
                CleanupCompression();
                return TASK_ERROR;
            }
        }

        // Aggiorna progresso
        if (currentSector_ % 1000 == 0 || currentSector_ == totalSectors_ - 1) {
            UpdateProgress();
        }
    }

    // Segna fine nell'indice
    indexTable_[totalSectors_] = static_cast<uint32_t>(outputPos_);
    
    // Scrivi tabella indice
    if (!WriteIndexTable()) {
        CleanupCompression();
        return TASK_ERROR;
    }

    UpdateProgress("Compressione completata!");
    CleanupCompression();
    return TASK_SUCCESS;
}

bool CSOCompressor::InitializeCompression(const std::string& inputFile, const std::string& outputFile) {
    // Apri file input
    inputFile_ = fopen(inputFile.c_str(), "rb");
    if (!inputFile_) {
        std::cerr << "Errore: Non posso aprire " << inputFile << std::endl;
        return false;
    }

    // Ottieni dimensione file
    fseek(inputFile_, 0, SEEK_END);
    inputSize_ = ftell(inputFile_);
    fseek(inputFile_, 0, SEEK_SET);

    if (inputSize_ == 0) {
        std::cerr << "Errore: File input vuoto" << std::endl;
        return false;
    }

    // Apri file output
    outputFile_ = fopen(outputFile.c_str(), "wb");
    if (!outputFile_) {
        std::cerr << "Errore: Non posso creare " << outputFile << std::endl;
        return false;
    }

    outputPos_ = 0;
    return true;
}

void CSOCompressor::CleanupCompression() {
    if (inputFile_) {
        fclose(inputFile_);
        inputFile_ = nullptr;
    }
    if (outputFile_) {
        fclose(outputFile_);
        outputFile_ = nullptr;
    }
}

bool CSOCompressor::ReadInputSector(uint32_t sectorIndex, uint8_t* buffer) {
    uint64_t pos = static_cast<uint64_t>(sectorIndex) * SECTOR_SIZE;
    
    if (fseek(inputFile_, pos, SEEK_SET) != 0) {
        return false;
    }

    // Leggi fino a SECTOR_SIZE byte, anche se l'ultimo settore è parziale
    size_t toRead = SECTOR_SIZE;
    if (pos + SECTOR_SIZE > inputSize_) {
        toRead = inputSize_ - pos;
        // Riempi il resto con zeri
        memset(buffer + toRead, 0, SECTOR_SIZE - toRead);
    }

    if (toRead > 0) {
        size_t bytesRead = fread(buffer, 1, toRead, inputFile_);
        if (bytesRead != toRead) {
            return false;
        }
    }

    return true;
}

bool CSOCompressor::WriteCompressedSector(const uint8_t* data, uint32_t dataSize, uint32_t sectorIndex) {
    // Segna come compresso nell'indice (senza flag CSO_INDEX_UNCOMPRESSED)
    indexTable_[sectorIndex] = static_cast<uint32_t>(outputPos_);
    
    // Scrivi i dati compressi
    if (fwrite(data, 1, dataSize, outputFile_) != dataSize) {
        return false;
    }
    
    outputPos_ += dataSize;
    return true;
}

bool CSOCompressor::WriteUncompressedSector(const uint8_t* data, uint32_t sectorIndex) {
    // Segna come non compresso nell'indice (con flag CSO_INDEX_UNCOMPRESSED)
    indexTable_[sectorIndex] = static_cast<uint32_t>(outputPos_) | CSO_INDEX_UNCOMPRESSED;
    
    // Scrivi i dati non compressi
    if (fwrite(data, 1, SECTOR_SIZE, outputFile_) != SECTOR_SIZE) {
        return false;
    }
    
    outputPos_ += SECTOR_SIZE;
    return true;
}

int CSOCompressor::CompressWithZlib(const uint8_t* input, uint32_t inputSize, uint8_t* output, uint32_t outputSize) {
    z_stream strm;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    
    // Inizializza deflate con livello di compressione massimo
    if (deflateInit(&strm, Z_BEST_COMPRESSION) != Z_OK) {
        return -1;
    }
    
    strm.avail_in = inputSize;
    strm.next_in = const_cast<uint8_t*>(input);
    strm.avail_out = outputSize;
    strm.next_out = output;
    
    int result = deflate(&strm, Z_FINISH);
    deflateEnd(&strm);
    
    if (result == Z_STREAM_END) {
        return outputSize - strm.avail_out;
    }
    
    return -1;
}

#ifdef HAVE_LZ4
int CSOCompressor::CompressWithLZ4(const uint8_t* input, uint32_t inputSize, uint8_t* output, uint32_t outputSize) {
    if (config_.fastMode) {
        return LZ4_compress_default(reinterpret_cast<const char*>(input), 
                                   reinterpret_cast<char*>(output), 
                                   inputSize, outputSize);
    } else {
        return LZ4_compress_HC(reinterpret_cast<const char*>(input), 
                              reinterpret_cast<char*>(output), 
                              inputSize, outputSize, LZ4HC_CLEVEL_MAX);
    }
}
#else
int CSOCompressor::CompressWithLZ4(const uint8_t* input, uint32_t inputSize, uint8_t* output, uint32_t outputSize) {
    // LZ4 non disponibile
    return -1;
}
#endif

bool CSOCompressor::WriteHeader() {
    CSOHeader header;
    
    // Imposta magic in base al formato
    switch (config_.format) {
        case CSO_FORMAT_ZSO:
            memcpy(header.magic, ZSO_MAGIC, 4);
            break;
        case CSO_FORMAT_CSO1:
        case CSO_FORMAT_CSO2:
        case CSO_FORMAT_DAX:
        default:
            memcpy(header.magic, CSO_MAGIC, 4);
            break;
    }
    
    header.header_size = sizeof(CSOHeader);
    header.uncompressed_size = inputSize_;
    header.sector_size = SECTOR_SIZE;
    
    // Versione basata sul formato
    switch (config_.format) {
        case CSO_FORMAT_CSO2:
            header.version = 2;
            break;
        case CSO_FORMAT_ZSO:
            header.version = 1;
            break;
        default:
            header.version = 1;
            break;
    }
    
    // Calcola index_shift (log2 della dimensione settore)
    header.index_shift = SECTOR_SHIFT;
    
    // Reset unused
    memset(header.unused, 0, sizeof(header.unused));
    
    // Scrivi header
    if (fwrite(&header, sizeof(header), 1, outputFile_) != 1) {
        return false;
    }
    
    outputPos_ = sizeof(header);
    return true;
}

bool CSOCompressor::WriteIndexTable() {
    // Torna all'inizio per scrivere l'indice dopo l'header
    if (fseek(outputFile_, sizeof(CSOHeader), SEEK_SET) != 0) {
        return false;
    }
    
    // Scrivi tabella indice
    size_t indexEntries = totalSectors_ + 1;
    if (fwrite(indexTable_.data(), sizeof(uint32_t), indexEntries, outputFile_) != indexEntries) {
        return false;
    }
    
    return true;
}

void CSOCompressor::UpdateProgress(const std::string& status) {
    if (progressCallback_) {
        int progress = totalSectors_ > 0 ? 
                      (currentSector_ * 100) / totalSectors_ : 0;
        std::string msg = status.empty() ? 
                         "Compressione in corso..." : status;
        progressCallback_(progress, msg);
    }
}

uint32_t CSOCompressor::CalculateBlockSize() {
    // Logica simile a maxcso: usa blocchi più grandi per file grandi
    const uint64_t LARGE_BLOCK_THRESH = 0x80000000; // 2GB
    
    if (inputSize_ > LARGE_BLOCK_THRESH) {
        return 16384; // 16KB per file grandi
    } else {
        return 2048;  // 2KB per file piccoli
    }
}

bool CSOCompressor::ShouldCompress(const uint8_t* data, uint32_t size) {
    // Heuristica semplice: evita di comprimere dati che sembrano già compressi
    // o che hanno alta entropia
    
    if (IsEmptySector(data, size)) {
        return false; // I settori vuoti li gestiamo separatamente
    }
    
    // Conta byte unici nelle prime parti del settore
    std::array<bool, 256> seen = {};
    uint32_t uniqueBytes = 0;
    uint32_t checkSize = std::min(size, 512u); // Controlla primi 512 byte
    
    for (uint32_t i = 0; i < checkSize; ++i) {
        if (!seen[data[i]]) {
            seen[data[i]] = true;
            uniqueBytes++;
        }
    }
    
    // Se ci sono troppi byte unici, probabilmente è già compresso
    double uniqueRatio = static_cast<double>(uniqueBytes) / checkSize;
    return uniqueRatio < 0.8; // Comprimi solo se meno dell'80% dei byte sono unici
}

bool CSOCompressor::IsEmptySector(const uint8_t* data, uint32_t size) {
    // Controlla se il settore è completamente vuoto (tutti zeri)
    for (uint32_t i = 0; i < size; ++i) {
        if (data[i] != 0) {
            return false;
        }
    }
    return true;
}

} // namespace UniversalCompressor

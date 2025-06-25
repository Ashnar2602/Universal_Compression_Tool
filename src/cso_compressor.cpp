#include "cso_compressor.h"
#include <iostream>
#include <cstring>
#include <algorithm>
#include <zlib.h>

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
    fseek(outputFile_, outputPos_, SEEK_SET);

    // Comprimi settori uno alla volta
    for (currentSector_ = 0; currentSector_ < totalSectors_; ++currentSector_) {
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
            int compressedSize = -1;
            
            // Prova diversi algoritmi
            if (config_.algorithms & CSO_ALG_ZLIB) {
                compressedSize = CompressWithZlib(inputBuffer_.data(), SECTOR_SIZE, 
                                                outputBuffer_.data(), outputBuffer_.size());
            }
            
            #ifdef HAVE_LZ4
            if ((compressedSize == -1 || config_.fastMode) && (config_.algorithms & CSO_ALG_LZ4)) {
                int lz4Size = CompressWithLZ4(inputBuffer_.data(), SECTOR_SIZE,
                                            outputBuffer_.data(), outputBuffer_.size());
                if (lz4Size > 0 && (compressedSize == -1 || lz4Size < compressedSize)) {
                    compressedSize = lz4Size;
                }
            }
            #endif

            // Usa risultato compresso se conveniente
            if (compressedSize > 0 && compressedSize < SECTOR_SIZE * 0.9) {
                if (!WriteCompressedSector(outputBuffer_.data(), compressedSize, currentSector_)) {
                    CleanupCompression();
                    return TASK_ERROR;
                }
            } else {
                // Compressione non conveniente - salva non compresso
                if (!WriteUncompressedSector(inputBuffer_.data(), currentSector_)) {
                    CleanupCompression();
                    return TASK_ERROR;
                }
            }
        } else {
            // Non comprimere
            if (!WriteUncompressedSector(inputBuffer_.data(), currentSector_)) {
                CleanupCompression();
                return TASK_ERROR;
            }
        }

        // Aggiorna progresso
        if (currentSector_ % 1000 == 0 || currentSector_ == totalSectors_ - 1) {
            UpdateProgress("Comprimendo settore " + std::to_string(currentSector_ + 1) + 
                         " di " + std::to_string(totalSectors_));
        }
    }

    // Aggiungi ultimo indice
    indexTable_[totalSectors_] = static_cast<uint32_t>(outputPos_);

    // Scrivi tabella indici
    if (!WriteIndexTable()) {
        CleanupCompression();
        return TASK_ERROR;
    }

    UpdateProgress("Compressione CSO completata");
    CleanupCompression();
    return TASK_SUCCESS;
}

bool CSOCompressor::InitializeCompression(const std::string& inputFile, const std::string& outputFile) {
    // Apri file di input
    inputFile_ = fopen(inputFile.c_str(), "rb");
    if (!inputFile_) {
        return false;
    }

    // Ottieni dimensione file
    fseek(inputFile_, 0, SEEK_END);
    inputSize_ = ftell(inputFile_);
    fseek(inputFile_, 0, SEEK_SET);

    // Calcola numero settori
    totalSectors_ = static_cast<uint32_t>((inputSize_ + SECTOR_SIZE - 1) / SECTOR_SIZE);

    // Apri file di output
    outputFile_ = fopen(outputFile.c_str(), "wb");
    if (!outputFile_) {
        fclose(inputFile_);
        inputFile_ = nullptr;
        return false;
    }

    outputPos_ = 0;
    currentSector_ = 0;
    
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
    uint64_t offset = static_cast<uint64_t>(sectorIndex) * SECTOR_SIZE;
    
    if (fseek(inputFile_, offset, SEEK_SET) != 0) {
        return false;
    }
    
    // Leggi settore, riempi con zero se parziale
    size_t bytesRead = fread(buffer, 1, SECTOR_SIZE, inputFile_);
    if (bytesRead < SECTOR_SIZE) {
        memset(buffer + bytesRead, 0, SECTOR_SIZE - bytesRead);
    }
    
    return true;
}

bool CSOCompressor::WriteCompressedSector(const uint8_t* data, uint32_t dataSize, uint32_t sectorIndex) {
    // Salva posizione nell'indice
    indexTable_[sectorIndex] = static_cast<uint32_t>(outputPos_);
    
    // Scrivi dati compressi
    if (fwrite(data, 1, dataSize, outputFile_) != dataSize) {
        return false;
    }
    
    outputPos_ += dataSize;
    return true;
}

bool CSOCompressor::WriteUncompressedSector(const uint8_t* data, uint32_t sectorIndex) {
    // Salva posizione nell'indice con flag non compresso
    indexTable_[sectorIndex] = static_cast<uint32_t>(outputPos_) | CSO_INDEX_UNCOMPRESSED;
    
    // Scrivi dati non compressi
    if (fwrite(data, 1, SECTOR_SIZE, outputFile_) != SECTOR_SIZE) {
        return false;
    }
    
    outputPos_ += SECTOR_SIZE;
    return true;
}

int CSOCompressor::CompressWithZlib(const uint8_t* input, uint32_t inputSize, uint8_t* output, uint32_t outputSize) {
    uLongf compressedSize = outputSize;
    int level = config_.fastMode ? 1 : 9; // Livello compressione
    
    int result = compress2(output, &compressedSize, input, inputSize, level);
    
    if (result == Z_OK) {
        return static_cast<int>(compressedSize);
    }
    
    return -1; // Errore
}

int CSOCompressor::CompressWithLZ4(const uint8_t* input, uint32_t inputSize, uint8_t* output, uint32_t outputSize) {
    #ifdef HAVE_LZ4
    if (config_.fastMode) {
        return LZ4_compress_default(reinterpret_cast<const char*>(input), 
                                  reinterpret_cast<char*>(output), 
                                  inputSize, outputSize);
    } else {
        return LZ4_compress_HC(reinterpret_cast<const char*>(input), 
                             reinterpret_cast<char*>(output), 
                             inputSize, outputSize, LZ4HC_CLEVEL_MAX);
    }
    #else
    return -1; // LZ4 non disponibile
    #endif
}

bool CSOCompressor::WriteHeader() {
    CSOHeader header = {};
    
    // Magic number basato sul formato
    switch (config_.format) {
        case CSO_FORMAT_CSO1:
        case CSO_FORMAT_CSO2:
            memcpy(header.magic, CSO_MAGIC, 4);
            break;
        case CSO_FORMAT_ZSO:
            memcpy(header.magic, ZSO_MAGIC, 4);
            break;
        default:
            memcpy(header.magic, CSO_MAGIC, 4);
            break;
    }
    
    header.header_size = sizeof(CSOHeader);
    header.uncompressed_size = inputSize_;
    header.sector_size = SECTOR_SIZE;
    header.version = (config_.format == CSO_FORMAT_CSO2) ? 2 : 1;
    header.index_shift = SECTOR_SHIFT;
    
    // Scrivi header
    if (fwrite(&header, sizeof(header), 1, outputFile_) != 1) {
        return false;
    }
    
    outputPos_ = sizeof(header);
    return true;
}

bool CSOCompressor::WriteIndexTable() {
    // Vai all'inizio della tabella indici
    if (fseek(outputFile_, sizeof(CSOHeader), SEEK_SET) != 0) {
        return false;
    }
    
    // Scrivi tabella
    size_t indexCount = totalSectors_ + 1;
    if (fwrite(indexTable_.data(), sizeof(uint32_t), indexCount, outputFile_) != indexCount) {
        return false;
    }
    
    return true;
}

void CSOCompressor::UpdateProgress(const std::string& status) {
    if (progressCallback_) {
        int progress = 0;
        if (totalSectors_ > 0) {
            progress = (currentSector_ * 100) / totalSectors_;
        }
        progressCallback_(progress, status);
    }
}

uint32_t CSOCompressor::CalculateBlockSize() {
    // Logica di autodetect simile a maxcso
    if (inputSize_ > 0x80000000ULL) { // > 2GB
        return 16384;
    } else {
        return 2048;
    }
}

bool CSOCompressor::ShouldCompress(const uint8_t* data, uint32_t size) {
    // Controlla se vale la pena comprimere
    // Salta settori che sembrano già compressi o random
    
    // Conta byte unici
    bool seen[256] = {};
    uint32_t uniqueBytes = 0;
    
    for (uint32_t i = 0; i < size; ++i) {
        if (!seen[data[i]]) {
            seen[data[i]] = true;
            uniqueBytes++;
        }
    }
    
    // Se troppi byte unici, probabilmente già compresso
    return uniqueBytes < 250;
}

bool CSOCompressor::IsEmptySector(const uint8_t* data, uint32_t size) {
    // Controlla se il settore è tutto zero
    for (uint32_t i = 0; i < size; ++i) {
        if (data[i] != 0) {
            return false;
        }
    }
    return true;
}

} // namespace UniversalCompressor

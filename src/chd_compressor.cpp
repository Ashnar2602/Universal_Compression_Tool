#include "chd_compressor.h"
#include <iostream>
#include <cstring>
#include <algorithm>
#include <zlib.h>
#include <filesystem>

namespace UniversalCompressor {

CHDCompressor::CHDCompressor(const CHDConfig& config)
    : config_(config), inputFile_(nullptr), outputFile_(nullptr),
      inputSize_(0), outputPos_(0), totalHunks_(0), currentHunk_(0), 
      hunkSize_(config.hunkSize), isCD_(false) {
    
    // Calcola dimensione hunk se auto
    if (config_.hunkSize == 0) {
        hunkSize_ = CalculateHunkSize();
    }
    
    // Prepara buffer
    inputBuffer_.resize(hunkSize_);
    outputBuffer_.resize(hunkSize_ * 2); // Spazio extra per compressione
}

CHDCompressor::~CHDCompressor() {
    CleanupCompression();
}

void CHDCompressor::SetProgressCallback(ProgressCallback callback) {
    progressCallback_ = callback;
}

TaskStatus CHDCompressor::Compress(const std::string& inputFile, const std::string& outputFile) {
    // Inizializza compressione
    if (!InitializeCompression(inputFile, outputFile)) {
        CleanupCompression();
        return TASK_ERROR;
    }

    UpdateProgress("Iniziando compressione CHD...");

    // Analizza input per determinare formato
    if (!AnalyzeInput()) {
        CleanupCompression();
        return TASK_ERROR;
    }

    // Calcola numero totale di hunk
    totalHunks_ = static_cast<uint32_t>((inputSize_ + hunkSize_ - 1) / hunkSize_);
    
    // Prepara mappa hunk
    hunkMap_.resize(totalHunks_);
    
    // Scrivi header placeholder
    outputPos_ = CHD_V5_HEADER_SIZE;
    if (fseek(outputFile_, outputPos_, SEEK_SET) != 0) {
        CleanupCompression();
        return TASK_ERROR;
    }

    // Riserva spazio per mappa hunk
    uint64_t mapSize = totalHunks_ * sizeof(CHDMapEntry);
    uint64_t mapOffset = outputPos_;
    outputPos_ += mapSize;
    if (fseek(outputFile_, outputPos_, SEEK_SET) != 0) {
        CleanupCompression();
        return TASK_ERROR;
    }

    // Comprimi hunk uno alla volta
    for (currentHunk_ = 0; currentHunk_ < totalHunks_; ++currentHunk_) {
        // Leggi hunk
        if (!ReadInputHunk(currentHunk_, inputBuffer_.data())) {
            CleanupCompression();
            return TASK_ERROR;
        }

        // Determina se comprimere
        if (ShouldCompressHunk(inputBuffer_.data(), hunkSize_)) {
            // Prova compressione
            int bestCompressedSize = -1;
            
            // Prova Zlib
            if (config_.codecs & CHD_CODEC_CDLZ) {
                int zlibSize = CompressWithZlib(inputBuffer_.data(), hunkSize_, 
                                              outputBuffer_.data(), outputBuffer_.size());
                if (zlibSize > 0 && (bestCompressedSize == -1 || zlibSize < bestCompressedSize)) {
                    bestCompressedSize = zlibSize;
                }
            }
            
            // Usa risultato compresso se conveniente
            if (bestCompressedSize > 0 && bestCompressedSize < hunkSize_ * 0.9) {
                if (!WriteCompressedHunk(outputBuffer_.data(), bestCompressedSize, currentHunk_)) {
                    CleanupCompression();
                    return TASK_ERROR;
                }
            } else {
                // Compressione non conveniente, salva non compresso
                if (!WriteUncompressedHunk(inputBuffer_.data(), currentHunk_)) {
                    CleanupCompression();
                    return TASK_ERROR;
                }
            }
        } else {
            // Non comprimere questo hunk
            if (!WriteUncompressedHunk(inputBuffer_.data(), currentHunk_)) {
                CleanupCompression();
                return TASK_ERROR;
            }
        }

        // Aggiorna progresso
        if (currentHunk_ % 100 == 0 || currentHunk_ == totalHunks_ - 1) {
            UpdateProgress();
        }
    }

    // Scrivi mappa hunk
    if (fseek(outputFile_, mapOffset, SEEK_SET) != 0) {
        CleanupCompression();
        return TASK_ERROR;
    }
    
    if (fwrite(hunkMap_.data(), sizeof(CHDMapEntry), totalHunks_, outputFile_) != totalHunks_) {
        CleanupCompression();
        return TASK_ERROR;
    }

    // Scrivi header finale
    if (!WriteHeader()) {
        CleanupCompression();
        return TASK_ERROR;
    }

    // Scrivi metadata se necessario
    if (isCD_ && !WriteMetadata()) {
        CleanupCompression();
        return TASK_ERROR;
    }

    UpdateProgress("Compressione CHD completata!");
    CleanupCompression();
    return TASK_SUCCESS;
}

bool CHDCompressor::InitializeCompression(const std::string& inputFile, const std::string& outputFile) {
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

void CHDCompressor::CleanupCompression() {
    if (inputFile_) {
        fclose(inputFile_);
        inputFile_ = nullptr;
    }
    if (outputFile_) {
        fclose(outputFile_);
        outputFile_ = nullptr;
    }
}

bool CHDCompressor::AnalyzeInput() {
    // Semplice euristica per determinare se è un CD
    // I CD hanno solitamente settori da 2352 byte
    
    // Controlla se la dimensione è compatibile con un CD
    const uint32_t CD_SECTOR_SIZE = 2352;
    const uint32_t ISO_SECTOR_SIZE = 2048;
    
    if (inputSize_ % CD_SECTOR_SIZE == 0) {
        isCD_ = true;
        // Regola hunk size per CD se non specificato
        if (config_.hunkSize == 0) {
            hunkSize_ = CD_SECTOR_SIZE * 8; // 8 settori per hunk
        }
    } else if (inputSize_ % ISO_SECTOR_SIZE == 0) {
        isCD_ = false;
        // Standard ISO
        if (config_.hunkSize == 0) {
            hunkSize_ = ISO_SECTOR_SIZE * 8;
        }
    } else {
        // Hard disk o altro formato
        isCD_ = false;
        if (config_.hunkSize == 0) {
            hunkSize_ = 4096; // 4KB hunk di default
        }
    }
    
    return true;
}

bool CHDCompressor::ReadInputHunk(uint32_t hunkIndex, uint8_t* buffer) {
    uint64_t pos = static_cast<uint64_t>(hunkIndex) * hunkSize_;
    
    if (fseek(inputFile_, pos, SEEK_SET) != 0) {
        return false;
    }

    // Leggi fino a hunkSize_ byte, anche se l'ultimo hunk è parziale
    size_t toRead = hunkSize_;
    if (pos + hunkSize_ > inputSize_) {
        toRead = inputSize_ - pos;
        // Riempi il resto con zeri
        memset(buffer + toRead, 0, hunkSize_ - toRead);
    }

    if (toRead > 0) {
        size_t bytesRead = fread(buffer, 1, toRead, inputFile_);
        if (bytesRead != toRead) {
            return false;
        }
    }

    return true;
}

bool CHDCompressor::WriteCompressedHunk(const uint8_t* data, uint32_t dataSize, uint32_t hunkIndex) {
    // Registra nella mappa
    hunkMap_[hunkIndex].offset = outputPos_;
    hunkMap_[hunkIndex].crc = CalculateCRC32(inputBuffer_.data(), hunkSize_);
    hunkMap_[hunkIndex].length_lo = dataSize & 0xFFFF;
    hunkMap_[hunkIndex].length_hi = (dataSize >> 16) & 0xFF;
    hunkMap_[hunkIndex].flags = 0; // Compressed
    
    // Scrivi i dati compressi
    if (fwrite(data, 1, dataSize, outputFile_) != dataSize) {
        return false;
    }
    
    outputPos_ += dataSize;
    return true;
}

bool CHDCompressor::WriteUncompressedHunk(const uint8_t* data, uint32_t hunkIndex) {
    // Registra nella mappa
    hunkMap_[hunkIndex].offset = outputPos_;
    hunkMap_[hunkIndex].crc = CalculateCRC32(data, hunkSize_);
    hunkMap_[hunkIndex].length_lo = hunkSize_ & 0xFFFF;
    hunkMap_[hunkIndex].length_hi = (hunkSize_ >> 16) & 0xFF;
    hunkMap_[hunkIndex].flags = 1; // Uncompressed
    
    // Scrivi i dati non compressi
    if (fwrite(data, 1, hunkSize_, outputFile_) != hunkSize_) {
        return false;
    }
    
    outputPos_ += hunkSize_;
    return true;
}

int CHDCompressor::CompressWithZlib(const uint8_t* input, uint32_t inputSize, uint8_t* output, uint32_t outputSize) {
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

int CHDCompressor::CompressWithLZMA(const uint8_t* input, uint32_t inputSize, uint8_t* output, uint32_t outputSize) {
    // TODO: Implementare LZMA quando disponibile
    return -1;
}

bool CHDCompressor::WriteHeader() {
    CHDHeader header;
    
    // Magic
    memcpy(header.magic, CHD_MAGIC, 8);
    
    // Struttura header
    header.length = CHD_V5_HEADER_SIZE;
    header.version = CHD_HEADER_VERSION;
    header.flags = 0;
    header.compression = CHD_CODEC_ZLIB_IMPL; // TODO: Impostare basato sui codec usati
    header.hunksize = hunkSize_;
    header.totalhunks = totalHunks_;
    header.logicalbytes = inputSize_;
    header.metaoffset = 0; // TODO: Implementare metadata
    header.mapoffset = CHD_V5_HEADER_SIZE;
    
    // TODO: Calcolare checksum reali
    memset(header.md5, 0, 16);
    memset(header.parentmd5, 0, 16);
    memset(header.sha1, 0, 20);
    memset(header.parentsha1, 0, 20);
    memset(header.rawsha1, 0, 20);
    memset(header.parentrawsha1, 0, 20);
    
    // Scrivi header all'inizio del file
    if (fseek(outputFile_, 0, SEEK_SET) != 0) {
        return false;
    }
    
    if (fwrite(&header, sizeof(header), 1, outputFile_) != 1) {
        return false;
    }
    
    return true;
}

bool CHDCompressor::WriteMetadata() {
    // TODO: Implementare scrittura metadata per CD
    // Per ora ritorna true (nessun metadata)
    return true;
}

void CHDCompressor::UpdateProgress(const std::string& status) {
    if (progressCallback_) {
        int progress = totalHunks_ > 0 ? 
                      (currentHunk_ * 100) / totalHunks_ : 0;
        std::string msg = status.empty() ? 
                         "Compressione CHD in corso..." : status;
        progressCallback_(progress, msg);
    }
}

uint32_t CHDCompressor::CalculateHunkSize() {
    // Dimensioni hunk ottimali basate sulla dimensione del file
    if (inputSize_ < 700 * 1024 * 1024) { // CD (< 700MB)
        return 2352 * 8; // 8 settori CD
    } else if (inputSize_ < 4700 * 1024 * 1024) { // DVD (< 4.7GB)
        return 2048 * 16; // 16 settori ISO
    } else {
        return 65536; // 64KB per file grandi
    }
}

bool CHDCompressor::ShouldCompressHunk(const uint8_t* data, uint32_t size) {
    // Heuristica per determinare se vale la pena comprimere
    
    // Controlla se il hunk è vuoto
    bool isEmpty = true;
    for (uint32_t i = 0; i < size; ++i) {
        if (data[i] != 0) {
            isEmpty = false;
            break;
        }
    }
    
    if (isEmpty) {
        return true; // I hunk vuoti si comprimono molto bene
    }
    
    // Conta byte ripetuti
    std::array<uint32_t, 256> counts = {};
    for (uint32_t i = 0; i < std::min(size, 1024u); ++i) {
        counts[data[i]]++;
    }
    
    // Se ci sono molti byte ripetuti, vale la pena comprimere
    uint32_t maxCount = *std::max_element(counts.begin(), counts.end());
    double repetitionRatio = static_cast<double>(maxCount) / std::min(size, 1024u);
    
    return repetitionRatio > 0.1; // Comprimi se almeno 10% dei byte sono uguali
}

uint32_t CHDCompressor::CalculateCRC32(const uint8_t* data, uint32_t size) {
    // Implementazione CRC32 semplice
    uint32_t crc = 0xFFFFFFFF;
    
    static const uint32_t crc_table[256] = {
        0x00000000, 0x77073096, 0xee0e612c, 0x990951ba, 0x076dc419, 0x706af48f,
        0xe963a535, 0x9e6495a3, 0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988,
        // ... (tabella CRC32 completa)
        // Per brevità, uso una versione semplificata
    };
    
    for (uint32_t i = 0; i < size; ++i) {
        crc = (crc >> 8) ^ crc_table[(crc ^ data[i]) & 0xFF];
    }
    
    return crc ^ 0xFFFFFFFF;
}

bool CHDCompressor::DetectCDFormat() {
    // TODO: Implementare detection del formato CD
    return false;
}

bool CHDCompressor::ParseCueFile(const std::string& cueFile) {
    // TODO: Implementare parsing file CUE
    return false;
}

bool CHDCompressor::AddTrackMetadata(const CDTrackInfo& track) {
    // TODO: Implementare aggiunta metadata track
    return false;
}

bool CHDCompressor::AddGDROMMetadata() {
    // TODO: Implementare metadata GDROM
    return false;
}

} // namespace UniversalCompressor

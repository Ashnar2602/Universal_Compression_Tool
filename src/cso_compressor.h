#ifndef CSO_COMPRESSOR_H
#define CSO_COMPRESSOR_H

#include "universal_compressor.h"
#include <cstdint>
#include <vector>
#include <memory>
#include <functional>

namespace UniversalCompressor {

// Costanti CSO (da maxcso)
static const char* CSO_MAGIC = "CISO";
static const char* ZSO_MAGIC = "ZISO";
static const uint32_t CSO_INDEX_UNCOMPRESSED = 0x80000000;
static const uint32_t CSO2_INDEX_LZ4 = 0x80000000;
static const uint32_t SECTOR_SIZE = 0x800;
static const uint32_t SECTOR_MASK = 0x7FF;
static const uint8_t SECTOR_SHIFT = 11;

// Header CSO
#pragma pack(push, 1)
struct CSOHeader {
    char magic[4];
    uint32_t header_size;
    uint64_t uncompressed_size;
    uint32_t sector_size;
    uint8_t version;
    uint8_t index_shift;
    uint8_t unused[2];
};
#pragma pack(pop)

// Classe per compressione CSO
class CSOCompressor {
public:
    explicit CSOCompressor(const CSOConfig& config);
    ~CSOCompressor();

    // Compressione principale
    TaskStatus Compress(const std::string& inputFile, const std::string& outputFile);

    // Callback per progresso
    using ProgressCallback = std::function<void(int progress, const std::string& status)>;
    void SetProgressCallback(ProgressCallback callback);

private:
    // Configurazione
    CSOConfig config_;
    ProgressCallback progressCallback_;

    // Buffer e stato
    std::vector<uint8_t> inputBuffer_;
    std::vector<uint8_t> outputBuffer_;
    std::vector<uint32_t> indexTable_;
    
    // File handles
    FILE* inputFile_;
    FILE* outputFile_;
    
    uint64_t inputSize_;
    uint64_t outputPos_;
    uint32_t totalSectors_;
    uint32_t currentSector_;

    // Metodi interni
    bool InitializeCompression(const std::string& inputFile, const std::string& outputFile);
    void CleanupCompression();
    
    bool ReadInputSector(uint32_t sectorIndex, uint8_t* buffer);
    bool WriteCompressedSector(const uint8_t* data, uint32_t dataSize, uint32_t sectorIndex);
    bool WriteUncompressedSector(const uint8_t* data, uint32_t sectorIndex);
    
    // Algoritmi di compressione
    int CompressWithZlib(const uint8_t* input, uint32_t inputSize, uint8_t* output, uint32_t outputSize);
    int CompressWithLZ4(const uint8_t* input, uint32_t inputSize, uint8_t* output, uint32_t outputSize);
    
    // Utilità
    bool WriteHeader();
    bool WriteIndexTable();
    void UpdateProgress(const std::string& status = "");
    
    uint32_t CalculateBlockSize();
    bool ShouldCompress(const uint8_t* data, uint32_t size);
    bool IsEmptySector(const uint8_t* data, uint32_t size);
};

} // namespace UniversalCompressor

#endif // CSO_COMPRESSOR_H

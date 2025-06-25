#ifndef CHD_COMPRESSOR_H
#define CHD_COMPRESSOR_H

#include "universal_compressor.h"
#include <cstdint>
#include <vector>
#include <memory>
#include <functional>

namespace UniversalCompressor {

// Costanti CHD (basate su MAME chdman)
static const char* CHD_MAGIC = "MComprHD";
static const uint32_t CHD_HEADER_VERSION = 5;
static const uint32_t CHD_V5_HEADER_SIZE = 124;
static const uint32_t CHD_MAX_HEADER_SIZE = 124;

// Codec CHD (costanti specifiche per l'implementazione)
static const uint32_t CHD_CODEC_ZLIB_IMPL = 1;
static const uint32_t CHD_CODEC_LZMA_IMPL = 2;
static const uint32_t CHD_CODEC_HUFFMAN_IMPL = 3;
static const uint32_t CHD_CODEC_FLAC_IMPL = 4;

// Strutture CHD
#pragma pack(push, 1)
struct CHDHeader {
    char magic[8];           // "MComprHD"
    uint32_t length;         // Length of header
    uint32_t version;        // Drive format version
    uint32_t flags;          // Flags field
    uint32_t compression;    // Compression type
    uint32_t hunksize;       // Size of each hunk
    uint32_t totalhunks;     // Total # of hunks
    uint64_t logicalbytes;   // Logical size of the data
    uint64_t metaoffset;     // Offset to first metadata
    uint64_t mapoffset;      // Offset to hunk map
    uint8_t md5[16];         // MD5 checksum
    uint8_t parentmd5[16];   // Parent MD5 checksum
    uint8_t sha1[20];        // SHA1 checksum
    uint8_t parentsha1[20];  // Parent SHA1 checksum
    uint8_t rawsha1[20];     // Raw SHA1 checksum
    uint8_t parentrawsha1[20]; // Parent raw SHA1 checksum
};

struct CHDMapEntry {
    uint64_t offset;         // Offset to hunk data
    uint32_t crc;           // CRC of uncompressed data
    uint16_t length_lo;     // Lower 16 bits of length
    uint8_t length_hi;      // Upper 8 bits of length
    uint8_t flags;          // Flags
};
#pragma pack(pop)

// Metadata per CD
struct CDTrackInfo {
    uint32_t trackNumber;
    std::string trackType;
    uint32_t subType;
    uint32_t dataSize;
    uint32_t subSize;
    uint32_t frames;
    uint32_t pregap;
    uint32_t postgap;
};

// Classe per compressione CHD
class CHDCompressor {
public:
    explicit CHDCompressor(const CHDConfig& config);
    ~CHDCompressor();

    // Compressione principale
    TaskStatus Compress(const std::string& inputFile, const std::string& outputFile);

    // Callback per progresso
    using ProgressCallback = std::function<void(int progress, const std::string& status)>;
    void SetProgressCallback(ProgressCallback callback);

private:
    // Configurazione
    CHDConfig config_;
    ProgressCallback progressCallback_;

    // Buffer e stato
    std::vector<uint8_t> inputBuffer_;
    std::vector<uint8_t> outputBuffer_;
    std::vector<CHDMapEntry> hunkMap_;
    
    // File handles
    FILE* inputFile_;
    FILE* outputFile_;
    
    uint64_t inputSize_;
    uint64_t outputPos_;
    uint32_t totalHunks_;
    uint32_t currentHunk_;
    uint32_t hunkSize_;

    // CD specifico
    std::vector<CDTrackInfo> tracks_;
    bool isCD_;

    // Metodi interni
    bool InitializeCompression(const std::string& inputFile, const std::string& outputFile);
    void CleanupCompression();
    
    bool AnalyzeInput();
    bool DetectCDFormat();
    bool ParseCueFile(const std::string& cueFile);
    
    bool ReadInputHunk(uint32_t hunkIndex, uint8_t* buffer);
    bool WriteCompressedHunk(const uint8_t* data, uint32_t dataSize, uint32_t hunkIndex);
    bool WriteUncompressedHunk(const uint8_t* data, uint32_t hunkIndex);
    
    // Algoritmi di compressione CHD
    int CompressWithZlib(const uint8_t* input, uint32_t inputSize, uint8_t* output, uint32_t outputSize);
    int CompressWithLZMA(const uint8_t* input, uint32_t inputSize, uint8_t* output, uint32_t outputSize);
    
    // Utilità
    bool WriteHeader();
    bool WriteHunkMap();
    bool WriteMetadata();
    void UpdateProgress(const std::string& status = "");
    
    uint32_t CalculateHunkSize();
    bool ShouldCompressHunk(const uint8_t* data, uint32_t size);
    uint32_t CalculateCRC32(const uint8_t* data, uint32_t size);
    
    // Metadata helpers
    bool AddTrackMetadata(const CDTrackInfo& track);
    bool AddGDROMMetadata();
};

} // namespace UniversalCompressor

#endif // CHD_COMPRESSOR_H

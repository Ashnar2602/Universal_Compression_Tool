#ifndef UNIVERSAL_COMPRESSOR_H
#define UNIVERSAL_COMPRESSOR_H

#include <string>
#include <vector>
#include <functional>
#include <cstdint>
#include <memory>

namespace UniversalCompressor {

// Versione dell'applicazione
static const char* VERSION = "1.0.0";

// Tipi di compressione supportati
enum CompressionType {
    COMPRESSION_CSO,
    COMPRESSION_CHD
};

// Formati CSO supportati
enum CSOFormat {
    CSO_FORMAT_CSO1,
    CSO_FORMAT_CSO2,
    CSO_FORMAT_ZSO,
    CSO_FORMAT_DAX
};

// Algoritmi di compressione CSO
enum CSOAlgorithm {
    CSO_ALG_ZLIB    = 0x01,
    CSO_ALG_7ZIP    = 0x02,
    CSO_ALG_ZOPFLI  = 0x04,
    CSO_ALG_LZ4     = 0x08,
    CSO_ALG_LIBDEFLATE = 0x10
};

// Codec CHD
enum CHDCodec {
    CHD_CODEC_NONE   = 0x00,
    CHD_CODEC_CDLZ   = 0x01,
    CHD_CODEC_CDZL   = 0x02,
    CHD_CODEC_CDFL   = 0x04
};

// Status delle operazioni
enum TaskStatus {
    TASK_SUCCESS,
    TASK_ERROR,
    TASK_IN_PROGRESS,
    TASK_CANCELLED
};

// Configurazione per compressione CSO
struct CSOConfig {
    CSOFormat format = CSO_FORMAT_CSO1;
    uint32_t blockSize = 0;  // 0 = auto
    uint32_t algorithms = CSO_ALG_ZLIB | CSO_ALG_7ZIP;
    uint32_t threads = 4;
    bool fastMode = false;
    double origCostPercent = 100.0;
    double lz4CostPercent = 100.0;
};

// Configurazione per compressione CHD
struct CHDConfig {
    uint32_t codecs = CHD_CODEC_CDLZ | CHD_CODEC_CDZL | CHD_CODEC_CDFL;
    uint32_t hunkSize = 19584;
    uint32_t processors = 4;
    bool force = true;
    std::string template_name;
};

// Configurazione generale
struct GeneralConfig {
    std::string outputPath;
    bool deleteInputFiles = false;
    bool createSubDir = false;
    bool keepIncomplete = false;
    bool verbose = false;
};

// Callback per progresso
using ProgressCallback = std::function<void(int current, int total, const std::string& status)>;

// Callback per errori
using ErrorCallback = std::function<void(const std::string& error)>;

// Struttura per task di compressione
struct CompressionTask {
    std::string inputFile;
    std::string outputFile;
    CompressionType type;
    CSOConfig csoConfig;
    CHDConfig chdConfig;
    GeneralConfig generalConfig;
    ProgressCallback progressCallback;
    ErrorCallback errorCallback;
};

// Classe principale per la compressione universale
class UniversalCompressor {
public:
    UniversalCompressor();
    ~UniversalCompressor();

    // Configurazione
    void SetCSOConfig(const CSOConfig& config);
    void SetCHDConfig(const CHDConfig& config);
    void SetGeneralConfig(const GeneralConfig& config);

    // Operazioni di compressione
    TaskStatus CompressFile(const std::string& inputFile, 
                           const std::string& outputFile, 
                           CompressionType type);
    
    TaskStatus CompressFiles(const std::vector<std::string>& inputFiles,
                            const std::string& outputDir,
                            CompressionType type);

    // Callback per monitoraggio
    void SetProgressCallback(ProgressCallback callback);
    void SetErrorCallback(ErrorCallback callback);

    // Utility
    static std::vector<std::string> GetSupportedInputFormats();
    static std::string GetOutputExtension(CompressionType type, CSOFormat csoFormat = CSO_FORMAT_CSO1);
    static bool IsValidInputFile(const std::string& filename);
    std::string GenerateOutputFilename(const std::string& inputFile, CompressionType type);

private:
    // Implementazioni specifiche
    TaskStatus CompressToCSO(const std::string& inputFile, const std::string& outputFile);
    TaskStatus CompressToCHD(const std::string& inputFile, const std::string& outputFile);

    // Utilità interne
    bool ValidateInput(const std::string& inputFile);
    bool ValidateOutput(const std::string& outputFile);

    // Configurazioni
    CSOConfig csoConfig_;
    CHDConfig chdConfig_;
    GeneralConfig generalConfig_;

    // Callback
    ProgressCallback progressCallback_;
    ErrorCallback errorCallback_;

    // Stato interno
    bool cancelled_;
    std::string lastError_;
};

// Funzioni di utilità
namespace Utils {
    std::string GetFileExtension(const std::string& filename);
    std::string GetFileBasename(const std::string& filename);
    std::string GetFileDirectory(const std::string& filename);
    bool FileExists(const std::string& filename);
    uint64_t GetFileSize(const std::string& filename);
    std::string FormatBytes(uint64_t bytes);
    std::string FormatTime(double seconds);
}

} // namespace UniversalCompressor

#endif // UNIVERSAL_COMPRESSOR_H

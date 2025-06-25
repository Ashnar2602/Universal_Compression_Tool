#include "universal_compressor.h"
#include "cso_compressor.h"
#include "chd_compressor.h"
#include <filesystem>
#include <iostream>
#include <chrono>
#include <algorithm>
#include <cctype>

namespace UniversalCompressor {

UniversalCompressor::UniversalCompressor() 
    : cancelled_(false) {
    // Configurazioni di default
    csoConfig_ = CSOConfig{};
    chdConfig_ = CHDConfig{};
    generalConfig_ = GeneralConfig{};
}

UniversalCompressor::~UniversalCompressor() {
    // Cleanup se necessario
}

void UniversalCompressor::SetCSOConfig(const CSOConfig& config) {
    csoConfig_ = config;
}

void UniversalCompressor::SetCHDConfig(const CHDConfig& config) {
    chdConfig_ = config;
}

void UniversalCompressor::SetGeneralConfig(const GeneralConfig& config) {
    generalConfig_ = config;
}

void UniversalCompressor::SetProgressCallback(ProgressCallback callback) {
    progressCallback_ = callback;
}

void UniversalCompressor::SetErrorCallback(ErrorCallback callback) {
    errorCallback_ = callback;
}

TaskStatus UniversalCompressor::CompressFile(const std::string& inputFile, 
                                           const std::string& outputFile, 
                                           CompressionType type) {
    cancelled_ = false;
    lastError_.clear();

    // Validazione input
    if (!ValidateInput(inputFile)) {
        lastError_ = "File di input non valido o non esistente: " + inputFile;
        if (errorCallback_) {
            errorCallback_(lastError_);
        }
        return TASK_ERROR;
    }

    // Validazione output
    if (!ValidateOutput(outputFile)) {
        lastError_ = "Percorso di output non valido: " + outputFile;
        if (errorCallback_) {
            errorCallback_(lastError_);
        }
        return TASK_ERROR;
    }

    // Notifica inizio
    if (progressCallback_) {
        progressCallback_(0, 100, "Iniziando compressione...");
    }

    // Esegui compressione appropriata
    TaskStatus result;
    switch (type) {
        case COMPRESSION_CSO:
            result = CompressToCSO(inputFile, outputFile);
            break;
        case COMPRESSION_CHD:
            result = CompressToCHD(inputFile, outputFile);
            break;
        default:
            lastError_ = "Tipo di compressione non supportato";
            if (errorCallback_) {
                errorCallback_(lastError_);
            }
            return TASK_ERROR;
    }

    // Gestione post-compressione
    if (result == TASK_SUCCESS) {
        if (progressCallback_) {
            progressCallback_(100, 100, "Compressione completata");
        }

        // Elimina file di input se richiesto
        if (generalConfig_.deleteInputFiles) {
            try {
                std::filesystem::remove(inputFile);
            } catch (const std::exception& e) {
                // Log warning ma non fallire
                if (errorCallback_) {
                    errorCallback_("Avviso: impossibile eliminare file di input: " + std::string(e.what()));
                }
            }
        }
    }

    return result;
}

TaskStatus UniversalCompressor::CompressFiles(const std::vector<std::string>& inputFiles,
                                            const std::string& outputDir,
                                            CompressionType type) {
    cancelled_ = false;
    
    if (inputFiles.empty()) {
        lastError_ = "Nessun file di input specificato";
        if (errorCallback_) {
            errorCallback_(lastError_);
        }
        return TASK_ERROR;
    }

    // Crea directory di output se non esiste
    try {
        std::filesystem::create_directories(outputDir);
    } catch (const std::exception& e) {
        lastError_ = "Impossibile creare directory di output: " + std::string(e.what());
        if (errorCallback_) {
            errorCallback_(lastError_);
        }
        return TASK_ERROR;
    }

    int totalFiles = static_cast<int>(inputFiles.size());
    int completedFiles = 0;
    int failedFiles = 0;

    for (int i = 0; i < totalFiles && !cancelled_; ++i) {
        const std::string& inputFile = inputFiles[i];
        
        // Genera nome file di output
        std::string outputFile = GenerateOutputFilename(inputFile, type);
        std::string fullOutputPath = outputDir + "/" + outputFile;

        // Notifica progresso
        if (progressCallback_) {
            std::string status = "Comprimendo file " + std::to_string(i + 1) + " di " + 
                               std::to_string(totalFiles) + ": " + Utils::GetFileBasename(inputFile);
            progressCallback_(i * 100 / totalFiles, 100, status);
        }

        // Comprimi file
        TaskStatus result = CompressFile(inputFile, fullOutputPath, type);
        
        if (result == TASK_SUCCESS) {
            completedFiles++;
        } else {
            failedFiles++;
            if (!generalConfig_.keepIncomplete) {
                // Rimuovi file di output incompleto
                try {
                    std::filesystem::remove(fullOutputPath);
                } catch (...) {
                    // Ignora errori di cleanup
                }
            }
        }
    }

    // Risultato finale
    if (cancelled_) {
        return TASK_CANCELLED;
    } else if (failedFiles == 0) {
        return TASK_SUCCESS;
    } else if (completedFiles > 0) {
        // Successo parziale
        lastError_ = "Completati " + std::to_string(completedFiles) + " file, " + 
                    std::to_string(failedFiles) + " falliti";
        return TASK_SUCCESS; // Consideriamo successo parziale come successo
    } else {
        return TASK_ERROR;
    }
}

TaskStatus UniversalCompressor::CompressToCSO(const std::string& inputFile, const std::string& outputFile) {
    try {
        CSOCompressor compressor(csoConfig_);
        
        // Imposta callback se disponibili
        if (progressCallback_) {
            compressor.SetProgressCallback([this](int progress, const std::string& status) {
                progressCallback_(progress, 100, status);
            });
        }

        return compressor.Compress(inputFile, outputFile);
    } catch (const std::exception& e) {
        lastError_ = "Errore durante compressione CSO: " + std::string(e.what());
        if (errorCallback_) {
            errorCallback_(lastError_);
        }
        return TASK_ERROR;
    }
}

TaskStatus UniversalCompressor::CompressToCHD(const std::string& inputFile, const std::string& outputFile) {
    try {
        CHDCompressor compressor(chdConfig_);
        
        // Imposta callback se disponibili
        if (progressCallback_) {
            compressor.SetProgressCallback([this](int progress, const std::string& status) {
                progressCallback_(progress, 100, status);
            });
        }

        return compressor.Compress(inputFile, outputFile);
    } catch (const std::exception& e) {
        lastError_ = "Errore durante compressione CHD: " + std::string(e.what());
        if (errorCallback_) {
            errorCallback_(lastError_);
        }
        return TASK_ERROR;
    }
}

bool UniversalCompressor::ValidateInput(const std::string& inputFile) {
    return Utils::FileExists(inputFile) && IsValidInputFile(inputFile);
}

bool UniversalCompressor::ValidateOutput(const std::string& outputFile) {
    // Controlla che la directory di output esista o possa essere creata
    std::string dir = Utils::GetFileDirectory(outputFile);
    if (dir.empty()) {
        return true; // Directory corrente
    }
    
    try {
        std::filesystem::create_directories(dir);
        return true;
    } catch (...) {
        return false;
    }
}

std::string UniversalCompressor::GenerateOutputFilename(const std::string& inputFile, CompressionType type) {
    std::string basename = Utils::GetFileBasename(inputFile);
    std::string extension = GetOutputExtension(type, csoConfig_.format);
    return basename + extension;
}

// Funzioni statiche
std::vector<std::string> UniversalCompressor::GetSupportedInputFormats() {
    return {".iso", ".bin", ".img", ".cue", ".toc", ".gdi"};
}

std::string UniversalCompressor::GetOutputExtension(CompressionType type, CSOFormat csoFormat) {
    switch (type) {
        case COMPRESSION_CSO:
            switch (csoFormat) {
                case CSO_FORMAT_CSO1:
                case CSO_FORMAT_CSO2:
                    return ".cso";
                case CSO_FORMAT_ZSO:
                    return ".zso";
                case CSO_FORMAT_DAX:
                    return ".dax";
                default:
                    return ".cso";
            }
        case COMPRESSION_CHD:
            return ".chd";
        default:
            return ".compressed";
    }
}

bool UniversalCompressor::IsValidInputFile(const std::string& filename) {
    std::string ext = Utils::GetFileExtension(filename);
    std::transform(ext.begin(), ext.end(), ext.begin(), ::tolower);
    
    auto supportedFormats = GetSupportedInputFormats();
    return std::find(supportedFormats.begin(), supportedFormats.end(), ext) != supportedFormats.end();
}

// Implementazioni Utils
namespace Utils {

std::string GetFileExtension(const std::string& filename) {
    size_t dotPos = filename.find_last_of('.');
    if (dotPos == std::string::npos) {
        return "";
    }
    return filename.substr(dotPos);
}

std::string GetFileBasename(const std::string& filename) {
    std::string basename = std::filesystem::path(filename).stem().string();
    return basename;
}

std::string GetFileDirectory(const std::string& filename) {
    return std::filesystem::path(filename).parent_path().string();
}

bool FileExists(const std::string& filename) {
    return std::filesystem::exists(filename);
}

uint64_t GetFileSize(const std::string& filename) {
    try {
        return std::filesystem::file_size(filename);
    } catch (...) {
        return 0;
    }
}

std::string FormatBytes(uint64_t bytes) {
    const char* units[] = {"B", "KB", "MB", "GB", "TB"};
    int unit = 0;
    double size = static_cast<double>(bytes);
    
    while (size >= 1024.0 && unit < 4) {
        size /= 1024.0;
        unit++;
    }
    
    char buffer[32];
    if (unit == 0) {
        snprintf(buffer, sizeof(buffer), "%.0f %s", size, units[unit]);
    } else {
        snprintf(buffer, sizeof(buffer), "%.1f %s", size, units[unit]);
    }
    
    return std::string(buffer);
}

std::string FormatTime(double seconds) {
    int hours = static_cast<int>(seconds) / 3600;
    int minutes = (static_cast<int>(seconds) % 3600) / 60;
    int secs = static_cast<int>(seconds) % 60;
    
    char buffer[32];
    if (hours > 0) {
        snprintf(buffer, sizeof(buffer), "%d:%02d:%02d", hours, minutes, secs);
    } else {
        snprintf(buffer, sizeof(buffer), "%d:%02d", minutes, secs);
    }
    
    return std::string(buffer);
}

} // namespace Utils

} // namespace UniversalCompressor

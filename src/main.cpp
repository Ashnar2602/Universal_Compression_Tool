#include "universal_compressor.h"
#include <iostream>
#include <vector>
#include <string>
#include <filesystem>
#include <chrono>
#include <iomanip>
#include <algorithm>

using namespace UniversalCompressor;

// Struttura per parsing argomenti
struct Arguments {
    std::vector<std::string> inputFiles;
    std::string outputPath;
    CompressionType compressionType = COMPRESSION_CSO;
    
    // Opzioni CSO
    CSOConfig csoConfig;
    
    // Opzioni CHD
    CHDConfig chdConfig;
    
    // Opzioni generali
    GeneralConfig generalConfig;
    
    bool showHelp = false;
    bool showVersion = false;
    bool verbose = false;
    bool quiet = false;
};

void ShowVersion() {
    std::cout << "Universal ISO Compression Tool v" << VERSION << std::endl;
    std::cout << "Combina funzionalità di maxcso e chdman in un'unica applicazione" << std::endl;
}

void ShowHelp(const char* programName) {
    ShowVersion();
    std::cout << std::endl;
    std::cout << "Utilizzo: " << programName << " [opzioni] file.iso [file2.iso ...]" << std::endl;
    std::cout << std::endl;
    std::cout << "Opzioni generali:" << std::endl;
    std::cout << "  --help, -h          Mostra questo aiuto" << std::endl;
    std::cout << "  --version, -v       Mostra versione" << std::endl;
    std::cout << "  --type=TIPO         Tipo compressione: cso o chd (default: cso)" << std::endl;
    std::cout << "  --output=CARTELLA   Cartella output (default: cartella corrente)" << std::endl;
    std::cout << "  --delete-input      Elimina file input dopo compressione" << std::endl;
    std::cout << "  --verbose           Output verboso" << std::endl;
    std::cout << "  --quiet             Output silenzioso" << std::endl;
    std::cout << std::endl;
    std::cout << "Opzioni CSO:" << std::endl;
    std::cout << "  --cso-format=FMT    Formato: cso1, cso2, zso, dax (default: cso1)" << std::endl;
    std::cout << "  --cso-threads=N     Numero thread (default: 4)" << std::endl;
    std::cout << "  --cso-block=SIZE    Dimensione blocco (default: auto)" << std::endl;
    std::cout << "  --cso-fast          Modalità veloce" << std::endl;
    std::cout << "  --cso-no-zlib       Disabilita compressione zlib" << std::endl;
    std::cout << "  --cso-no-7zip       Disabilita compressione 7zip" << std::endl;
    std::cout << std::endl;
    std::cout << "Opzioni CHD:" << std::endl;
    std::cout << "  --chd-hunk=SIZE     Dimensione hunk (default: 19584)" << std::endl;
    std::cout << "  --chd-processors=N  Numero processori (default: 4)" << std::endl;
    std::cout << "  --chd-compression=C Codec: cdlz,cdzl,cdfl (default: tutti)" << std::endl;
    std::cout << "  --chd-no-force      Non forzare sovrascrittura" << std::endl;
    std::cout << std::endl;
    std::cout << "Esempi:" << std::endl;
    std::cout << "  " << programName << " game.iso" << std::endl;
    std::cout << "  " << programName << " --type=chd --output=compressed game.iso" << std::endl;
    std::cout << "  " << programName << " --cso-format=zso --cso-fast *.iso" << std::endl;
}

bool ParseArguments(int argc, char* argv[], Arguments& args) {
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        
        if (arg == "--help" || arg == "-h") {
            args.showHelp = true;
            return true;
        } else if (arg == "--version" || arg == "-v") {
            args.showVersion = true;
            return true;
        } else if (arg.find("--type=") == 0) {
            std::string type = arg.substr(7);
            if (type == "cso") {
                args.compressionType = COMPRESSION_CSO;
            } else if (type == "chd") {
                args.compressionType = COMPRESSION_CHD;
            } else {
                std::cerr << "Errore: Tipo compressione non valido: " << type << std::endl;
                return false;
            }
        } else if (arg.find("--output=") == 0) {
            args.outputPath = arg.substr(9);
        } else if (arg == "--delete-input") {
            args.generalConfig.deleteInputFiles = true;
        } else if (arg == "--verbose") {
            args.verbose = true;
            args.generalConfig.verbose = true;
        } else if (arg == "--quiet") {
            args.quiet = true;
        } else if (arg.find("--cso-format=") == 0) {
            std::string format = arg.substr(13);
            if (format == "cso1") args.csoConfig.format = CSO_FORMAT_CSO1;
            else if (format == "cso2") args.csoConfig.format = CSO_FORMAT_CSO2;
            else if (format == "zso") args.csoConfig.format = CSO_FORMAT_ZSO;
            else if (format == "dax") args.csoConfig.format = CSO_FORMAT_DAX;
            else {
                std::cerr << "Errore: Formato CSO non valido: " << format << std::endl;
                return false;
            }
        } else if (arg.find("--cso-threads=") == 0) {
            args.csoConfig.threads = std::stoul(arg.substr(14));
        } else if (arg.find("--cso-block=") == 0) {
            args.csoConfig.blockSize = std::stoul(arg.substr(12));
        } else if (arg == "--cso-fast") {
            args.csoConfig.fastMode = true;
        } else if (arg == "--cso-no-zlib") {
            args.csoConfig.algorithms &= ~CSO_ALG_ZLIB;
        } else if (arg == "--cso-no-7zip") {
            args.csoConfig.algorithms &= ~CSO_ALG_7ZIP;
        } else if (arg.find("--chd-hunk=") == 0) {
            args.chdConfig.hunkSize = std::stoul(arg.substr(11));
        } else if (arg.find("--chd-processors=") == 0) {
            args.chdConfig.processors = std::stoul(arg.substr(17));
        } else if (arg == "--chd-no-force") {
            args.chdConfig.force = false;
        } else if (arg.find("--") == 0) {
            std::cerr << "Errore: Opzione sconosciuta: " << arg << std::endl;
            return false;
        } else {
            // File di input
            args.inputFiles.push_back(arg);
        }
    }
    
    return true;
}

int main(int argc, char* argv[]) {
    Arguments args;
    
    // Parsing argomenti
    if (!ParseArguments(argc, argv, args)) {
        return 1;
    }
    
    if (args.showHelp) {
        ShowHelp(argv[0]);
        return 0;
    }
    
    if (args.showVersion) {
        ShowVersion();
        return 0;
    }
    
    // Verifica che ci siano file di input
    if (args.inputFiles.empty()) {
        std::cerr << "Errore: Nessun file di input specificato" << std::endl;
        std::cerr << "Usa --help per vedere l'utilizzo" << std::endl;
        return 1;
    }
    
    // Imposta output path se non specificato
    if (args.outputPath.empty()) {
        args.outputPath = std::filesystem::current_path().string();
    }
    
    // Verifica che i file di input esistano
    for (const auto& file : args.inputFiles) {
        if (!std::filesystem::exists(file)) {
            std::cerr << "Errore: File non trovato: " << file << std::endl;
            return 1;
        }
        
        if (!UniversalCompressor::UniversalCompressor::IsValidInputFile(file)) {
            std::cerr << "Avviso: Formato file potenzialmente non supportato: " << file << std::endl;
        }
    }
    
    // Crea compressore
    UniversalCompressor::UniversalCompressor compressor;
    compressor.SetCSOConfig(args.csoConfig);
    compressor.SetCHDConfig(args.chdConfig);
    compressor.SetGeneralConfig(args.generalConfig);
    
    // Imposta callback per progresso
    if (!args.quiet) {
        compressor.SetProgressCallback([&args](int current, int total, const std::string& status) {
            if (args.verbose) {
                std::cout << "[" << current << "/" << total << "] " << status << std::endl;
            } else {
                // Barra di progresso semplice
                int barWidth = 50;
                int progress = (current * barWidth) / total;
                std::cout << "\r[";
                for (int i = 0; i < barWidth; ++i) {
                    if (i < progress) std::cout << "=";
                    else if (i == progress) std::cout << ">";
                    else std::cout << " ";
                }
                std::cout << "] " << current << "/" << total;
                if (current == total) std::cout << std::endl;
                std::cout.flush();
            }
        });
    }
    
    // Callback errori
    compressor.SetErrorCallback([](const std::string& error) {
        std::cerr << "Errore: " << error << std::endl;
    });
    
    // Statistiche
    auto startTime = std::chrono::high_resolution_clock::now();
    int successCount = 0;
    int errorCount = 0;
    uint64_t totalInputSize = 0;
    uint64_t totalOutputSize = 0;
    
    // Processa ogni file
    for (const auto& inputFile : args.inputFiles) {
        if (!args.quiet) {
            std::cout << "Comprimendo: " << inputFile << std::endl;
        }
        
        // Calcola dimensione input
        uint64_t inputSize = Utils::GetFileSize(inputFile);
        totalInputSize += inputSize;
        
        // Genera nome output
        std::string outputFile = compressor.GenerateOutputFilename(inputFile, args.compressionType);
        std::string fullOutputPath = args.outputPath + "/" + outputFile;
        
        // Comprimi
        TaskStatus result = compressor.CompressFile(inputFile, fullOutputPath, args.compressionType);
        
        if (result == TASK_SUCCESS) {
            successCount++;
            uint64_t outputSize = Utils::GetFileSize(fullOutputPath);
            totalOutputSize += outputSize;
            
            if (!args.quiet) {
                double ratio = 100.0 * (1.0 - static_cast<double>(outputSize) / inputSize);
                std::cout << "Completato: " << outputFile 
                         << " (riduzione: " << std::fixed << std::setprecision(1) << ratio << "%)" << std::endl;
            }
        } else {
            errorCount++;
            if (!args.quiet) {
                std::cout << "Fallito: " << inputFile << std::endl;
            }
        }
    }
    
    // Statistiche finali
    auto endTime = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(endTime - startTime);
    
    if (!args.quiet) {
        std::cout << std::endl << "=== Riepilogo ===" << std::endl;
        std::cout << "File processati: " << args.inputFiles.size() << std::endl;
        std::cout << "Successi: " << successCount << std::endl;
        std::cout << "Errori: " << errorCount << std::endl;
        
        if (successCount > 0) {
            double totalRatio = 100.0 * (1.0 - static_cast<double>(totalOutputSize) / totalInputSize);
            std::cout << "Dimensione input: " << Utils::FormatBytes(totalInputSize) << std::endl;
            std::cout << "Dimensione output: " << Utils::FormatBytes(totalOutputSize) << std::endl;
            std::cout << "Riduzione totale: " << std::fixed << std::setprecision(1) << totalRatio << "%" << std::endl;
        }
        
        std::cout << "Tempo impiegato: " << Utils::FormatTime(duration.count() / 1000.0) << std::endl;
    }
    
    return (errorCount == 0) ? 0 : 1;
}

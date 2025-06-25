# Universal ISO Compression Tool

A unified, native C++ tool that combines the functionality of **maxcso** (CSO compression) and **chdman** (CHD compression) into a single, cross-platform application.

## 🚀 Features

- **Unified CLI**: Single executable for both CSO and CHD compression
- **Native Implementation**: No external executable dependencies
- **Multiple Formats**: Support for CSO1, CSO2, ZSO, DAX, and CHD
- **Cross-Platform**: Works on Windows, Linux, and macOS
- **High Performance**: Multi-threaded compression with optimizations
- **Comprehensive Options**: Full control over compression parameters

## 📦 Supported Formats

### Input Formats
- ISO (CD/DVD disc images)
- BIN (Binary disc images)
- IMG (Disk image files)

### Output Formats
- **CSO**: Compressed ISO for PSP/PS2 emulators (PPSSPP, PCSX2)
  - CSO1, CSO2, ZSO, DAX variants
  - Algorithms: Zlib, 7-Zip, LZ4, Libdeflate
- **CHD**: Compressed Hunks of Data for MAME and arcade emulators
  - CHD v5 format compatible with MAME/RetroArch
  - Codecs: CDLZ, CDZL, CDFL

## 🛠️ Installation

### Prerequisites (Windows)
The project includes automated setup scripts for Windows:

```cmd
# Install MSYS2 and build tools automatically
setup_dev_env.bat

# Or manually install MSYS2 and required packages:
winget install MSYS2.MSYS2
# Then in MSYS2 terminal:
pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-zlib mingw-w64-x86_64-lz4 mingw-w64-x86_64-make
```

### Building from Source

```cmd
# Quick build (Windows with MSYS2)
quick_build.bat

# Or using the generic build script
build_cpp.bat

# Cross-platform build
make
```

The compiled executable will be available in `bin/universal-compressor.exe`.

## 🎯 Usage

### Basic Usage

```cmd
# Compress to CSO (default)
universal-compressor.exe game.iso

# Compress to CHD
universal-compressor.exe --type=chd game.iso

# Batch processing
universal-compressor.exe *.iso
```

### Advanced Usage

```cmd
# CSO with specific format and options
universal-compressor.exe --type=cso --cso-format=zso --cso-threads=8 --cso-fast game.iso

# CHD with custom settings
universal-compressor.exe --type=chd --chd-hunk=32768 --chd-processors=4 game.iso

# Custom output directory
universal-compressor.exe --output=compressed --delete-input *.iso
```

### Available Options

```
General Options:
  --help, -h          Show help
  --version, -v       Show version
  --type=TYPE         Compression type: cso or chd (default: cso)
  --output=DIR        Output directory (default: current)
  --delete-input      Delete input files after compression
  --verbose           Verbose output
  --quiet             Silent output

CSO Options:
  --cso-format=FMT    Format: cso1, cso2, zso, dax (default: cso1)
  --cso-threads=N     Number of threads (default: 4)
  --cso-block=SIZE    Block size (default: auto)
  --cso-fast          Fast mode
  --cso-no-zlib       Disable zlib compression
  --cso-no-7zip       Disable 7zip compression

CHD Options:
  --chd-hunk=SIZE     Hunk size (default: 19584)
  --chd-processors=N  Number of processors (default: 4)
  --chd-compression=C Codecs: cdlz,cdzl,cdfl (default: all)
  --chd-no-force      Don't force overwrite
```

## 🏗️ Architecture

The project is structured as a modular C++ application:

```
Universal-Compression-Tool/
├── src/                          # C++ source code
│   ├── universal_compressor.*    # Main unified interface
│   ├── cso_compressor.*          # Standalone CSO implementation
│   ├── chd_compressor.*          # Standalone CHD implementation
│   └── main.cpp                  # CLI interface
├── bin/                          # Compiled executables
├── obj/                          # Object files
├── Makefile                      # Cross-platform build system
├── *.bat                         # Windows build scripts
└── docs/                         # Documentation
```

### Key Components

- **UniversalCompressor**: Main class providing unified interface
- **CSOCompressor**: Standalone CSO compression implementation
- **CHDCompressor**: Standalone CHD compression implementation
- **CLI**: Command-line interface with full argument parsing

## 🎮 Emulator Compatibility

### CSO Files
- **PPSSPP** (PSP emulator)
- **PCSX2** (PS2 emulator) 
- **Other PSP/PS2 emulators**

### CHD Files
- **MAME** (Arcade emulator)
- **RetroArch** (Multi-system emulator)
- **Other MAME-compatible emulators**

## 📊 Performance

- **Multi-threaded**: Utilizes all available CPU cores
- **Optimized algorithms**: Fast compression with high quality
- **Memory efficient**: Streaming compression for large files
- **Progress tracking**: Real-time compression status

### Typical Compression Ratios
- **CSO**: 60-80% of original size (faster compression)
- **CHD**: 50-70% of original size (better compression)
- **Performance scales** with thread count and disk I/O speed

## 🔧 Development

### Building Dependencies
- **C++17** compatible compiler
- **zlib** for CSO compression
- **lz4** for fast compression options
- **CMake** or **Make** for cross-platform builds

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **maxcso** project for CSO compression algorithms
- **MAME** project for CHD format specification
- **7-Zip**, **zlib**, **lz4** for compression libraries

## 📈 Version History

- **v1.0.0**: Initial release with unified CSO/CHD compression
- Native C++ implementation
- Cross-platform build system
- Complete CLI interface

---

**Note**: This tool is designed for legitimate backup and preservation purposes. Only compress disc images that you legally own.

# Universal ISO Compression Tool - Makefile
# Combina funzionalità di maxcso e chdman

# Configurazione compilatore
CXX = g++
CXXFLAGS = -std=c++20 -O2 -Wall -Wextra -pthread
INCLUDES = -Isrc
DEFINES = -DHAVE_ZLIB

# Librerie di base
LIBS = -lz

# Rileva sistema operativo
UNAME_S := $(shell uname -s)

# Configurazione per Windows (MinGW/MSYS2)
ifeq ($(OS),Windows_NT)
    LIBS += -lws2_32
    TARGET_EXT = .exe
else
    TARGET_EXT =
endif

# Controlla se LZ4 è disponibile
LZ4_CHECK := $(shell pkg-config --exists liblz4 && echo "yes")
ifeq ($(LZ4_CHECK),yes)
    DEFINES += -DHAVE_LZ4
    LIBS += -llz4
endif

# Controlla se OpenSSL è disponibile
SSL_CHECK := $(shell pkg-config --exists openssl && echo "yes")
ifeq ($(SSL_CHECK),yes)
    DEFINES += -DHAVE_OPENSSL
    LIBS += -lssl -lcrypto
endif

# Directory
SRCDIR = src
OBJDIR = obj
BINDIR = bin

# File sorgente
SOURCES = $(wildcard $(SRCDIR)/*.cpp)
OBJECTS = $(SOURCES:$(SRCDIR)/%.cpp=$(OBJDIR)/%.o)
TARGET = $(BINDIR)/universal-compressor$(TARGET_EXT)

# Target principale
all: directories $(TARGET)

# Crea directory se non esistono
directories:
	@mkdir -p $(OBJDIR) $(BINDIR)

# Target principale
$(TARGET): $(OBJECTS)
	@echo "Linking $(TARGET)..."
	@$(CXX) $(OBJECTS) -o $@ $(LIBS)
	@echo "Build completato: $(TARGET)"

# Regola per file oggetto
$(OBJDIR)/%.o: $(SRCDIR)/%.cpp
	@echo "Compiling $<..."
	@$(CXX) $(CXXFLAGS) $(INCLUDES) $(DEFINES) -c $< -o $@

# Pulizia
clean:
	@echo "Cleaning build files..."
	@rm -rf $(OBJDIR) $(BINDIR)

# Installazione (Linux/macOS)
install: $(TARGET)
	@echo "Installing to /usr/local/bin..."
	@sudo cp $(TARGET) /usr/local/bin/
	@sudo chmod +x /usr/local/bin/universal-compressor$(TARGET_EXT)

# Test di base
test: $(TARGET)
	@echo "Running basic tests..."
	@$(TARGET) --version
	@$(TARGET) --help

# Build di debug
debug: CXXFLAGS += -g -DDEBUG
debug: $(TARGET)

# Build statico
static: CXXFLAGS += -static
static: $(TARGET)

# Informazioni build
info:
	@echo "Compiler: $(CXX)"
	@echo "Flags: $(CXXFLAGS)"
	@echo "Includes: $(INCLUDES)"
	@echo "Defines: $(DEFINES)"
	@echo "Libraries: $(LIBS)"
	@echo "Sources: $(SOURCES)"
	@echo "Target: $(TARGET)"

# Verifica dipendenze
deps:
	@echo "Checking dependencies..."
	@pkg-config --exists zlib && echo "✓ zlib found" || echo "✗ zlib missing"
	@pkg-config --exists liblz4 && echo "✓ liblz4 found" || echo "○ liblz4 optional"
	@pkg-config --exists openssl && echo "✓ openssl found" || echo "○ openssl optional"

.PHONY: all clean install test debug static info deps directories
	@$(TARGET) --version
	@$(TARGET) --help

# Debug build
debug: CXXFLAGS += -g -DDEBUG
debug: clean $(TARGET)

# Release build
release: CXXFLAGS += -DNDEBUG -s
release: clean $(TARGET)

# Distribuzione
dist: release
	@echo "Creating distribution package..."
	@mkdir -p dist
	@cp $(TARGET) dist/
	@cp README.md dist/
	@cp CHANGELOG.md dist/
	@cp TECHNICAL.md dist/
	@echo "Distribution package created in dist/"

# Help
help:
	@echo "Universal ISO Compression Tool - Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  all       - Build application (default)"
	@echo "  clean     - Remove build files"
	@echo "  debug     - Build with debug symbols"
	@echo "  release   - Build optimized release"
	@echo "  install   - Install to system"
	@echo "  test      - Run basic tests"
	@echo "  dist      - Create distribution package"
	@echo "  help      - Show this help"
	@echo ""
	@echo "Requirements:"
	@echo "  - g++ with C++20 support"
	@echo "  - zlib development headers"
	@echo "  - Optional: lz4 development headers"

# Dipendenze automatiche
-include $(OBJECTS:.o=.d)

$(OBJDIR)/%.d: $(SRCDIR)/%.cpp
	@set -e; rm -f $@; \
	$(CXX) -MM $(CXXFLAGS) $(INCLUDES) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,$(OBJDIR)/\1.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

# Phony targets
.PHONY: all clean install test debug release dist help directories

# Default target
.DEFAULT_GOAL := all

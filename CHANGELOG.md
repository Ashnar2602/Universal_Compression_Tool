# Universal ISO Compression Tool - Changelog

## [1.0.0] - 2025-06-25

### Aggiunto
- ✨ **Interfaccia unificata** per compressione CSO e CHD
- 🎯 **Selezione formato**: Radio button per scegliere tra CSO e CHD
- 📁 **Gestione file multipli**: Selezione e elaborazione batch di file ISO
- ⚙️ **Finestra opzioni avanzate** con configurazioni dettagliate per entrambi i formati
- 📊 **Monitoraggio progresso**: Lista file con stato in tempo reale
- 🎵 **Notifiche**: Suono opzionale al completamento
- 🗑️ **Cleanup automatico**: Rimozione file input dopo compressione (opzionale)
- 💾 **Salvataggio configurazioni**: File Settings.ini per persistenza impostazioni
- 📈 **Statistiche compressione**: Calcolo e visualizzazione rapporti di compressione
- ⏱️ **Timing elaborazione**: Tracciamento tempi per ogni file
- 🔧 **Script di setup**: Controllo automatico dipendenze e installazione

### Funzionalità CSO
- 🚀 **Supporto formati multipli**: CSO1, CSO2, ZSO, DAX
- 🔄 **Threading configurabile**: 1-16 thread per elaborazione parallela
- 📦 **Algoritmi compressione**: Zlib, 7-Zip deflate, Zopfli
- ⚡ **Modalità veloce**: Compressione rapida con qualità ridotta
- 📏 **Dimensioni blocco personalizzabili**: Auto-detection o manuale

### Funzionalità CHD
- 🎮 **Compatibilità MAME completa**: Formato CHD standard
- 🗜️ **Codec multipli**: CDLZ, CDZL, CDFL
- ⚙️ **Configurazione hunk**: Dimensioni personalizzabili
- 🔧 **Processori multipli**: Utilizzo ottimale CPU multi-core
- 🎯 **Modalità CD**: Ottimizzata per immagini CD/DVD

### Interfaccia Utente
- 🖥️ **GUI moderna**: Interfaccia pulita e intuitiva
- 📋 **Lista file interattiva**: Visualizzazione stato e progresso
- 📂 **Selezione cartelle**: Browser integrato per input/output
- 🎨 **Descrizioni dinamiche**: Informazioni contestuali per ogni formato
- 📊 **Barra di stato**: Informazioni real-time su operazioni

### File di Supporto
- 📝 **README.md**: Documentazione utente completa
- 🔧 **TECHNICAL.md**: Documentazione tecnica dettagliata
- ⚙️ **Settings.ini**: File configurazione con tutte le opzioni
- 🔨 **Build.bat**: Script compilazione automatica
- 🚀 **Setup.bat**: Script verifica e installazione

### Controlli Qualità
- ✅ **Validazione input**: Controllo esistenza file e permessi
- 🛡️ **Gestione errori**: Error handling robusto
- 📋 **Logging**: Tracciamento operazioni e debug
- 🔍 **Verifica output**: Controllo successo compressione

### Requisiti Sistema
- 🖥️ **OS**: Windows 7/8/10/11 (x86/x64)
- 💾 **RAM**: 512MB+ raccomandati
- 💿 **Spazio**: 100MB+ temporaneo per operazioni
- 🔧 **Dipendenze**: maxcso.exe, chdman.exe

### Note Tecniche
- 🏗️ **Linguaggio**: AutoHotkey v1.1+
- 📦 **Packaging**: Compilabile in eseguibile standalone
- ⚡ **Performance**: Ottimizzato per elaborazione batch
- 🔄 **Compatibilità**: Mantiene compatibilità con tool originali

### Roadmap Futura
- 🔄 **Compressione parallela**: Elaborazione simultanea multipli file
- 🖱️ **Drag & Drop**: Interfaccia drag and drop
- 👁️ **Anteprima**: Stima dimensioni prima della compressione
- 📅 **Scheduler**: Compressioni automatiche programmate
- 🎯 **Formati aggiuntivi**: Supporto 7Z, ZIP, altri formati
- 🌐 **Integrazione web**: Download automatico tool dependencies

---

## Legenda Emoji
- ✨ Funzionalità principali
- 🎯 Interfaccia utente
- 📁 Gestione file
- ⚙️ Configurazione
- 📊 Monitoraggio
- 🎵 Audio/Notifiche
- 🗑️ Utility
- 💾 Persistenza
- 📈 Statistiche
- ⏱️ Performance
- 🔧 Setup/Build
- 🚀 Formati/Algoritmi
- 🔄 Threading/Parallel
- 📦 Compressione
- ⚡ Velocità
- 📏 Personalizzazione
- 🎮 Gaming/Emulation
- 🗜️ Codec
- 🖥️ Sistema
- 📋 Interface
- 📂 File Management
- 🎨 UX
- 📝 Documentazione
- ✅ Qualità
- 🛡️ Sicurezza
- 🔍 Validazione
- 🏗️ Sviluppo
- 🔄 Compatibilità
- 👁️ Preview
- 📅 Scheduling
- 🌐 Network

---

**Maintainers**: Universal Compression Tool Team  
**License**: Wrapper per maxcso e chdman - Rispetta licenze originali  
**Support**: Consulta README.md e TECHNICAL.md per documentazione dettagliata

# MAME WASM Build Factory - Complete Guide (v3.0)

> 🇹🇼 [繁體中文版](README-TW.md)
> 🎮 [Play Robby Roto](https://anomixer.github.io/MameWasm/) | [Load Your ROM](https://anomixer.github.io/MameWasm/play.html)

Automated toolset for compiling MAME WebAssembly builds on Windows and Linux. While highly optimized for the AmpleWeb project, it is a general-purpose factory for creating stable and efficient MAME WASM binaries.

## 📋 Project Structure

```
.
├── setup.ps1                    ← Environment initialization (run first)
├── build.ps1                    ← Main build script (Windows, with Production mode)
├── build-linux.ps1              ← Main build script (Linux)
├── analyze_roms_v3.py           ← Independent ROM dependency analyzer
├── verify_mame_targets.ps1      ← Build verification tool (developer)
├── server.py                    ← Simple local web server (for testing)
├── test_mamewasm.html           ← MAME WASM Loader (ROM file picker)
├── test_emularity.html          ← Emularity testing page (Robby Roto)
├── Dockerfile                   ← Docker build environment
├── docker-compose.yml           ← Docker Compose configuration
├── README.md                    ← This complete guide
├── README-TW.md                 ← Traditional Chinese guide
├── custom_targets/              ← User-defined target scripts (incl. 'ample')
├── emularity/                   ← Web loader components
├── mame/                        ← MAME source (auto-downloaded)
├── emsdk/                       ← Emscripten SDK (auto-downloaded)
├── bin/                         ← Place native mame.exe here for analysis
└── roms/                        ← Your ROM files (manual)
```

---

## 🚀 Quick Start (5 Minutes)

### First Time Setup

```powershell
# Run as Administrator
PowerShell -ExecutionPolicy Bypass -File ./setup.ps1

# Then start building
PowerShell -ExecutionPolicy Bypass -File ./build.ps1
```

### What happens?

1. **setup.ps1** (one time):
   - Installs Emscripten SDK.
   - Downloads `make` and `ninja` build tools.
   - Clones MAME source code.
   - Downloads `robby.zip` (test ROM).

2. **build.ps1** (repeatable):
   - Provides an interactive interface to choose TARGET and SUBTARGET.
   - **NEW: Production Mode**: Choose `-Oz` and `LTO` for smallest binaries.
   - Compiles MAME to WebAssembly using Ninja for speed.
   - Automatically applies Windows patches (fixes command length limits and JS syntax).
   - Copies artifacts to the root directory for testing.

3. **Analysis (Optional)**:
   - Run `python analyze_roms_v3.py` if you need to generate recursive ROM dependency mappings (specifically for AmpleWeb integration).
   - The results will be saved to **`rom_mapping_results_v3.txt`**. You can copy the generated mappings directly into AmpleWeb's config.

4. **Test**:
   - Run `python server.py`.
   - Open `test_mamewasm.html` in your browser.

---

## 🌟 Key Feature: Production Mode

When running `build.ps1`, you can now select **Production** mode, which enables:
- **-Oz Optimization**: Most aggressive binary size reduction.
- **LTO (Link-Time Optimization)**: Cross-module optimization for better speed and smaller binaries.
- **1GB Initial Memory**: Ensures heavy machines (Mac 68k, Apple IIgs) boot reliably.
- **Disabled Exception Catching (Optional)**: Further reduces size and increases performance for stable releases.

---

## 🐳 Docker Support (Recommended for Full Builds)

To avoid Windows-specific file locks and linker issues during parallel compilation, we recommend using Docker.

```bash
# Start the build environment via Docker Compose
docker-compose run mame-build mame-build TARGET=mame SUBTARGET=ample
```

This uses a stable Linux environment inside a container to produce high-quality WASM artifacts.

---

## 🐧 Native Linux / WSL Support

If you prefer not to use Docker, you can build natively on Linux/WSL.

### Prerequisites (Ubuntu/Debian)
```bash
sudo apt update && sudo apt install -y build-essential git python3
```

### Quick Start (Linux / WSL)
1. **Setup EMSDK**: `git clone https://github.com/emscripten-core/emsdk.git`
2. **Activate**: `cd emsdk && ./emsdk install latest && ./emsdk activate latest && source ./emsdk_env.sh`
3. **Build**: `cd mame && emmake make -j$(nproc) TARGET=mame SUBTARGET=ample OSD=sdl TARGETOS=asmjs`

---

## 📊 Parameters & Custom Targets

### SUBTARGET Selection

| SUBTARGET | Description | Est. Size | Recommended Mode |
|-----------|-------------|-----------|------------------|
| `tiny` ⭐ | **Recommended for Testing** | 30-50MB | Debug (Fast) |
| `ample` 🚀| **AmpleWeb Optimized** | 45-60MB | Production (Small) |
| `mame` | Full Build (40k+ drivers) | ~210MB | Docker (Stable) |

### 🔍 Independent Dependency Analyzer (`analyze_roms_v3.py`) [Optional]
A specialized tool for projects like AmpleWeb to automatically analyze recursive ROM dependencies.
- **Usage**: Place a native `mame.exe` in `bin/`, update `custom_targets/ample.lst`, and run the script.
- **Advantage**: Fully decoupled from external projects.

---

## 💡 Pro Tips

### Tip 1: Incremental Builds
- As long as you don't switch SUBTARGETs, subsequent builds take only 1-5 minutes.
- If you modify `custom_targets/*.lst`, we recommend running `build.ps1` again.

### Tip 2: WASM Optimization
- If your WASM files are over 100MB, use **Production** mode.
- Enabling **LTO** increases linking time but significantly improves runtime performance in the browser.

### Tip 3: ROM Setup
- Create a `./roms` folder and place ZIPs (e.g., `apple2e.zip`) there.
- When using `test_mamewasm.html`, the loader automatically writes ZIPs to the WASM virtual filesystem.

---

## ❌ Troubleshooting & FAQ

### Issue: "Aborted()" or "Out of memory" at runtime
- **Fix**: The machine needs more memory than the WASM default. The new `build.ps1` sets `INITIAL_MEMORY` to 1GB. Please rebuild using the updated script.

### Issue: "PAGE_SIZE" macro conflict
- **Fix**: This is a naming conflict between MAME source and the Emscripten SDK. Rename `PAGE_SIZE` in `cmi.cpp` or `msxdos2.cpp` as described in the "Known Source Patches" section.

### Issue: Ninja error "multiple rules generate" on Windows
- **Fix**: The build script now includes auto-patchers for `dasm.ninja` and `optional.ninja`. If it persists, try deleting the `build/` directory and restarting the build.

---

## ⚠️ Important Notes

- **Independence**: This repository is now 100% self-contained. No external paths required.
- **Path Limits**: Folder paths MUST NOT contain Chinese characters or spaces.
- **RAM Requirements**: At least 16GB RAM is recommended for building the full `mame` target.

---

**Last Updated**: 2026-05-03
**Version**: 3.0 (Production Mode, Dockerized, Independent Tools, LTO Support)

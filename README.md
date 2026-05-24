# MAME WASM Build Factory (v3.1)

> 🇹🇼 [繁體中文版](README-TW.md)
> 🎮 [Play Robby Roto](https://anomixer.github.io/MameWasm/) | [Load your own ROM](https://anomixer.github.io/MameWasm/play.html)

Automated toolset for compiling MAME to WebAssembly with high stability and optimization. While optimized for AmpleWeb, this repository serves as a general-purpose build factory for any MAME-to-WASM needs.

## 📋 Repository Structure

```
.
├── 🛠️ Build Scripts
│   ├── setup.ps1             ← Initialization (Run first)
│   ├── build.ps1             ← Main build script (Windows)
│   └── build-linux.ps1       ← Main build script (Linux)
│
├── 🎯 Custom Targets
│   └── custom_targets/       ← LUA/LST definitions (supracan, ample)
│
├── 🌐 Web & Testing
│   ├── test_mamewasm.html    ← Advanced multi-ROM loader
│   ├── test_emularity.html   ← Emularity test page (Robby Roto)
│   └── server.py             ← Local test server
│
├── 📦 Core Components
│   ├── mame/                 ← MAME source tree
│   ├── emsdk/                ← Emscripten SDK
│   └── bin/                  ← Build tools & native MAME
│
└── 💾 ROMs & Data
    ├── roms/                 ← Your ROM files
    └── analyze_roms_v3.py    ← Dependency analyzer
```

---

## 🚀 Quick Start (5 Minutes)

### Initial Setup

```powershell
# Run as Administrator
PowerShell -ExecutionPolicy Bypass -File ./setup.ps1

# Start Building
PowerShell -ExecutionPolicy Bypass -File ./build.ps1
```

### What happens?
1. **setup.ps1**: Installs EMSDK, build tools (Ninja/Make), and clones MAME source.
2. **build.ps1**: Interactive UI to choose TARGET, SUBTARGET, and Optimization mode.
3. **Test**: Run `python server.py` and open `test_mamewasm.html`.

---

## 🌟 Key Features: Production Mode

When building via `build.ps1`, you can choose **Production** mode, which enables:
- **Extreme Optimization (-Oz)**: Aggressive size reduction.
- **LTO (Link-Time Optimization)**: Cross-module optimization for better performance.
- **Memory Stability**: Sets `INITIAL_MEMORY` to 1GB and `MAXIMUM_MEMORY` to 4GB.
- **No Exceptions**: Further reduces size and improves speed for release builds.

---

## 🧠 Direct WASM Emulator RAM Query (DMA Tech)

This repository includes a highly advanced and custom memory access mechanism designed to allow external JavaScript files to query the emulator's memory space directly, completely bypassing unstable heap scanning heuristics.

### Exported Functions
The build automatically exports two custom C++ functions from MAME's `running_machine` structure into WebAssembly/JavaScript:

1.  **Single Byte Read**:
    `uint8_t emscripten_read_ram(uint32_t addr)`
    *JS Call*: `Module._ZN15running_machine19emscripten_read_ramEj(addr)`
    *Description*: Directly queries the `:maincpu` address space program memory for the given address.

2.  **Bulk Buffer Read**:
    `uint32_t emscripten_read_ram_bulk(uint32_t start_addr, uint32_t length, uint8_t *out_buf)`
    *JS Call*: `Module._ZN15running_machine24emscripten_read_ram_bulkEjjPh(start_addr, length, ptr)`
    *Description*: Contiguously reads a memory block from the 6502 CPU space into an allocated WebAssembly pointer (`ptr`), enabling high-performance block memory reading (e.g. text screens).

---

## 🐳 Docker Support (Recommended for Full Builds)

To avoid file locking and linker issues on Windows, use the containerized environment:
```bash
# Start build via Docker Compose
docker-compose run mame-build mame-build TARGET=mame SUBTARGET=ample
```

This ensures a stable Linux-based build environment for the best results.

---

## 🐧 Native Linux / WSL Support

If you prefer not to use Docker, you can build directly on Linux/WSL.

### Prerequisites (Ubuntu/Debian)
```bash
sudo apt update && sudo apt install -y build-essential git python3
```

### Quick Start (Linux / WSL)
1. **Setup EMSDK**: `git clone https://github.com/emscripten-core/emsdk.git`
2. **Activate**: `cd emsdk && ./emsdk install latest && ./emsdk activate latest && source ./emsdk_env.sh`
3. **Build**: `PowerShell -File ./build-linux.ps1` (or use manual `emmake make`)

---

## 📊 Build Parameters Reference

| SUBTARGET | Description | Size | Recommended Mode |
|-----------|------|------|----------|
| `tiny` ⭐ | Recommended for testing | 30-50MB | Debug (Fast) |
| `ample` 🚀| Optimized for AmpleWeb | 45-60MB | Production (Oz + LTO) |
| `supracan`| Super A'Can custom target | ~40MB | Production |
| `mame` | Full version (40k drivers) | ~210MB | Docker (Recommended) |

### 💡 Build Examples

You can use the `-Sources` parameter to build specific machines:

*   **Apple IIe**:
    `PowerShell -File ./build.ps1 -Subtarget tiny -Sources apple2e`
*   **Pac-Man**:
    `PowerShell -File ./build.ps1 -Subtarget tiny -Sources pacman`
*   **Arcade Multi-pack (Multiple drivers)**:
    `PowerShell -File ./build.ps1 -Subtarget tiny -Sources pacman,robby,dkong`
*   **Custom Target (Super A'Can)**:
    `PowerShell -File ./build.ps1 -Subtarget supracan -Optimization Production`
    *(Note: Production mode enables Oz and LTO for the smallest and fastest WASM binary.)*

---

## 🎮 Test Environment (`test_mamewasm.html`)

This project includes a premium, local-friendly test page for rapid verification of your WASM builds.

### 🔧 UI Field Description
1.  **WASM JS**: The filename of your build output (e.g., `mamesupracan.js` or `mametiny.js`).
2.  **Driver**: The MAME machine name (e.g., `supracan` or `apple2e`).
3.  **Extra Args**: Additional MAME CLI arguments.
    *   *Example*: Use `-cart /roms/game.zip` to mount a cartridge.
4.  **ROM File Selection**: Click to select all required ZIP files.

### 📝 Usage Guide (Step-by-Step)
1.  **Configure**: Enter the **WASM JS** and **Driver** name first.
2.  **Add Args**: If mounting a cartridge, enter the path in **Extra Args** (must start with `/roms/`).
3.  **Select Files**: Click "Select Files" and **select ALL required ZIPs simultaneously** (e.g., `supracan.zip` + `umc6650.zip` + `game.zip`).
4.  **Run**: Click **Load & Run**. The page remembers your settings and reloads to start MAME.
5.  **Reset**: If you get stuck, click the red **Clear Settings** button to reset the UI.

---

## 💡 Pro Tips

### Tip 1: Advanced Custom Targets
MAME's architecture is complex. For machines requiring specific cores (like `supracan`), a simple `-Sources` flag might not suffice. 
- You can create a `.lst` and a `.lua` definition in `custom_targets/`.
- **AI-Powered Workflow**: Ask an AI (Claude/Antigravity) to "Write a MAME Genie LUA definition for target X" and place it in `custom_targets`.

### Tip 2: Incremental Builds
- Subsequent builds take only 1-5 minutes as long as you don't switch SUBTARGET.
- If you modify `custom_targets/*.lst`, we recommend running `build.ps1` again.

---

## ❌ Troubleshooting & FAQ

### Issue: "Aborted()" or "Out of memory" at runtime
- **Fix**: The machine needs more memory. Rebuild using `build.ps1` which sets memory to 1GB.

### Issue: "PAGE_SIZE" macro conflict
- **Fix**: Conflict between MAME and Emscripten. Rename `PAGE_SIZE` in `cmi.cpp` or `msxdos2.cpp`.

### Issue: Ninja error "multiple rules generate" on Windows
- **Fix**: The script auto-patches `dasm.ninja`. If it persists, try deleting the `build/` directory and restarting.

---

## ⚠️ Important Notes
- **Independence**: 100% self-contained toolchain. No external dependencies required.
- **Path Limits**: Folder paths MUST NOT contain Chinese characters or spaces.
- **RAM Requirements**: At least 16GB RAM is recommended for full `mame` target builds.

**Last Updated**: 2026-05-14
**Version**: 3.1

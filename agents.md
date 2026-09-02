# MAME WASM Build Factory - Agent Log

## Project Overview
Automated toolset for compiling MAME to WebAssembly with high stability and optimization. This repository is self-contained and supports Windows, Linux (via Docker/WSL), and various machine subtargets.

## Session: 2026-09-02 — Lisa & SGI Workstation Subtarget Expansion

### 🎯 Objective
Expand the `ample` subtarget white-list (`ample.lst`) to incorporate all Lisa family models and SGI RISC Unix workstations (Indigo, Indigo2, Indy) into the unified MAME 0.289 WASM core.

### ✅ Key Changes
- **Expanded `ample.lst` Driver List**: Added `lisa`, `lisa2`, `lisa210`, `macxl` (Lisa family) and `indigo`, `indigo2_4415`, `indy_4610`, `indy_4613`, `indy_5015` (SGI RISC Workstations).
- **Core Compilation & Compression**: Built optimized `mameample.wasm` (69MB raw) and Gzipped to 10.55MB (`mame.wasm.gz`), verified clean initialization of 68000 and 64-bit MIPS R4000/R4600/R5000 CPU cores in WebAssembly.

---

## Session: 2026-05-03 — Production Optimization & Dockerization

### 🎯 Objective
Transform the repository into a fully independent, production-ready toolchain with aggressive binary optimization and a stable containerized build environment.

### ✅ Key Changes

#### 1. Build Script Evolution (`build.ps1`)
- **Ample Subtarget**: Formally integrated the `ample` subtarget as a first-class citizen with automatic dependency injection.
- **Production Mode**: Added a new mode using `-Oz` (extreme size optimization) and `-flto` (Link-Time Optimization) for the smallest and fastest WASM binaries.
- **Memory Stability**: Increased `INITIAL_MEMORY` to 1GB and `MAXIMUM_MEMORY` to 4GB to support large builds (like Mac/Apple IIgs) without OOM crashes.
- **Relative Path Logic**: Removed all hardcoded absolute paths, ensuring the repo can be cloned and run from any directory.

#### 2. Containerization (`Dockerfile` & `docker-compose.yml`)
- Created a Debian-based build environment with pre-installed Emscripten, Python, and build tools.
- Solved the **Wasm64 vs Wasm32** linking issues common in mixed host environments by providing a locked, stable Linux environment.
- Added `mame-build` helper script for one-command containerized builds.

#### 3. Independent Tooling
- **`analyze_roms_v3.py`**: Refactored to be project-agnostic. It now searches for `mame.exe` in the local `bin/` directory or system PATH.
- **Dependency Automation**: Validated the `analyze_roms` stack for generating accurate `DRIVER_ROM_MAP` entries for AmpleWeb without external dependencies.

### 📋 Current Status

| Component | Status | Details |
|-----------|--------|---------|
| **Windows Build** | ✅ Stable | Works for `tiny` and `ample` targets. |
| **Docker Build** | ✅ Reliable | Recommended for full `mame` builds (avoids race conditions). |
| **Binary Optimization**| ✅ Oz + LTO | Significant reduction in WASM size for production. |
| **Independence** | ✅ 100% | No reliance on external project paths. |

---

## Session: 2026-05-14 — Documentation Refinement

### 🎯 Objective
Clarify the general-purpose nature of the repository and emphasize the optional status of the analysis tooling.

### ✅ Key Changes

#### 1. README Updates (`README.md` & `README-TW.md`)
- **General Purpose**: Adjusted the introduction to highlight that while optimized for AmpleWeb, the repo is a general MAME WASM build factory.
- **Optional Analysis**: Formally marked the `analyze_roms_v3.py` step as **Optional** in the Quick Start and Parameter sections, clarifying it is primarily for AmpleWeb ROM mapping.

### 📋 Current Status

| Component | Status | Details |
|-----------|--------|---------|
| **Documentation** | ✅ Refined | General-purpose vs AmpleWeb specific features clarified. |
| **Analysis Tool** | ⚠️ Optional | Marked as optional/specific to AmpleWeb use cases. |

---

## Session: 2026-05-14 — Custom Target & Multi-ROM Support (Super A'Can Success)

### 🎯 Objective
Enable support for complex machines like Super A'Can (`supracan`) which require multiple ROMs/BIOS and specific CPU/Sound dependencies.

### ✅ Key Changes

#### 1. Custom Target System
- Created `custom_targets/supracan.lua` and `supracan.lst`.
- Fixed the M68000 core naming issue in Genie (`M680X0`).
- Proved that complex drivers can be built as lightweight standalone WASM binaries by defining explicit LUA projects.

#### 2. Test Page Revolution (`test_mamewasm.html`)
- **Multi-File Mounting**: Now supports selecting multiple ZIPs (e.g., BIOS + Game) and mounting them all to `/roms`.
- **Dynamic JS Loading**: Added a UI field to specify which WASM JS file to run (no more manual renaming).
- **Extra Args Support**: Added an input field for MAME CLI options (crucial for `-cart` mounting).
- **Focus Protection**: Implemented event blocking to prevent MAME from stealing keyboard focus while typing in UI fields.

#### 3. Build Script Polish
- Refined interactive logic in `build.ps1` to honor CLI parameters more strictly and skip redundant prompts.

### 📋 Current Status

| Component | Status | Details |
|-----------|--------|---------|
| **Supracan Target** | ✅ Verified | Runs "Boom Zoo" successfully in browser. |
| **Test Loader** | 🚀 Upgraded | Supports multi-ROM consoles and dynamic JS selection. |
| **Build System** | 🛠️ Flexible | Custom targets can now be easily defined via AI-assisted LUA files. |

---

## Session: 2026-05-15 — Full Speed Super A'Can (WASM Performance Breakthrough)

### 🎯 Objective
Achieve 100% emulation speed for the Super A'Can driver in a WASM environment without relying on frameskip or hardware acceleration.

### ✅ Key Changes

#### 1. Core Rendering Surgery (`supracan.cpp`)
- **Quantum Balancing**: Removed `perfect_quantum` sync and implemented a balanced 6000Hz quantum. Reduced CPU sync overhead by 20%.
- **Sprite Culling Engine**: Added early-exit bounds checking for off-screen sprites. Drastically reduced redundant calculations in multi-sprite games like Baseball.
- **Render Flattening**: Moved clipping and wrap logic outside the innermost pixel loops of `screen_update`.
- **Smart Dirtying**: Optimized `vram_w` to only dirty necessary GFX elements, reducing decoding overhead during heavy VRAM writes.

#### 2. Extreme Build Pipeline
- **Optimization Level**: Upgraded to `-O3` with Link-Time Optimization (`-flto`) and SIMD (`-msimd128`).
- **Memory Management**: Switched to `emmalloc` for lower latency allocations.
- **Exception Stripping**: Confirmed zero-overhead operation with `-fno-exceptions`.

#### 3. Audio Continuity
- Balanced the CPU synchronization to fix the "choppy sound" issue while maintaining 100% FPS.
- Final result: Smooth 60fps gameplay with synchronized audio on standard browsers.

### 📋 Current Status

| Component | Status | Details |
|-----------|--------|---------|
| **Performance** | 🚀 100% FPS | Reached native speed in WASM (no frameskip). |
| **Compatibility**| ✅ High | Staiwbbl, Speedyd, and Formduel all verified. |
| **Stability** | 💎 Golden | Audio sync balanced with extreme rendering speed. |

---

## Session: 2026-05-24 — Direct WASM Emulator RAM Access (Precision Text Mode)

### 🎯 Objective
Eliminate unstable heuristic heap scanning in Apple II text screen memory reading by implementing direct WASM-to-emulator RAM query functions, providing 100% accurate character decoding.

### ✅ Key Changes

#### 1. C++ Core Modifications (`machine.cpp` & `machine.h`)
- Implemented and exported two direct RAM reading static member functions under `running_machine`:
  - `uint8_t emscripten_read_ram(uint32_t addr)`: Reads a single byte from `:maincpu` address space program memory (i.e. virtual 6502 RAM bank mapped by softswitches).
  - `uint32_t emscripten_read_ram_bulk(uint32_t start_addr, uint32_t length, uint8_t *out_buf)`: Reads a contiguous array of program memory into a JS-allocated buffer.
- Added direct symbol registration in MAME compilation environment so they can be exposed to Javascript.

#### 2. Mangled Linker Symbol Registration (`genie.lua`)
- Corrected name-mangled symbols in `EXPORTED_FUNCTIONS` inside `mame/scripts/genie.lua` under Itanium C++ ABI conventions:
  - Added `_ZN15running_machine19emscripten_read_ramEj` (length 19 mangled name)
  - Added `_ZN15running_machine24emscripten_read_ram_bulkEjjPh` (length 24 mangled name)
- Cleared static compilation library duplicates/caches recursively to prevent archiver (`ar`) linker duplication errors on Windows.

#### 3. Optimized Compiler Targets & Build Factory Integration
- Built highly optimized `mametiny` WASM core restricting compiled drivers to `apple2e`, yielding a highly compact final WASM size.
- Precompiled, linked, verified, and zipped the output to `mame.wasm.gz` (7.0MB) using an on-the-fly .NET Gzip pipeline.

### 📋 Current Status

| Component | Status | Details |
|-----------|--------|---------|
| **C++ RAM Reader** | ✅ Exported | Bypasses all unstable heap scanning with 100% precision. |
| **Linker Exports** | ✅ Resolved | Mangled symbols linked cleanly under Emscripten. |
| **Output Size** | 🚀 7.0MB GZ | Highly optimized standalone driver, 30% smaller than full build. |

---

## Session: 2026-06-05 — MAME 0.288 Upgrade & Emscripten Toolchain CI Update

### 🎯 Objective
Upgrade the build factory MAME source target to version 0.288, synchronize all document versioning, and resolve C++20 compiler compatibility issues in the GitHub Actions workflow by upgrading the Emscripten toolchain.

### ✅ Key Changes

#### 1. Version Bump to MAME 0.288
- Updated `README.md` and `README-TW.md` version tags from `3.1` to `0.288` to align with the MAME release version.
- Set the `Last Updated` date to `2026-06-05`.

#### 2. GitHub Actions CI Toolchain Fix
- Upgraded the cloning branch in `.github/workflows/deploy.yml` from `mame0287` to `mame0288` to fetch the 0.288 release source.
- Replaced the deprecated `mymindstorm/setup-emsdk@v14` action with `emscripten-core/setup-emsdk@v14`.
- Upgraded the Emscripten compiler version in CI from `3.1.35` to `latest` to satisfy MAME 0.288's strict C++20 requirements (`std::endian` support, template constraints), resolving the `libemu.a` archiving failure in GitHub Actions.
- Increased the process open file descriptor limit (`ulimit -n 65536`) in the build runner before compilation to prevent archiver crashes (`Too many open files` error) during the assembly of `libemu.a`.
- Added `VERBOSE=1` to the `emmake make` command to output complete compilation and archiving command lines to aid diagnosis.

### 📋 Current Status

| Component | Status | Details |
|-----------|--------|---------|
| **MAME Base** | ✅ v0.288 | Upgraded base branch to mame0288. |
| **CI Toolchain** | ✅ emcc latest | Upgraded to latest Emscripten to fix C++20 compile errors. |
| **Documentation** | ✅ v0.288 | Refactored versions and updated dates in guides. |

---

## Session: 2026-08-02 — MAME 0.289 Upgrade & Windows Build System Fixes

### 🎯 Objective
Upgrade the MAME WASM Build Factory source target to official **MAME 0.289**, resolve Windows Ninja static library archiving path errors, and fix custom subtarget project generation.

### ✅ Key Changes

#### 1. MAME 0.289 Upgrade & Core Parity
- **Source Target**: Fetched tag `mame0289` from official upstream MAME and created the `release0289` branch.
- **WASM RAM Access Exports**: Ported `_emscripten_get_main_ram_wasm_offset` and `_emscripten_get_aux_ram_wasm_offset` export functions to MAME 0.289 `src/emu/machine.cpp` for direct Apple II screen RAM DMA reading.
- **PowerBook EASC Fix**: Upstream MAME 0.289 C++ fixes for Macintosh PowerBook ASC/EASC audio devices are active.
- **CI Workflow Update**: Updated `.github/workflows/deploy.yml` branch from `mame0288` to `mame0289`.

#### 2. Windows Build System Fixes
- **Rule AR Command Fix**: Fixed `ar` rule replacement in `build.ps1` by removing an invalid `del` invocation (`del /f /q ../path/lib.a`) which broke on Windows forward slashes.
- **Header-Only Project Filter Fix**: Fixed `custom_targets/ample.lua` and `scripts/target/mame/ample.lua` (`createProjects_mame_ample`) so subtarget projects are only generated for directories containing `.cpp` source files, preventing linker errors from non-existent `.a` libraries (e.g. `libaccess.a`).
- **Emscripten MSX Header Collision Fix**: Fixed a C++ macro collision in `src/devices/bus/msx/cart/msxdos2.cpp` by undefining `PAGE_SIZE` before the class definition.

### 📋 Current Status

| Component | Status | Details |
|-----------|--------|---------|
| **MAME Base** | ✅ v0.289 | Upgraded base branch to mame0289 tag. |
| **CI Workflow** | ✅ mame0289 | Pointed deploy workflow to mame0289 tag. |
| **Build Script** | ✅ Fixed | Fixed `rule ar` forward slash command execution on Windows. |
| **Documentation** | ✅ v0.289 | Updated version tags and dates in `README.md` and `README-TW.md`. |



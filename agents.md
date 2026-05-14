# MAME WASM Build Factory - Agent Log

## Project Overview
Automated toolset for compiling MAME to WebAssembly with high stability and optimization. This repository is self-contained and supports Windows, Linux (via Docker/WSL), and various machine subtargets.

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

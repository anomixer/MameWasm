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

### 💡 Tips for next Session
1. **LTO Benchmarking**: Compare boot times between `-O3` and `-Oz` for the `mac` target.
2. **Automated Patches**: Integrate common MAME source patches (like `PAGE_SIZE` conflicts) directly into the `build.ps1` flow.
3. **WASM Multi-threading**: Explore `-s USE_PTHREADS=1` for multi-core host support in MAME.

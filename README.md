# MAME WASM Build Factory - Complete Guide

Automated toolset for compiling MAME WebAssembly builds on Windows and Linux.

## 📋 Project Structure

```
.
├── setup.ps1                    ← Environment initialization (run first)
├── build.ps1                    ← Main build script (Windows)
├── build-linux.ps1              ← Main build script (Linux)
├── verify_mame_targets.ps1      ← Build verification tool (developer)
├── server.py                    ← Simple local web server (for testing)
├── test_vanilla.html            ← Minimal testing page
├── test_emularity.html          ← Emularity testing page
├── README.md                    ← This complete guide
├── README-TW.md                 ← Traditional Chinese guide
├── custom_targets/              ← User-defined target scripts
├── emularity/                   ← Web loader
├── mame/                        ← MAME source (auto-downloaded)
├── emsdk/                       ← Emscripten SDK (auto-downloaded)
├── bin/                         ← Build tools (auto-created)
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
   - Installs Emscripten SDK
   - Downloads make and GCC tools
   - Clones MAME source code
   - Downloads robby.zip (test ROM)

2. **build.ps1** (repeatable):
   - Interactive interface
   - Asks for TARGET, SUBTARGET, SOURCES
   - Compiles MAME to WebAssembly
   - Copies artifacts to root for testing

3. **Test**:
   - `python server.py` to start local server
   - Open http://localhost:8000/test_vanilla.html
   - Load ROM and play

---

## 🐧 Linux Support (2026-03-09)

You can now build MAME WASM on Linux! Here's how:

### Prerequisites

```bash
# Install PowerShell for Linux
# See: https://docs.microsoft.com/powershell/scripting/install/install-ubuntu
```

### Quick Start (Linux)

```bash
# 1. Install PowerShell
cd ~
mkdir tools && cd tools
wget https://github.com/PowerShell/PowerShell/releases/download/v7.5.1/powershell-7.5.1-linux-x64.tar.gz
tar -xzf powershell-7.5.1-linux-x64.tar.gz
chmod +x pwsh

# 2. Run setup (same as Windows)
cd MameWasm
~/tools/pwsh -ExecutionPolicy Bypass -File ./setup.ps1

# 3. Build for Linux
~/tools/pwsh -ExecutionPolicy Bypass -File ./build-linux.ps1 -Subtarget tiny
```

### What happens?

1. **setup.ps1** - Same as Windows, installs Emscripten SDK, MAME source, etc.
2. **build-linux.ps1** - Linux-specific build script that:
   - Uses Linux genie binary (`3rdparty/genie/bin/linux/genie`)
   - Generates native Makefiles instead of Ninja
   - Compiles with `emmake make`

### Build Output

After successful build, you'll find:
- `mametiny.js` - JavaScript loader (~262KB)
- `mametiny.wasm` - WebAssembly binary (~38MB)
- `mametiny.html` - Test page

### Troubleshooting

**Error: `_IO_FILE` redefinition**
- Fixed in `mame/src/osd/sdl/sdlprefix.h` - removed definition for newer Emscripten SDK compatibility

---

## 📊 Parameter Reference

### TARGET
**High-level build category** (rarely changes)
- Default: `mame`
- Modern MAME usually only supports `mame`

### SUBTARGET
**Which drivers/systems to compile**

| SUBTARGET | Description | Use Case | Size | Time | Note |
|-----------|-------------|----------|------|------|------|
| `tiny` ⭐ | **RECOMMENDED** | General WASM | 30-50MB | 10-20 min | Best for testing, includes Robby Roto |
| `pacmantest` | Pac-Man Only | Quick Testing | ~32MB | 2-5 min | Fastest build |
| `mame` | Full Build | All Games | 80-100MB | 1-2 hours | Needs 16GB+ RAM, may have build issues |
| `<custom>` | User Defined | Specific Drivers | Varies | Varies | Add `.lua` + `.lst` to `custom_targets/` |

*Note: `arcade` and `mess` subtargets are not available in this MAME version.*

*Note: The build script automatically enables memory optimizations (ALLOW_MEMORY_GROWTH) for large builds like 'mame' and 'mess'.*

### SOURCES
**Specific driver files to include** (optional)
- Leave empty: compile all drivers for SUBTARGET
- Examples:
  - `pacman` → `src/mame/pacman/pacman.cpp`
  - `robby` → `src/mame/midway/astrocde.cpp`
  - `src/mame/midw8080/mw8080bw.cpp` → Space Invaders

---

## 🎯 Common Build Scenarios

### Scenario 1: First Time (Balanced)
```powershell
./build.ps1
# When prompted, press Enter for all (accept defaults)
```
**Result**: Minimal WASM (~10-20 min, 30-50MB)

### Scenario 2: Single Game (Pac-Man)
```powershell
./build.ps1
# SUBTARGET: tiny
# SOURCES: pacman
```
**Result**: Just Pac-Man (~5-10 min, 3-5MB)

### Scenario 3: Space Invaders (Taito)
```powershell
./build.ps1
# SUBTARGET: tiny
# SOURCES: src/mame/midw8080/mw8080bw.cpp
```
**Result**: Space Invaders (~5-10 min, 2-4MB)

### Scenario 4: Robby Roto (Midway)
```powershell
./build.ps1
# SUBTARGET: tiny
# SOURCES: robby
```
**Result**: Just Robby Roto (~5-10 min, 2-3MB)

### Scenario 5: Fast Test
```powershell
./build.ps1 -Subtarget pacmantest
```
**Result**: Pac-Man test build (~5 min, 4MB)

### Scenario 6: Complete Build
```powershell
./build.ps1 -Subtarget mame
```
**Result**: Full MAME (~1-2 hours, 80-100MB)

---

## 💡 Pro Tips

### Tip 1: Use Shortcuts
- Type `pacman` → auto-converts to driver path
- Type `robby` → auto-converts to driver path

### Tip 2: Exception Handling
- `Enable` (default): Slower but enables stack traces for crash analysis.
- `Disable`: Faster compilation and execution, use for production.
*Note: The MAME internal debugger is disabled by default to prevent web UI issues.*

### Tip 3: Incremental Builds
- Same SUBTARGET: 1-5 minutes
- Different SOURCES: 5-15 minutes
- First build: 10-20 minutes

### Tip 4: WASM Optimization
```powershell
./build.ps1 -Subtarget tiny -Sources "src/mame/pacman/pacman.cpp"
```
Fast (5 min) + Small (3-5MB) + Focused (one game)

### Tip 5: ROM Setup
```
1. Create ./roms folder
2. Place ROM ZIPs there:
   - pacman.zip
   - invaders.zip (for Space Invaders)
   - robby.zip (for Robby Roto, auto-download by setup.ps1)
3. ROMs must match compiled systems
```

---

## 📈 Build Output & Performance

| Subtarget | Output Files | Est. Size | Est. Time | Use Case |
|-----------|--------------|-----------|-----------|----------|
| **tiny** | `mametiny.js`, `mametiny.wasm` | 30-50MB | 10-20 min | **Recommended** (General WASM) |
| **pacmantest** | `mamepacmantest.js`, `mamepacmantest.wasm` | ~32MB | 2-5 min | Quick testing |
| **mame** | `mame.js`, `mame.wasm` | 80-100MB | 1-2 hours | Full Build (Requires 16GB+ RAM) |

*Note: Filenames correspond to the `-Subtarget` parameter used during build.*

---

## 🎮 Game Driver Paths

Quick reference for popular games:

| Game | Driver File | Command |
|------|-------------|----------|
| Pac-Man | `src/mame/pacman/pacman.cpp` | `pacman` or full path |
| Space Invaders (Taito) | `src/mame/midw8080/mw8080bw.cpp` | Full path (long) |
| Robby Roto | `src/mame/midway/astrocde.cpp` | `robby` or full path |
| Galaxian | `src/mame/galaxian/galaxian.cpp` | Full path |
| Donkey Kong | `src/mame/nintendo/dkong.cpp` | Full path |
| Asteroids | `src/mame/atari/asteroid.cpp` | Full path |
| Tempest | `src/mame/atari/tempest.cpp` | Full path |

---

## 🔧 Command Line Parameters

### build.ps1 Options

```powershell
# Interactive (recommended for first time)
./build.ps1

# Production build (Disabled debugger & exceptions, smaller file)
./build.ps1 -NoDebug

# Single game with NoDebug
./build.ps1 -Subtarget tiny -Sources robby -NoDebug

# Multiple games (comma-separated)
./build.ps1 -Subtarget tiny -Sources "pacman,robby"
```

### setup.ps1 Options

```powershell
# Standard setup
./setup.ps1

# Force reinstall of everything
./setup.ps1 -Force

# Skip prerequisite checks (advanced)
./setup.ps1 -SkipValidation
```

---

## 🧪 Testing Your Build

### Step 1: Start Web Server
```powershell
python server.py
```

### Step 2: Open Test Page
- MAME WASM Loader: http://localhost:8000/test_mamewasm.html (ROM file picker — select any .zip locally)
- Emularity Loader: http://localhost:8000/test_emularity.html (Pre-configured for **Robby Roto**, with splash screen & progress bar)

*Note: The vanilla page lets you pick any local ROM .zip file and enter the driver name. The emularity page is hardcoded for Robby Roto.*

---

## ❌ Common Issues & Solutions

### Issue: "emsdk not found"
```powershell
# Solution: Run setup first
./setup.ps1
```

### Issue: "make command not found"
- setup.ps1 auto-downloads it from GnuWin32
- Or manually install MinGW/GnuWin32

### Issue: Build takes too long
```powershell
# Use faster, smaller build
./build.ps1 -Subtarget pacmantest  # 5 min instead of hours
```

### Issue: Output is too large
```powershell
# Specify single game
./build.ps1 -Subtarget tiny -Sources "src/mame/pacman/pacman.cpp"
# 3-5MB instead of 30-50MB
```

### Issue: Build aborts with "Aborted()" error
- **Cause**: Usually WASM memory exhaustion, missing exception catching, or a runtime exception.
- **Solution 1**: Ensure you are using the latest `build.ps1` which enables `ALLOW_MEMORY_GROWTH=1` and `DISABLE_EXCEPTION_CATCHING=0`.
- **Solution 2**: Rebuild with `-Debug Y` to see the actual error message in the console.
- **Solution 3**: Check Browser Console (F12) for specific JavaScript or WASM errors.
- **Solution 4**: If you see `SyntaxError: Expecting Unicode escape sequence \uXXXX` with `ERRNO_CODES`, the ninja build files have incorrect escaping. The build script now auto-patches this.

### Issue: Path contains Chinese characters
```
❌ Wrong: C:\遊戲\mame-wasm
✅ Right: C:\games\mame-wasm
```

### Issue: File lock during Emscripten install
- setup.ps1 retries automatically
- If still fails, wait a moment and try again

---

## ⚠️ Known Issues & Limitations

### 1. `mame` full build fails with "multiple rules generate" error
- **Error**: `ninja: error: dasm.ninja:130: multiple rules generate ../../../../../generated/emu/cpu/tms57002/tms57002.hxx`
- **Cause**: Upstream MAME build system bug — `dasm.ninja` generates duplicate build rules for the same output file (tms57002.hxx). This is a MAME genie/ninja generation issue, not specific to WASM.
- **Workaround**: Use `tiny` or `pacmantest` subtargets instead. They compile successfully and are much faster anyway.
- **Status**: Unresolved — requires fix in upstream MAME's `scripts/genie.lua` or `scripts/build/makedep.py`.

### 2. `arcade` and `mess` subtargets are not available
- **Error**: `Definition file for TARGET=mame SUBTARGET=arcade does not exist`
- **Cause**: This version of MAME (0.287) does not include `arcade.lua` or `mess.lua` definition files. Only `mame.lua`, `tiny.lua`, and custom targets are supported.
- **Workaround**: Use `tiny` for arcade games (includes most popular ones) or `mame` for everything (if the build issue above is fixed).
- **Status**: By design — these subtargets were removed or never existed in this MAME branch.

### 3. Custom targets require BOTH `.lua` AND `.lst` files
- **Error**: Linker errors with "undefined symbol: driver_xxx" when building custom targets
- **Cause**: The `.lua` file controls which `.cpp` source files are compiled, but `drivlist.cpp` (which lists all available drivers) is controlled separately by a `.lst` file. Without a matching `.lst`, `drivlist.cpp` references ALL 50,000+ drivers, causing linker failures.
- **Solution**: Place both `mytarget.lua` and `mytarget.lst` in `custom_targets/`. The build script copies them to the correct locations automatically.
- **Status**: Fixed — build script now auto-copies `.lst` files.

### 4. `$(2)` in ninja files causes "bad $-escape" error
- **Error**: `ninja: dasm.ninja:44: bad $-escape (literal $ must be written as $$)`
- **Cause**: MAME's genie generates `$(2)` (a CMD argument) in ninja files, but ninja interprets `$(...)` as variable expansion.
- **Solution**: The build script now auto-patches `$(2)` → `$$(2)` in all ninja files.
- **Status**: Fixed in build script.

### 5. `ERRNO_CODES` causes JavaScript SyntaxError
- **Error**: `SyntaxError: Expecting Unicode escape sequence \uXXXX` at `function _\$ERRNO_CODES`
- **Cause**: Genie produces `\$ERRNO_CODES` in ninja link rules. When ninja processes this, the `\$` becomes an invalid escape sequence in the generated JavaScript.
- **Solution**: The build script now auto-patches all `ERRNO_CODES` references to `$$ERRNO_CODES` (ninja's way of producing a literal `$`).
- **Status**: Fixed in build script.

### 6. Exception catching must be enabled for WASM
- **Error**: `Aborted(Assertion failed: Exception thrown, but exception catching is not enabled)`
- **Cause**: MAME uses C++ exceptions internally (e.g., `device_missing_dependencies`). Without exception catching enabled in Emscripten, these exceptions cause an abort.
- **Solution**: The build script now includes `-s DISABLE_EXCEPTION_CATCHING=0` in the ninja link rule.
- **Status**: Fixed in build script.

### 7. Emularity test page shows no display (SDL video mode error)
- **Error**: `SDL: ERROR! Unknown video mode` — the canvas has `display: none` when SDL initializes, preventing it from detecting a valid video mode.
- **Cause**: Emscripten's SDL layer reads canvas dimensions at startup. A hidden canvas returns zero dimensions.
- **Solution**: The canvas is now always visible; the splash screen overlays on top of it and hides once the game starts.
- **Status**: Fixed in `test_emularity.html`.

---

## ⏱️ Typical Workflow

```
Step 1: Setup (one time): 5-10 minutes
  ./setup.ps1

Step 2: First Build: 10-20 minutes
  ./build.ps1 [accept defaults]

Step 3: Test: 2-3 minutes
  python server.py
  [open browser, test]

Step 4: Tweak & Rebuild: 5-10 minutes
  ./build.ps1 [different parameters]

Step 5: Deploy
  Copy mame.js + mame.wasm to web server
```

**Total first use: ~30-45 minutes**

---

## 🎮 Quick Game Examples

### Pac-Man
```powershell
./build.ps1 -Subtarget tiny -Sources "src/mame/pacman/pacman.cpp"
# ROM: pacman.zip
```

### Space Invaders (Taito)
```powershell
./build.ps1 -Subtarget tiny -Sources "src/mame/midw8080/mw8080bw.cpp"
# ROM: invaders.zip
```

### Robby Roto
```powershell
./build.ps1 -Subtarget tiny -Sources "src/mame/midway/astrocde.cpp"
# ROM: astrocde.zip
```

### Galaxian
```powershell
./build.ps1 -Subtarget tiny -Sources "src/mame/galaxian/galaxian.cpp"
# ROM: galaxian.zip
```

---

## 📚 Files & Their Purpose

| File | Purpose | Run? | Required? |
|------|---------|------|----------|
| setup.ps1 | Environment setup | Once | ✅ Yes (first) |
| build.ps1 | Build script | Many | ✅ Yes (each time) |
| server.py | Local web server | Testing | Optional |
| test_vanilla.html | Test page (Robby) | Testing | Optional |
| test_emularity.html | Test page (Emularity) | Testing | Optional |
| README.md | This guide | N/A | ✅ Yes (read) |
| README-TW.md | Chinese guide | N/A | Optional |

---

## 🔧 Advanced: Environment Variables

If you need manual control:

```powershell
# Activate Emscripten
. ./emsdk/emsdk_env.ps1

# Key paths (set automatically by build.ps1):
# ./bin               (gcc/g++/ar shims)
# ./emsdk/upstream/emscripten
# ./emsdk/upstream/bin
# Git Unix tools
```

---

## ⚠️ Important Notes

- **Paths**: No Chinese characters or special symbols
- **RAM**: Build needs 16GB+ RAM recommended
- **Time**: First compile can take 1-2 hours
- **ROMs**: Must match compiled systems
- **WASM**: Files typically 30MB-100MB
- **Emscripten**: Version 3.1.35 or newer

---

## 🚀 Next Steps

1. ✅ Run `setup.ps1`
2. ✅ Run `build.ps1`
3. ✅ Start `server.py`
4. ✅ Test in browser
5. ✅ Deploy `mame.js` + `mame.wasm`

---

## 📞 Need Help?

Check the "Common Issues & Solutions" section above first.

For more details on specific games or drivers, see the "Game Driver Paths" table.

---

**Last Updated**: 2026-04-04
**Version**: 2.3 (Fixed Full Build System — Exception Catching, ERRNO_CODES, Custom Target .lst Filtering)

Good luck! 🎮

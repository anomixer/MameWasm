# MAME WASM Build Factory - Complete Guide

Automated toolset for compiling MAME WebAssembly builds on Windows.

## 📋 Project Structure

```
.
├── setup.ps1                    ← Environment initialization (run first)
├── build.ps1                    ← Main build script (interactive)
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

## 📊 Parameter Reference

### TARGET
**High-level build category** (rarely changes)
- Default: `mame`
- Modern MAME usually only supports `mame`

### SUBTARGET
**Which drivers/systems to compile**

| SUBTARGET | Description | Use Case | Size | Time | Note |
|-----------|-------------|----------|------|------|------|
| `mame` | **Default** | Standard Build | 80-100MB | 1-2 hours | Default if unspecified. |
| `tiny` ⭐ | **RECOMMENDED** | General WASM | 30-50MB | 10-20 min | Best for testing |
| `arcade` | Predefined Arcade | Arcade Only | 70-90MB | 45-60 min | Large build |
| `mess` | Predefined Systems | Computers & Consoles | 60-80MB | 45-60 min | Large build |
| `<custom>` | User Defined | Specific Drivers | Varies | Varies | Use with `SOURCES`. |

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
- `Enable` (default): Slower but better debugging
- `Disable`: Faster if you don't need debugging info

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
| **tiny** | `tiny.js`, `tiny.wasm` | 30-50MB | 10-20 min | **Recommended** (General WASM) |
| **mame** | `mame.js`, `mame.wasm` | 80-100MB | 1-2 hours | Full Build (Requires 16GB+ RAM) |
| **arcade** | `arcade.js`, `arcade.wasm` | 70-90MB | 45-60 min | Arcade games only |
| **mess** | `mess.js`, `mess.wasm` | 60-80MB | 45-60 min | Home computers & consoles |
| **pacmantest** | `pacman.js`, `pacman.wasm` | ~4MB | 2-5 min | Quick testing |

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

# With specific parameters
./build.ps1 -Target mame -Subtarget tiny

# Single game
./build.ps1 -Subtarget tiny -Sources "src/mame/pacman/pacman.cpp"

# Multiple games
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
- Vanilla Loader: http://localhost:8000/test_vanilla.html
- Emularity Loader: http://localhost:8000/test_emularity.html

### Step 3: Load Game
1. Click "Choose File"
2. Select ROM file (e.g., pacman.zip, invaders.zip)
3. Click "Play"

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

### Issue: Path contains Chinese characters
```
❌ Wrong: C:\遊戲\mame-wasm
✅ Right: C:\games\mame-wasm
```

### Issue: File lock during Emscripten install
- setup.ps1 retries automatically
- If still fails, wait a moment and try again

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

**Last Updated**: 2026-01-22
**Version**: 2.1 (Verified Targets & Patches)

Good luck! 🎮
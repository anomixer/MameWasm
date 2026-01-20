# MAME WASM Build Factory - Quick Reference Guide

## ⚡ Quick Start (5 Minutes)

```powershell
# First time only: Setup environment
PowerShell -ExecutionPolicy Bypass -File ./setup.ps1

# Then: Run build (interactive)
PowerShell -ExecutionPolicy Bypass -File ./build.ps1
```

---

## 📊 Parameter Quick Reference

### What is TARGET?
**High-level build category**
- Usually `mame` (default)
- Rarely changes in modern MAME versions
- Most modern MAME versions only support `mame` as TARGET

### What is SUBTARGET?
**Specifies which drivers/systems to compile**
- `tiny` ⭐ **Recommended** - Fast, small, good for WASM
- `mame` - Full build (all arcade systems)
- `mess` - Retro computers & consoles
- `arcade` - Arcade games only
- `pacmantest` - Pac-Man only (fastest!)

### What is SOURCES?
**Specific driver files to include**
- Leave empty = compile all drivers for SUBTARGET
- Examples:
  - `src/mame/pacman/pacman.cpp` (Pac-Man)
  - `src/mame/midway/astrocde.cpp` (Robby Roto)
  - `src/mame/midw8080/mw8080bw.cpp` (Space Invaders / Taito Invaders)
  - Multiple: `file1.cpp,file2.cpp`

---

## 🎯 Common Build Scenarios

### Scenario 1: First Time (Balanced)
```powershell
./build.ps1
# When prompted:
# TARGET: [Enter] (use default: mame)
# SUBTARGET: [Enter] (use default: tiny)
# SOURCES: [Enter] (leave empty for all)
```
**Result**: Minimal WASM build, ~10-20 minutes

### Scenario 2: Single Game (Pac-Man)
```powershell
./build.ps1
# SUBTARGET: tiny
# SOURCES: pacman [or: src/mame/pacman/pacman.cpp]
```
**Result**: Just Pac-Man, ~5-10 minutes, 3-5MB

### Scenario 3: Fast Test (Pac-Man variant)
```powershell
./build.ps1 -Subtarget pacmantest
```
**Result**: Pac-Man test build, ~5 minutes, 4MB

### Scenario 4: Full Build (Everything)
```powershell
./build.ps1 -Subtarget mame
```
**Result**: Complete MAME, ~1-2 hours, 80-100MB

### Scenario 5: Robby Roto (Midway game)
```powershell
./build.ps1
# SUBTARGET: tiny
# SOURCES: robby [or: src/mame/midway/astrocde.cpp]
```
**Result**: Just Robby Roto, ~5-10 minutes

### Scenario 6: Space Invaders (Taito classic)
```powershell
./build.ps1
# SUBTARGET: tiny
# SOURCES: src/mame/midw8080/mw8080bw.cpp
```
**Result**: Space Invaders/Taito Invaders, ~5-10 minutes, 2-4MB

---

## 📈 Size & Time Reference

| Build | File Size | Time | Use Case |
|-------|-----------|------|----------|
| tiny (all) | 30-50MB | 10-20 min | General WASM |
| Pac-Man | 3-5MB | 5-10 min | Single game |
| Space Invaders | 2-4MB | 5-10 min | Classic arcade |
| pacmantest | 4MB | 2-5 min | Testing |
| applulator | 40-50MB | 20-30 min | Apple II |
| arcade | 70-90MB | 45-60 min | Arcades only |
| mess | 60-80MB | 45-60 min | Home computers |
| mame (full) | 80-100MB | 1-2 hours | Everything |

---

## 🔍 Parameters in Detail

### TARGET Examples
```powershell
-Target mame          # Standard MAME (default)
-Target ldplayer      # LDPLAYER (rare, needs checking)
```

### SUBTARGET Examples
```powershell
-Subtarget tiny       # Lightweight (⭐ RECOMMENDED)
-Subtarget mame       # Full MAME
-Subtarget mess       # Computers + consoles
-Subtarget arcade     # Arcade games
-Subtarget pacmantest # Test build
```

### SOURCES Examples
```powershell
-Sources ""                                                           # All drivers
-Sources "src/mame/pacman/pacman.cpp"                               # Pac-Man
-Sources "src/mame/midway/astrocde.cpp"                             # Robby Roto
-Sources "src/mame/midw8080/mw8080bw.cpp"                           # Space Invaders
-Sources "src/mame/pacman/pacman.cpp,src/mame/galaxian/galaxian.cpp"  # Multiple
```

---

## 💡 Pro Tips

### Tip 1: Use Shortcuts
During build prompts:
- Type `pacman` → auto-converts to `src/mame/pacman/pacman.cpp`
- Type `robby` → auto-converts to `src/mame/midway/astrocde.cpp`

### Tip 2: Exception Handling
- `Enable` (default): Slower but better error debugging
- `Disable`: Faster compilation if you don't need debugging

### Tip 3: Incremental Builds
After first build, subsequent builds are faster:
- Same SUBTARGET: 1-5 minutes
- Different sources: 5-15 minutes

### Tip 4: WASM Optimization
For best WebAssembly performance:
```powershell
./build.ps1 -Subtarget tiny -Sources "src/mame/pacman/pacman.cpp"
```
Gives you: Fast (5 min), Small (3-5MB), Focused (one game)

### Tip 5: ROM Files
After building, you'll need ROM files:
- Create `./roms` directory
- Place ROM ZIPs there (e.g., `pacman.zip`, `invaders.zip`)
- ROMs must match the systems you compiled
- **Space Invaders ROM**: Usually named `invaders.zip`

---

## ❌ Common Issues & Solutions

### Issue: PowerShell Quote Escaping Error
**Error**: `Unexpected token '-Oz' in expression or statement`
```
At build.ps1:128 char:65
+ ... EMCC_CFLAGS=\"-Oz\" -j 4"
                  ~~~
```

**Solution 1: Use Single Quotes (RECOMMENDED)** ⭐
修改 `build.ps1` 第 128 行：
```powershell
# 舊的（有問題）:
$buildCmd += " TARGET=$Target PLATFORM=emscripten EMCC_CFLAGS=\"-Oz\" -j 4"

# 新的（修正）:
$buildCmd += " TARGET=$Target PLATFORM=emscripten EMCC_CFLAGS='-Oz' -j 4"
```

**Solution 2: Escape Backslashes** (alternative)
```powershell
$buildCmd += " TARGET=$Target PLATFORM=emscripten EMCC_CFLAGS=`\"-Oz`\" -j 4"
```

**Solution 3: Use Splatting** (advanced)
```powershell
$params = @(
    "SUBTARGET=$Subtarget"
    "TARGET=$Target"
    "PLATFORM=emscripten"
    'EMCC_CFLAGS=-Oz'
    "-j 4"
)
$buildCmd = "make " + ($params -join " ")
```

**How to Fix**:
1. Open `build.ps1` in Notepad
2. Find line 128: `$buildCmd += " TARGET=$Target PLATFORM=emscripten EMCC_CFLAGS=\"-Oz\" -j 4"`
3. Replace `\"` with `'` (single quotes)
4. Save and try again

---

### Issue: "emsdk not found"
**Solution**: Run setup.ps1 first
```powershell
PowerShell -ExecutionPolicy Bypass -File ./setup.ps1
```

### Issue: "make command not found"
**Solution**: Either:
- setup.ps1 will auto-install it
- Or manually: install MinGW or GnuWin32

### Issue: Build takes too long
**Solution**: Use smaller SUBTARGET
```powershell
./build.ps1 -Subtarget pacmantest  # 5 min instead of hours
```

### Issue: Output is too large
**Solution**: Specify specific drivers instead of all
```powershell
./build.ps1 -Subtarget tiny -Sources "src/mame/pacman/pacman.cpp"
# Result: 3-5MB instead of 30-50MB
```

### Issue: Paths contain Chinese characters
**Solution**: Move project to ASCII-only path
```
❌ C:\遊戲\mame-wasm
✅ C:\games\mame-wasm
```

### Issue: Permission Denied on setup.ps1
**Solution**: Run PowerShell as Administrator
```powershell
# Right-click PowerShell → "Run as administrator"
# Then:
PowerShell -ExecutionPolicy Bypass -File ./setup.ps1
```

### Issue: Git LFS files not downloaded
**Solution**: Install Git LFS and retry
```powershell
git lfs install
git lfs pull
```

---

## 🧪 Testing Your Build

### Step 1: Start Web Server
```powershell
python server.py
# Or if python not in PATH:
python.exe server.py
```

### Step 2: Open Test Page
- **Vanilla Loader**: http://localhost:8000/test_vanilla.html
- **Emularity Loader**: http://localhost:8000/test_emularity.html

### Step 3: Load Game
- Click "Choose File" and select ROM file (e.g., `pacman.zip`, `invaders.zip`)
- Click "Play"

---

## 🔧 Environment Variables (Advanced)

If manual setup needed:

```powershell
# Emscripten activation
. ./emsdk/emsdk_env.ps1

# Key paths set by build.ps1:
# - ./bin               (gcc/g++/ar shims)
# - ./emsdk/upstream/emscripten
# - ./emsdk/upstream/bin
# - Git Unix tools
```

---

## 📖 Full Documentation

- **README.md**: Complete English guide
- **README-TW.md**: Full Traditional Chinese guide
- **IMPROVEMENTS.md**: What was fixed/improved
- **build.ps1**: Comments in the script itself

---

## 🎮 Quick Game Building Examples

### Pac-Man
```powershell
./build.ps1 -Subtarget tiny -Sources "src/mame/pacman/pacman.cpp"
# ROM: pacman.zip
```

### Space Invaders (Taito)
```powershell
./build.ps1 -Subtarget tiny -Sources "src/mame/midw8080/mw8080bw.cpp"
# ROM: invaders.zip (or related Taito invaders ROMs)
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

## ⏱️ Typical Workflow

```
1. Setup (one time): 5-10 minutes
   ./setup.ps1

2. First Build: 10-20 minutes
   ./build.ps1 [accept defaults]

3. Test: 2-3 minutes
   python server.py
   [open browser, test]

4. Tweak & Rebuild: 5-10 minutes
   ./build.ps1 [different settings]

5. Deploy: Copy mame.js + mame.wasm to web server
```

**Total first use: ~30-45 minutes**

---

## 🚀 Next Steps

1. ✅ Run setup.ps1
2. ✅ Fix build.ps1 quote escaping (if needed)
3. ✅ Run build.ps1
4. ✅ Run server.py
5. ✅ Test in browser
6. ✅ Deploy mame.js + mame.wasm

Good luck! 🎮

---

Produced by Antigravity Agent
Last Updated: 2025-01-20

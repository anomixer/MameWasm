# MAME WASM Build Factory - Quick Start

## 🚀 Get Started in 30 Seconds

### First Time?

```powershell
# 1. Setup environment (run as Administrator)
PowerShell -ExecutionPolicy Bypass -File ./setup.ps1

# 2. Build MAME
PowerShell -ExecutionPolicy Bypass -File ./build.ps1

# 3. Test
python server.py
# Open: http://localhost:8000/test_vanilla.html
```

---

## 📊 Quick Reference

| Need | Command | Time | Size |
|------|---------|------|------|
| **First Build** | `./build.ps1` (accept defaults) | 10-20 min | 30-50 MB |
| **Pac-Man** | `./build.ps1 -Subtarget tiny -Sources pacman` | 5-10 min | 3-5 MB |
| **Space Invaders** | `./build.ps1 -Subtarget tiny -Sources "src/mame/midw8080/mw8080bw.cpp"` | 5-10 min | 2-4 MB |
| **Robby Roto** | `./build.ps1 -Subtarget tiny -Sources robby` | 5-10 min | 2-3 MB |
| **Fast Test** | `./build.ps1 -Subtarget pacmantest` | 2-5 min | 4 MB |
| **Complete** | `./build.ps1 -Subtarget mame` | 1-2 hours | 80-100 MB |

---

## 📖 Full Documentation

- **[README.md](README.md)** - Complete English guide (all parameters & examples)
- **[README-TW.md](README-TW.md)** - Complete Traditional Chinese guide

---

## ⏱️ What Happens?

### setup.ps1 (First time only)
- Downloads Emscripten SDK
- Installs build tools (make, GCC)
- Clones MAME source code

### build.ps1 (Run anytime)
- Interactive prompts
- Compiles MAME to WebAssembly
- Outputs: `mame.js` + `mame.wasm`

### Test
- `python server.py` → Local web server
- Browser → Load ROM → Play!

---

## 🎮 Popular Games

| Game | Command |
|------|----------|
| Pac-Man | `pacman` |
| Space Invaders | `src/mame/midw8080/mw8080bw.cpp` |
| Robby Roto | `robby` |
| Galaxian | `src/mame/galaxian/galaxian.cpp` |
| Donkey Kong | `src/mame/nintendo/dkong.cpp` |

---

## ❌ Issues?

- **"emsdk not found"** → Run `./setup.ps1`
- **Build too slow** → Use `-Subtarget pacmantest`
- **Output too large** → Specify single game: `-Sources "src/mame/pacman/pacman.cpp"`
- **Path has Chinese chars** → Move to ASCII-only path (e.g., `C:\games\mame-wasm`)

---

**Need more help?** → See [README.md](README.md)

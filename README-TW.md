# MAME WASM Build Factory - 繁體中文完整指南

> 🇺🇸 [English Version](README.md)
> 🎮 [玩 Robby Roto](https://anomixer.github.io/MameWasm/) | [載入你的 ROM](https://anomixer.github.io/MameWasm/play.html)

這是一個自動化的工具包，用於在 Windows 和 Linux 環境下編譯 MAME 的 WebAssembly (WASM) 版本。它簡化了環境設置、源碼下載和編譯參數配置的過程。

## 📋 目錄結構

```
.
├── setup.ps1                    ← 環境初始化腳本（首先執行）
├── build.ps1                    ← 主編譯腳本（Windows）
├── build-linux.ps1              ← 主編譯腳本（Linux）
├── verify_mame_targets.ps1      ← 編譯驗證工具（開發者用）
├── server.py                    ← 簡單的本地網頁伺服器（測試用）
├── test_mamewasm.html           ← MAME WASM 載入器（ROM 檔案選擇器）
├── test_emularity.html          ← Emularity 測試網頁（Robby Roto）
├── README.md                    ← 英文完整指南
├── README-TW.md                 ← 本繁體中文指南
├── custom_targets/              ← 使用者自訂目標腳本
├── emularity/                  ← 網頁載入器
├── mame/                        ← MAME 源碼（自動下載）
├── emsdk/                       ← Emscripten SDK（自動下載）
├── bin/                         ← 編譯工具（自動建立）
└── roms/                        ← 你的 ROM 檔案（手動放置）
```

---

## 🚀 快速開始（5 分鐘）

### 首次設置

```powershell
# 以管理員身分執行
PowerShell -ExecutionPolicy Bypass -File ./setup.ps1

# 然後開始編譯
PowerShell -ExecutionPolicy Bypass -File ./build.ps1
```

### 會發生什麼？

1. **setup.ps1**（只需運行一次）：
   - 安裝 Emscripten SDK
   - 下載 make 和 GCC 工具
   - 複製 MAME 源代碼
   - 下載 robby.zip (測試用 ROM)

2. **build.ps1**（可重複使用）：
   - 互動式介面
   - 詢問 TARGET、SUBTARGET、SOURCES
   - 編譯 MAME 為 WebAssembly
   - 將編譯產物複製到根目錄方便測試

3. **測試**：
   - `python server.py` 啟動本地伺服器
   - 打開 http://localhost:8000/test_mamewasm.html
   - 選擇 ROM 檔案並遊玩

---

## 🐧 Linux / WSL 支援 (2026-04-06)

現在你可以在 Linux 和 WSL 上編譯 MAME WASM 了！**完整 MAME 編譯在 Linux 上穩定可靠** — Windows 上的完整編譯可能因 emscripten 快取競爭條件而失敗。

### 前置需求（WSL）

```bash
# 安裝 WSL（Windows 使用者）
wsl --install

# 在 WSL 內安裝必要套件
sudo apt update && sudo apt install -y build-essential git python3
```

### 快速開始 (Linux / WSL)

```bash
# 1. 複製 MameWasm（或從 Windows 透過 /mnt/c/ 複製）
git clone https://github.com/anomixer/MameWasm.git
cd MameWasm

# 2. 設定 Emscripten SDK
git clone https://github.com/emscripten-core/emsdk.git emsdk-linux
cd emsdk-linux
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh
cd ..

# 3. 複製 MAME 原始碼
git clone --depth 1 https://github.com/mamedev/mame.git

# 4. 編譯完整 MAME WASM
cd mame
emmake make -j$(nproc) \
    OSD=sdl TARGETOS=asmjs GCC=asmjs GCC_VERSION=22.0.0 \
    TARGET=mame SUBTARGET=mame PLATFORM=x64 \
    NO_USE_MIDI=1 NO_USE_PORTAUDIO=1 NO_USE_PULSEAUDIO=1 NO_USE_ALSA=1 \
    NO_USE_BGFX=1 NO_USE_QTDEBUG=1 NO_USE_SYSTEM_LIBS=1 \
    SYMBOLS=0 OPTIMIZE=2 IGNORE_GIT=1
```

### 完整編譯需要的原始碼修補

MAME 0.287 + Emscripten 4.0.5 需要幾個原始碼修補才能完整編譯：

| 檔案 | 問題 | 解法 |
|------|------|------|
| `src/mame/fairlight/cmi.cpp` | `PAGE_SIZE` 巨集與 emscripten 的 `limits.h` 衝突 | 重新命名為 `CMI_PAGE_SIZE` |
| `src/devices/bus/msx/cart/msxdos2.cpp` | 同樣的 `PAGE_SIZE` 衝突 | 重新命名為 `MSX_PAGE_SIZE` |
| `src/devices/cpu/drcbec.cpp` | `#pragma STDC FENV_ACCESS` 不支援 wasm | 用 `#if 0 ... #endif` 包起來 |
| `src/frontend/mame/luaengine.cpp` | sol2 的 `operator=` 模糊問題 | 將 `ret = res` 改為明確的 `std::make_pair(...)` |
| `src/mame/apollo/apollo.cpp` | 未使用變數錯誤 | 加上 `__attribute__((unused))` |

另外需要在產生的 `mame.make` 中將 `INITIAL_MEMORY` 從 `24MB` 提高到 `128MB`。

### 編譯產物

成功編譯完整版本後，你會找到：
- `mame.js` - JavaScript 載入器（約 289KB）
- `mame.wasm` - WebAssembly 二進制檔案（約 210MB，42,740 個驅動程式）
- `mame.html` - 測試網頁

### 問題排解

**錯誤：`_IO_FILE` 重新定義**
- 已在 `mame/src/osd/sdl/sdlprefix.h` 中修復 - 移除定義以相容新版 Emscripten SDK

**錯誤：`initial memory too small`**
- 在產生的 makefile 中增加 `INITIAL_MEMORY`（試試 128MB 或 256MB）

**錯誤：`undefined exported symbol: "__ZN13sound_manager4muteEbh"`**
- 這發生在編譯工具程式（jedutil、floptool 等）時。從產生的 `Makefile` 的 `PROJECTS` 列表中移除工具，或只編譯 `mame` 目標。

---

## 📊 參數參考

### TARGET
**高層級編譯類別**（很少更改）
- 預設值：`mame`
- 現代 MAME 通常只支持 `mame`

### SUBTARGET
**指定要編譯的驅動程式/系統**

| SUBTARGET | 說明 | 實際用途 | 大小 | 時間 | 備註 |
|-----------|------|----------|------|------|------|
| `tiny` ⭐ | **推薦** | 通用 WASM | 30-50MB | 10-20 分 | 適合一般測試，Windows 上可正常編譯 |
| `pacmantest` | 僅 Pac-Man | 快速測試 | ~32MB | 2-5 分 | 最快的編譯選項 |
| `mame` | 完整版本 | 所有遊戲 + MESS | ~210MB | 30-60 分 | **請用 WSL/Linux** — Windows 完整編譯不穩定。包含 42,740 個驅動（Apple II、Mac 等） |
| `<custom>` | 用戶自訂 | 指定特定驅動 | 視情況而定 | 視情況而定 | 在 `custom_targets/` 中加入 `.lua` + `.lst` |

*注意：此版本的 MAME 不提供 `arcade` 和 `mess` subtarget。*

### SOURCES
**指定要包含的驅動程式檔案**（可選）
- 留空：編譯該 SUBTARGET 的所有驅動程式
- 範例：
  - `pacman` → `src/mame/pacman/pacman.cpp`
  - `robby` → `src/mame/midway/astrocde.cpp`
  - `src/mame/midw8080/mw8080bw.cpp` → 太空侵略者

---

## 🎯 常見建立場景

### 場景 1：首次使用（平衡）
```powershell
./build.ps1
# 出現提示時，按 Enter 使用預設值
```
**結果**：最小化 WASM（~10-20 分，30-50MB）

### 場景 2：單一遊戲（Pac-Man）
```powershell
./build.ps1
# SUBTARGET: tiny
# SOURCES: pacman
```
**結果**：只有 Pac-Man（~5-10 分，3-5MB）

### 場景 3：太空侵略者（Taito）
```powershell
./build.ps1
# SUBTARGET: tiny
# SOURCES: src/mame/midw8080/mw8080bw.cpp
```
**結果**：太空侵略者（~5-10 分，2-4MB）

### 場景 4：Robby Roto（Midway）
```powershell
./build.ps1
# SUBTARGET: tiny
# SOURCES: robby
```
**結果**：只有 Robby Roto（~5-10 分，2-3MB）

### 場景 5：快速測試
```powershell
./build.ps1 -Subtarget pacmantest
```
**結果**：Pac-Man 測試構建（~5 分，4MB）

### 場景 6：完整編譯
```powershell
./build.ps1 -Subtarget mame
```
**結果**：完整 MAME（~1-2 小時，80-100MB）

---

## 💡 Pro 提示

### 提示 1：使用快捷方式
- 輸入 `pacman` → 自動轉換為驅動程式路徑
- 輸入 `robby` → 自動轉換為驅動程式路徑

### 提示 2：異常處理
- `Enable`（預設）：較慢但開啟錯誤追蹤（Stack Trace），適合排查崩潰。
- `Disable`：編譯與執行較快，適合生產環境。
*注意：預設不開啟 MAME 內部除錯器，以避免網頁介面卡頓。*

### 提示 3：增量編譯
- 相同 SUBTARGET：1-5 分鐘
- 不同 SOURCES：5-15 分鐘
- 首次編譯：10-20 分鐘

### 提示 4：WASM 最佳化
```powershell
./build.ps1 -Subtarget tiny -Sources "src/mame/pacman/pacman.cpp"
```
快速（5 分）+ 小檔案（3-5MB）+ 專注（單一遊戲）

### 提示 5：ROM 設置
```
1. 建立 ./roms 資料夾
2. 放入 ROM ZIP 檔案：
   - pacman.zip
   - invaders.zip（太空侵略者）
   - robby.zip (Robby Roto, 由setup.ps1自動下載)
3. ROM 必須與編譯的系統相符
```

---

## 📈 構建輸出與效能參考

| Subtarget | 輸出檔案 | 預估大小 | 預估時間 | 用途 |
|-----------|---------|---------|---------|------|
| **tiny** | `mametiny.js`, `mametiny.wasm` | 30-50MB | 10-20 分 | **推薦**（通用 WASM） |
| **pacmantest** | `mamepacmantest.js`, `mamepacmantest.wasm` | ~32MB | 2-5 分 | 快速測試 |
| **mame** | `mame.js`, `mame.wasm` | 80-100MB | 1-2 小時 | 完整版本（建議 16GB+ RAM） |

*注意：輸出檔名通常對應於構建時使用的 `-Subtarget` 參數名稱。*

---

## 🎮 遊戲驅動程式路徑

熱門遊戲的快速參考：

| 遊戲 | 驅動檔案 | 命令 |
|------|---------|------|
| Pac-Man | `src/mame/pacman/pacman.cpp` | `pacman` or 完整路徑 |
| 太空侵略者（Taito） | `src/mame/midw8080/mw8080bw.cpp` | 完整路徑（較長） |
| Robby Roto | `src/mame/midway/astrocde.cpp` | `robby` or 完整路徑 |
| Galaxian | `src/mame/galaxian/galaxian.cpp` | 完整路徑 |
| 大金剛 | `src/mame/nintendo/dkong.cpp` | 完整路徑 |
| 小行星 | `src/mame/atari/asteroid.cpp` | 完整路徑 |
| Tempest | `src/mame/atari/tempest.cpp` | 完整路徑 |

---

## 🔧 命令列參數

### build.ps1 選項

```powershell
# 互動式（首次推薦）
./build.ps1

# 生產環境編譯（停用除錯器與異常處理，檔案更小、速度更快）
./build.ps1 -NoDebug

# 單一遊戲配合 NoDebug
./build.ps1 -Subtarget tiny -Sources robby -NoDebug

# 多個遊戲（使用逗號分隔）
./build.ps1 -Subtarget tiny -Sources "pacman,robby"
```

### setup.ps1 選項

```powershell
# 標準設置
./setup.ps1

# 強制重新安裝所有內容
./setup.ps1 -Force

# 跳過先決條件檢查（進階）
./setup.ps1 -SkipValidation
```

---

## 🧪 測試你的構建

### 步驟 1：啟動網頁伺服器
```powershell
python server.py
```

### 步驟 2：打開測試頁面
- **線上示範**：[玩 Robby Roto](https://anomixer.github.io/MameWasm/) | [載入你的 ROM](https://anomixer.github.io/MameWasm/play.html)
- **本地編譯**：
  - MAME WASM 載入器：http://localhost:8000/test_mamewasm.html（ROM 檔案選擇器）
  - Emularity 載入器：http://localhost:8000/test_emularity.html（Robby Roto）

---

## ❌ 常見問題和解決方案

### 問題：「emsdk not found」
```powershell
# 解決方案：首先執行 setup
./setup.ps1
```

### 問題：「make command not found」
- setup.ps1 自動從 GnuWin32 下載
- 或手動安裝 MinGW/GnuWin32

### 問題：編譯時間太長
```powershell
# 使用更快、更小的構建
./build.ps1 -Subtarget pacmantest  # 5 分而不是數小時
```

### 問題：輸出太大
```powershell
# 指定單一遊戲
./build.ps1 -Subtarget tiny -Sources "src/mame/pacman/pacman.cpp"
# 3-5MB 而不是 30-50MB
```

### 問題：執行時出現「Aborted()」錯誤
- **原因**：通常是 WASM 記憶體耗盡或發生執行階段異常。
- **解決方案 1**：確保使用最新的 `build.ps1`，它已預設開啟 `ALLOW_MEMORY_GROWTH=1`。
- **解決方案 2**：使用 `./build.ps1 -Debug Y` 重新編譯，以在控制台查看具體的錯誤訊息。
- **解決方案 3**：檢查瀏覽器開發者工具 (F12) 的 Console 分頁，查看具體的 JS 或 WASM 報錯。

### 問題：路徑包含中文字元
```
❌ 錯誤：C:\遊戲\mame-wasm
✅ 正確：C:\games\mame-wasm
```

### 問題：Emscripten 安裝時檔案鎖定
- setup.ps1 會自動重試
- 如仍失敗，等待片刻後重試

---

## ⚠️ 已知問題與限制

### 1. `mame` 完整編譯在 Windows 上失敗：「multiple rules generate」或「file has been modified」錯誤
- **錯誤訊息**：`ninja: error: dasm.ninja:130: multiple rules generate ...` 或 `error: 'xxx.h' has been modified during compilation`
- **原因**：Windows 上有兩個獨立問題：
  1. **重複 ninja 規則**：`dasm.ninja` 和 `optional.ninja` 都產生相同的檔案（`tms57002.hxx`、`vaxdasm.o`、`xtensa_helper.o`）。編譯腳本已自動修補。
  2. **Emscripten 快取競爭條件**：平行編譯時，多個 `emcc` 程序同時嘗試更新快取 `.stamp` 檔案，導致「檔案被修改」錯誤。編譯腳本嘗試預熱並鎖定快取，但在 Windows 上不是 100% 可靠。
- **替代方案**：使用 WSL/Linux 進行完整編譯（見上方 Linux/WSL 章節）。`tiny` subtarget 在 Windows 上可正常編譯。
- **狀態**：部分修復 — `tiny` 在 Windows 上可正常運作；完整編譯需要 WSL/Linux。

### 2. `arcade` 和 `mess` subtarget 不可用
- **錯誤訊息**：`Definition file for TARGET=mame SUBTARGET=arcade does not exist`
- **原因**：此版本的 MAME（0.287）沒有包含 `arcade.lua` 或 `mess.lua` 定義檔。僅支援 `mame.lua`、`tiny.lua` 和自訂目標。
- **替代方案**：使用 `tiny` 來玩街機遊戲（包含大多數熱門遊戲），或使用 `mame` 來取得所有遊戲（如果上述編譯問題已修復）。
- **狀態**：設計如此 — 這些 subtarget 在此 MAME 分支中被移除或從未存在過。

### 3. 自訂目標需要同時提供 `.lua` 和 `.lst` 檔案
- **錯誤**：編譯自訂目標時出現連結器錯誤「undefined symbol: driver_xxx」
- **原因**：`.lua` 檔案控制編譯哪些 `.cpp` 原始檔，但 `drivlist.cpp`（列出所有可用驅動程式）是由 `.lst` 檔案分別控制的。如果沒有對應的 `.lst`，`drivlist.cpp` 會參考全部 50,000+ 個驅動程式，導致連結失敗。
- **解決方案**：將 `mytarget.lua` 和 `mytarget.lst` 都放在 `custom_targets/` 中。建構腳本會自動複製到正確位置。
- **狀態**：已修復 — 建構腳本現在會自動複製 `.lst` 檔案。

### 4. ninja 檔案中的 `$(2)` 導致「bad $-escape」錯誤
- **錯誤**：`ninja: dasm.ninja:44: bad $-escape (literal $ must be written as $$)`
- **原因**：MAME 的 genie 在 ninja 檔案中產生 `$(2)`（CMD 的參數），但 ninja 會將 `$(...)` 解讀為變數展開。
- **解決方案**：建構腳本現在會自動將所有 ninja 檔案中的 `$(2)` 修補為 `$$(2)`。
- **狀態**：已修復。

### 5. `ERRNO_CODES` 導致 JavaScript SyntaxError
- **錯誤**：`SyntaxError: Expecting Unicode escape sequence \uXXXX` 出現在 `function _\$ERRNO_CODES`
- **原因**：Genie 在 ninja 連結規則中產生 `\$ERRNO_CODES`。當 ninja 處理時，`\$` 在產生的 JavaScript 中變成無效的跳脫序列。
- **解決方案**：建構腳本現在會自動將所有 `ERRNO_CODES` 參考修補為 `$$ERRNO_CODES`（ninja 產生字面 `$` 的方式）。
- **狀態**：已修復。

### 6. WASM 必須啟用異常捕捉
- **錯誤**：`Aborted(Assertion failed: Exception thrown, but exception catching is not enabled)`
- **原因**：MAME 在內部使用 C++ 異常（例如 `device_missing_dependencies`）。如果沒有在 Emscripten 中啟用異常捕捉，這些異常會導致中止。
- **解決方案**：建構腳本現在在 ninja 連結規則中加入 `-s DISABLE_EXCEPTION_CATCHING=0`。
- **狀態**：已修復。

### 7. Emularity 測試頁面沒有畫面（SDL 視訊模式錯誤）
- **錯誤**：`SDL: ERROR! Unknown video mode` — 當 SDL 初始化時 canvas 是 `display: none`，導致無法檢測有效的視訊模式。
- **原因**：Emscripten 的 SDL 層在啟動時讀取 canvas 尺寸。隱藏的 canvas 會回傳零尺寸。
- **解決方案**：Canvas 現在始終可見；啟動畫面覆蓋在其上方，遊戲開始後消失。
- **狀態**：已修復於 `test_emularity.html`。

---

## ⏱️ 典型工作流程

```
步驟 1：設置（一次性）：5-10 分鐘
  ./setup.ps1

步驟 2：首次編譯：10-20 分鐘
  ./build.ps1 [接受預設值]

步驟 3：測試：2-3 分鐘
  python server.py
  [打開瀏覽器，測試]

步驟 4：調整和重新編譯：5-10 分鐘
  ./build.ps1 [不同參數]

步驟 5：部署
  將 mame.js + mame.wasm 複製到網頁伺服器
```

**總計首次使用：~30-45 分鐘**

---

## 🎮 快速遊戲範例

### Pac-Man
```powershell
./build.ps1 -Subtarget tiny -Sources "src/mame/pacman/pacman.cpp"
# ROM：pacman.zip
```

### 太空侵略者（Taito）
```powershell
./build.ps1 -Subtarget tiny -Sources "src/mame/midw8080/mw8080bw.cpp"
# ROM：invaders.zip
```

### Robby Roto
```powershell
./build.ps1 -Subtarget tiny -Sources "src/mame/midway/astrocde.cpp"
# ROM：astrocde.zip
```

### Galaxian
```powershell
./build.ps1 -Subtarget tiny -Sources "src/mame/galaxian/galaxian.cpp"
# ROM：galaxian.zip
```

---

## 📚 檔案及其用途

| 檔案 | 用途 | 執行？ | 必需？ |
|------|------|--------|--------|
| setup.ps1 | 環境設置 | 一次 | ✅ 是（首次） |
| build.ps1 | 編譯腳本 | 多次 | ✅ 是（每次） |
| server.py | 本地網頁伺服器 | 測試時 | 可選 |
| test_mamewasm.html | 測試頁面（ROM 選擇器） | 測試時 | 可選 |
| test_emularity.html | 測試頁面（Emularity） | 測試時 | 可選 |
| README.md | 英文指南 | N/A | ✅ 是（閱讀） |
| README-TW.md | 本繁體中文指南 | N/A | 可選 |

---

## 🔧 進階：環境變數

如果你需要手動控制：

```powershell
# 激活 Emscripten
. ./emsdk/emsdk_env.ps1

# 關鍵路徑（由 build.ps1 自動設置）：
# ./bin               (gcc/g++/ar shims)
# ./emsdk/upstream/emscripten
# ./emsdk/upstream/bin
# Git Unix 工具
```

---

## ⚠️ 重要注意事項

- **路徑**：不應包含中文字元或特殊符號
- **RAM**：編譯需要 16GB+ RAM（推薦）
- **時間**：首次編譯可能需要 1-2 小時
- **ROM**：必須與編譯的系統相符
- **WASM**：檔案通常為 30MB-100MB
- **Emscripten**：版本 3.1.35 或更新

---

## 🚀 下一步

1. ✅ 執行 `setup.ps1`
2. ✅ 執行 `build.ps1`
3. ✅ 啟動 `server.py`
4. ✅ 在瀏覽器中測試
5. ✅ 部署 `mame.js` + `mame.wasm`

---

## 📞 需要幫助？

首先查看上面的「常見問題和解決方案」部分。

有關特定遊戲或驅動程式的更多詳情，請參見「遊戲驅動程式路徑」表格。

---

**最後更新**：2026-04-06
**版本**：2.4（WSL/Linux 完整編譯支援、動態 Python 路徑偵測、重複 Ninja 規則修復）

祝你順利！🎮


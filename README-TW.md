# MAME WASM Build Factory - 繁體中文完整指南

這是一個自動化的工具包，用於在 Windows 環境下編譯 MAME 的 WebAssembly (WASM) 版本。它簡化了環境設置、源碼下載和編譯參數配置的過程。

## 📋 目錄結構

```
.
├── setup.ps1                    ← 環境初始化腳本（首先執行）
├── build.ps1                    ← 主編譯腳本（互動式介面）
├── README.md                    ← 英文完整指南
├── README-TW.md                 ← 本繁體中文指南
├── emularity/                   ← 網頁載入器
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

2. **build.ps1**（可重複使用）：
   - 互動式介面
   - 詢問 TARGET、SUBTARGET、SOURCES
   - 編譯 MAME 為 WebAssembly

3. **測試**：
   - `python server.py` 啟動本地伺服器
   - 打開 http://localhost:8000/test_vanilla.html
   - 載入 ROM 並遊玩

---

## 📊 參數參考

### TARGET
**高層級編譯類別**（很少更改）
- 預設值：`mame`
- 現代 MAME 通常只支持 `mame`

### SUBTARGET
**指定要編譯的驅動程式/系統**

| SUBTARGET | 說明 | 用途 | 大小 | 時間 |
|-----------|------|------|------|------|
| `tiny` ⭐ | **推薦** 最小化構建 | 通用 WASM | 30-50MB | 10-20 分 |
| `mame` | 完整 MAME（所有街機） | 完整模擬器 | 80-100MB | 1-2 小時 |
| `mess` | 復古電腦和遊戲主機 | 家用系統 | 60-80MB | 45-60 分 |
| `arcade` | 僅街機遊戲 | 街機專用 | 70-90MB | 45-60 分 |
| `pacmantest` | Pac-Man 測試構建 | 快速測試 | 4MB | 2-5 分 |
| `applulator` | Apple II 系統 | Apple II 模擬 | 40-50MB | 20-30 分 |
| `pacem` | Pac-Man 變體 | 最小化 | 5-8MB | 5-10 分 |

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
- `Enable`（預設）：較慢但有更好的除錯
- `Disable`：如不需除錯則較快

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
   - astrocde.zip（Robby Roto）
3. ROM 必須與編譯的系統相符
```

---

## 📈 構建輸出與效能參考

| Subtarget | 輸出檔案 | 預估大小 | 預估時間 | 用途 |
|-----------|---------|---------|---------|------|
| **tiny** | `tiny.js`, `tiny.wasm` | 30-50MB | 10-20 分 | **推薦**（通用 WASM） |
| **mame** | `mame.js`, `mame.wasm` | 80-100MB | 1-2 小時 | 完整版本（建議 16GB+ RAM） |
| **arcade** | `arcade.js`, `arcade.wasm` | 70-90MB | 45-60 分 | 僅街機遊戲 |
| **applulator** | `applulator.js`, `applulator.wasm` | 40-50MB | 20-30 分 | Apple II 系列 |
| **mess** | `mess.js`, `mess.wasm` | 60-80MB | 45-60 分 | 家用電腦與主機 |
| **pacmantest** | `pacman.js`, `pacman.wasm` | ~4MB | 2-5 分 | 快速測試 |

*注意：輸出檔名通常對應於構建時使用的 `-Subtarget` 參數名稱。*

---

## 🎮 遊戲驅動程式路徑

熱門遊戲的快速參考：

| 遊戲 | 驅動檔案 | 命令 |
|------|---------|------|
| Pac-Man | `src/mame/pacman/pacman.cpp` | `pacman` 或完整路徑 |
| 太空侵略者（Taito） | `src/mame/midw8080/mw8080bw.cpp` | 完整路徑（較長） |
| Robby Roto | `src/mame/midway/astrocde.cpp` | `robby` 或完整路徑 |
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

# 指定特定參數
./build.ps1 -Target mame -Subtarget tiny

# 單一遊戲
./build.ps1 -Subtarget tiny -Sources "src/mame/pacman/pacman.cpp"

# 多個遊戲
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
- Vanilla 載入器：http://localhost:8000/test_vanilla.html
- Emularity 載入器：http://localhost:8000/test_emularity.html

### 步驟 3：載入遊戲
1. 點擊「Choose File」
2. 選擇 ROM 檔案（例如 pacman.zip、invaders.zip）
3. 點擊「Play」

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

### 問題：路徑包含中文字元
```
❌ 錯誤：C:\遊戲\mame-wasm
✅ 正確：C:\games\mame-wasm
```

### 問題：Emscripten 安裝時檔案鎖定
- setup.ps1 會自動重試
- 如仍失敗，等待片刻後重試

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
| test_vanilla.html | 測試頁面（Robby） | 測試時 | 可選 |
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

**最後更新**：2025-01-20
**版本**：2.0（整合和清理）

祝你順利！🎮

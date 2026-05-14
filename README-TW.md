# MAME WASM Build Factory - 繁體中文完整指南 (v3.0)

> 🇺🇸 [English Version](README.md)
> 🎮 [玩 Robby Roto](https://anomixer.github.io/MameWasm/) | [載入你的 ROM](https://anomixer.github.io/MameWasm/play.html)

這是一個自動化的工具包，用於在 Windows 和 Linux 環境下編譯 MAME 的 WebAssembly (WASM) 版本。雖然它針對 AmpleWeb 進行了極致的最佳化，但本質上是一個通用型的 MAME WASM 編譯工廠，適用於各種 Web 整合場景。

## 📋 目錄結構

```
.
├── setup.ps1                    ← 環境初始化腳本（首先執行）
├── build.ps1                    ← 主編譯腳本（Windows，支援生產模式）
├── build-linux.ps1              ← 主編譯腳本（Linux）
├── analyze_roms_v3.py           ← 獨立的 ROM 依賴分析工具
├── verify_mame_targets.ps1      ← 編譯驗證工具（開發者用）
├── server.py                    ← 簡單的本地網頁伺服器（測試用）
├── test_mamewasm.html           ← MAME WASM 載入器（ROM 檔案選擇器）
├── test_emularity.html          ← Emularity 測試網頁（Robby Roto）
├── Dockerfile                   ← Docker 編譯環境定義
├── docker-compose.yml           ← Docker Compose 配置
├── README.md                    ← 英文完整指南
├── README-TW.md                 ← 本繁體中文指南
├── custom_targets/              ← 使用者自訂目標腳本（包含 ample 目標）
├── emularity/                   ← 網頁載入器組件
├── mame/                        ← MAME 源碼（自動下載）
├── emsdk/                       ← Emscripten SDK（自動下載）
├── bin/                         ← 編譯工具與原生 MAME (mame.exe) 放置處
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
   - 安裝 Emscripten SDK。
   - 下載 `make` 和 `ninja` 編譯工具。
   - 複製 MAME 源代碼。
   - 下載 `robby.zip` (測試用 ROM)。

2. **build.ps1**（可重複使用）：
   - 提供互動式介面選擇 TARGET、SUBTARGET。
   - **新增：生產模式 (Production Mode)**：可選擇使用 `-Oz` 與 `LTO` 進行極致壓縮。
   - 使用 Ninja 編譯系統加速編譯。
   - 自動套用 Windows 特定補丁（修正命令長度限制與 JS 語法錯誤）。
   - 將編譯產物複製到根目錄方便測試。

3. **分析與映射 (選用)**：
   - 僅當你需要產生 ROM 遞歸依賴映射（通常是為了整合進 AmpleWeb）時，才執行 `python analyze_roms_v3.py`。
   - 分析結果會存入 **`rom_mapping_results_v3.txt`**。你可以直接複製其中的內容到 AmpleWeb 的配置中。

4. **測試**：
   - 執行 `python server.py` 啟動本地伺服器。
   - 在瀏覽器中打開 `test_mamewasm.html` 驗證結果。

---

## 🌟 關鍵功能：生產模式 (Production Mode)

在 `build.ps1` 的優化選項中，你可以選擇 **Production** 模式，這將啟用：
- **-Oz 最佳化**：針對二進制體積進行最激進的縮減。
- **LTO (Link-Time Optimization)**：跨模組連結優化，讓程式碼更精簡、執行更流暢。
- **1GB 初始記憶體**：確保大型機型（如 Macintosh 68k, Apple IIgs）在瀏覽器中穩定啟動。
- **停用異常處理 (Optional)**：進一步縮小檔案並提升效能（適合發布版）。

---

## 🐳 Docker 支援（推薦用於完整編譯）

為了避開 Windows 上的檔案鎖定與連結器競爭問題，建議使用 Docker 進行編譯。

```bash
# 使用 Docker Compose 啟動編譯環境
docker-compose run mame-build mame-build TARGET=mame SUBTARGET=ample
```

這會在容器內使用穩定版本的 Linux 環境編譯出最適合 Web 使用的 `mame.wasm`。

---

## 🐧 原生 Linux / WSL 支援

如果你不想使用 Docker，也可以在 Linux/WSL 上直接編譯。

### 前置需求（Ubuntu/Debian）
```bash
sudo apt update && sudo apt install -y build-essential git python3
```

### 快速開始 (Linux / WSL)
1. **設定 EMSDK**: `git clone https://github.com/emscripten-core/emsdk.git`
2. **啟用**: `cd emsdk && ./emsdk install latest && ./emsdk activate latest && source ./emsdk_env.sh`
3. **編譯**: `cd mame && emmake make -j$(nproc) TARGET=mame SUBTARGET=ample OSD=sdl TARGETOS=asmjs`

---

## 📊 參數參考與機型清單

### SUBTARGET 選擇

| SUBTARGET | 說明 | 體積 | 建議模式 |
|-----------|------|------|----------|
| `tiny` ⭐ | **推薦測試用** | 30-50MB | Debug (快速) |
| `ample` 🚀| **AmpleWeb 專用** | 45-60MB | Production (體積小) |
| `mame` | 完整版本 (4 萬個驅動) | ~210MB | Docker (最穩定) |

### 🔍 獨立依賴分析工具 (`analyze_roms_v3.py`) [選用]
這是一個專為 AmpleWeb 等專案打造的工具，用於自動遞歸分析機型的 ROM 依賴。
- **用法**：在 `bin/` 放一個原生 `mame.exe`，更新 `custom_targets/ample.lst`，然後執行此腳本。
- **優點**：不再依賴外部專案路徑，完全獨立運作。

---

## 💡 Pro 提示

### 提示 1：增量編譯 (Incremental Build)
- 只要不切換 SUBTARGET，再次編譯只需 1-5 分鐘。
- 如果修改了 `custom_targets/*.lst`，建議重新執行 `build.ps1`。

### 提示 2：WASM 優化建議
- 如果你的 WASM 檔案超過 100MB 且載入緩慢，請務必使用 **Production** 模式編譯。
- 開啟 **LTO** 雖然會增加連結時間（Link Time），但能顯著提升瀏覽器端的執行效率。

### 提示 3：ROM 設置
- 建立 `./roms` 資料夾並放入 ZIP（如 `apple2e.zip`）。
- 使用 `test_mamewasm.html` 測試時，載入器會自動將 ZIP 寫入 WASM 虛擬檔案系統。

---

## ❌ 常見問題與解決方案

### 問題：執行時出現「Aborted()」或「Out of memory」
- **解法**：這是因為機型需要的記憶體超過了 WASM 預設值。新版 `build.ps1` 已將 `INITIAL_MEMORY` 提升至 1GB，請重新編譯。

### 問題：出現「PAGE_SIZE」衝突錯誤
- **解法**：這是 MAME 源碼與 Emscripten SDK 的命名衝突。請參考 `README` 中的「已知原始碼修補」部分，手動修改 `cmi.cpp` 或 `msxdos2.cpp` 中的變數名稱。

### 問題：Windows 下 Ninja 報錯「multiple rules generate」
- **解法**：新版 `build.ps1` 已內建自動修補程式，會自動過濾掉 `dasm.ninja` 與 `optional.ninja` 中的重複規則。如果仍發生，請嘗試刪除 `build/` 資料夾後重新編譯。

---

## ⚠️ 重要注意事項

- **儲存庫獨立性**：此專案現在是 100% 獨立的，不依賴任何外部路徑。
- **路徑限制**：資料夾路徑絕對不能包含中文字元或空格。
- **RAM 需求**：編譯 `mame` 完整目標時，建議主機至少有 16GB 以上的 RAM。

---

**最後更新**：2026-05-03
**版本**：3.0 (生產模式、Docker 化、獨立分析工具、LTO 支持)

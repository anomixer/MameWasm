# MAME WASM Build Factory - 繁體中文完整指南 (v0.289)

> 🇺🇸 [English Version](README.md)
> 🎮 [玩 Robby Roto](https://anomixer.github.io/MameWasm/) | [載入你的 ROM](https://anomixer.github.io/MameWasm/play.html)

這是一個自動化的工具包，用於在 Windows 和 Linux 環境下編譯 MAME 的 WebAssembly (WASM) 版本。雖然它針對 AmpleWeb 進行了極致的最佳化，但本質上是一個通用型的 MAME WASM 編譯工廠，適用於各種 Web 整合場景。

## 📋 目錄結構

```
.
├── 🛠️ 編譯腳本 (Build Scripts)
│   ├── setup.ps1             ← 環境初始化 (Run first)
│   ├── build.ps1             ← Windows 編譯腳本
│   └── build-linux.ps1       ← Linux / WSL 編譯腳本
│
├── 🎯 自訂目標 (Custom Targets)
│   └── custom_targets/       ← LUA/LST 目標定義 (supracan, ample)
│
├── 🌐 網頁與測試 (Web & Testing)
│   ├── test_mamewasm.html    ← 進階多檔案載入器
│   ├── test_emularity.html   ← Emularity 測試網頁 (Robby Roto)
│   └── server.py             ← 本地測試伺服器
│
├── 📦 核心組件 (Core Components)
│   ├── mame/                 ← MAME 原始碼樹
│   ├── emsdk/                ← Emscripten SDK
│   └── bin/                  ← 編譯工具與原生 MAME
│
└── 💾 ROM 與數據 (ROMs & Data)
    ├── roms/                 ← 存放 ROM 的資料夾
    └── analyze_roms_v3.py    ← 依賴關係分析工具
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
1. **setup.ps1**：安裝 EMSDK、編譯工具 (Ninja/Make)，並下載 MAME 源碼。
2. **build.ps1**：提供互動介面選擇目標、子目標以及優化模式。
3. **測試**：執行 `python server.py` 並開啟 `test_mamewasm.html`。

---

## 🌟 關鍵功能：生產模式 (Production Mode)

當透過 `build.ps1` 編譯時，可以選擇 **Production** 模式，這將啟用：
- **極致優化 (-Oz)**：針對二進制體積進行最激進的縮減。
- **LTO (Link-Time Optimization)**：跨模組連結優化，顯著提升效能。
- **穩定記憶體**：自動設置 `INITIAL_MEMORY` 為 1GB，`MAXIMUM_MEMORY` 為 4GB。
- **停用異常處理**：進一步縮小檔案並提升發布版的執行速度。

---

## 🧠 直接 WASM 模擬器記憶體讀取技術 (DMA Tech)

本專案提供了一套先進的自訂記憶體讀取通道，允許外部 JavaScript 直接查詢模擬器的核心虛擬記憶體空間（例如 6502 虛擬 CPU 的 RAM），完全繞過了脆弱不穩定的 Heap 堆積指紋掃描（heuristic heap scanning）。

### 導出函數（Exported Functions）
編譯架構自動將 MAME 的 `running_machine` 核心 C++ 靜態函數導出至 WebAssembly/JavaScript 環境中：

1.  **單字節讀取 (Single Byte Read)**：
    `uint8_t emscripten_read_ram(uint32_t addr)`
    *JS 呼叫方式*：`Module._ZN15running_machine19emscripten_read_ramEj(addr)`
    *說明*：直接從主處理器 `:maincpu` 的 AS_PROGRAM 位址空間（包含軟開關 MMU 映射後的當前 RAM Bank）讀取單個位元組。

2.  **整塊讀取 (Bulk Buffer Read)**：
    `uint32_t emscripten_read_ram_bulk(uint32_t start_addr, uint32_t length, uint8_t *out_buf)`
    *JS 呼叫方式*：`Module._ZN15running_machine24emscripten_read_ram_bulkEjjPh(start_addr, length, ptr)`
    *說明*：將 `:maincpu` 中從 `start_addr` 開始的 `length` 長度記憶體直接複製到由 JS 分配的 WebAssembly 指標（`ptr`）中，適合高效傳輸整頁螢幕 RAM 文字。

---

## 🐳 Docker 支援（推薦用於完整編譯）

為了避開 Windows 上的檔案鎖定與連結器競爭問題，建議使用 Docker 進行編譯：
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
3. **編譯**: `PowerShell -File ./build-linux.ps1` (或手動使用 `emmake make`)

---

## 📊 參數參考與機型清單

| SUBTARGET | 說明 | 體積 | 建議模式 |
|-----------|------|------|----------|
| `tiny` ⭐ | 推薦測試用 | 30-50MB | Debug (快速) |
| `ample` 🚀| AmpleWeb 最佳化 | 45-60MB | Production (Oz + LTO) |
| `supracan`| Super A'Can 自訂目標 | ~40MB | Production |
| `mame` | 完整版本 (4 萬個驅動) | ~210MB | Docker (最穩定) |

### 💡 編譯實戰範例 (Examples)

你可以透過 `-Sources` 參數來編譯特定的機型，以下是常見範例：

*   **Apple IIe**:
    `PowerShell -File ./build.ps1 -Subtarget tiny -Sources apple2e`
*   **Pac-Man**:
    `PowerShell -File ./build.ps1 -Subtarget tiny -Sources pacman`
*   **街機多合一 (多個驅動)**:
    `PowerShell -File ./build.ps1 -Subtarget tiny -Sources pacman,robby,dkong`
*   **自訂目標 (以 A'Can 為例)**:
    `PowerShell -File ./build.ps1 -Subtarget supracan -Optimization Production`
    *(註：使用 Production 模式可開啟 Oz 與 LTO 優化，讓 WASM 檔案更小、執行更快。)*

---

## 🎮 測試環境 (`test_mamewasm.html`)

本專案包含一個進階且易用的測試網頁，專門用於開發過程中快速驗證 WASM 編譯產物。

### 🔧 介面欄位說明
1.  **WASM JS**: 填寫你編譯出來的 JS 檔名（例如 `mamesupracan.js` 或 `mametiny.js`）。
2.  **Driver**: 填寫 MAME 的機器名稱（例如 `supracan` 或 `apple2e`）。
3.  **Extra Args**: 填寫額外的 MAME 命令列參數。
    *   *重要範例*：掛載卡帶請使用 `-cart /roms/你的遊戲檔名.zip`。
4.  **ROM 檔案選擇**: 點擊後選取所有必要的 ZIP 檔案。

### 📝 標準操作流程 (Step-by-Step)
1.  **填寫設定**：先輸入 **WASM JS** 與 **Driver** 名稱。
2.  **輸入參數**：若有卡帶或軟體清單需求，在 **Extra Args** 填入路徑（路徑開頭必為 `/roms/`）。
3.  **選取檔案**：點擊「選擇檔案」，並在視窗中**同時選中所有 ZIP**（例如 `supracan.zip` + `umc6650.zip` + `game.zip`）。
4.  **執行**：點擊 **Load & Run**。頁面會自動記住你的設定並重新整理開始執行。
5.  **重設**：若設定錯誤導致無法操作，點擊紅色的 **Clear Settings** 即可清空並回到初始狀態。

---

## 💡 Pro 提示

### 提示 1：進階自訂目標 (Custom Targets)
由於 MAME 的架構極其複雜，某些需要特定核心的機型（如 `supracan`），單純使用 `-Sources` 可能不足。
- 你可以在 `custom_targets/` 中自定義 `.lst` 與 `.lua` 檔。
- **AI 輔助工作流**：你可以請 AI 幫忙「撰寫 MAME Genie LUA 定義檔」，並放入 `custom_targets` 目錄。

### 提示 2：增量編譯 (Incremental Build)
- 只要不切換 SUBTARGET，再次編譯只需 1-5 分鐘。
- 如果修改了 `custom_targets/*.lst`，建議重新執行 `build.ps1`。

---

## ❌ 常見問題與解決方案

### 問題：執行時出現「Aborted()」或「Out of memory」
- **解法**：這是記憶體不足。請使用 `build.ps1` 重新編譯，它會自動將記憶體提升至 1GB。

### 問題：出現「PAGE_SIZE」衝突錯誤
- **解法**：這是 MAME 與 Emscripten 的命名衝突。請手動修改 `cmi.cpp` 或 `msxdos2.cpp` 中的變數名稱。

### 問題：Windows 下 Ninja 報錯「multiple rules generate」
- **解法**：腳本會自動修補 `dasm.ninja`。如果仍發生，請嘗試刪除 `build/` 資料夾後重新編譯。

---

## ⚠️ 重要注意事項
- **獨立性**：100% 獨立的工具鏈，不依賴外部路徑。
- **路徑限制**：資料夾路徑絕對不能包含中文字元或空格。
- **RAM 需求**：建議至少有 16GB 以上的 RAM。

**最後更新**：2026-08-02
**版本**：0.289

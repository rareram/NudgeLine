# NudgeLine

<p align="center">
  <img src="docs/images/app_icon.png?v=2" width="128" height="128" alt="NudgeLine Icon" />
</p>

<p align="center">
  <strong>靜臥於螢幕邊緣的今日時光線</strong><br>
  <em>macOS 15+ (Sequoia) / Swift 6, SwiftUI</em>
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README_KR.md">한국어</a> | <a href="README_JP.md">日本語</a> | <a href="README_CN.md">简体中文</a> | <strong>繁體中文</strong> | <a href="README_RU.md">Русский</a> | <a href="README_NL.md">Nederlands</a> | <a href="README_FR.md">Français</a> | <a href="README_DE.md">Deutsch</a> | <a href="README_ES.md">Español</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2015.0%2B%20(Sequoia)-blue.svg" alt="Platform" />
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift Version" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%2F%20Intel-success.svg" alt="Architecture" />
  <img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="License" />
</p>

---

## 為什麼選擇 NudgeLine？

在 32 位元 macOS 時代，開發者曾非常喜愛一款經典的時間管理小工具 [PixelScheduler](https://pixelscheduler.art-mixture.com/)。然而隨著 macOS 全面轉向 64 位元，該軟體的開發不得不畫下句點。懷抱著這份不捨與期待，NudgeLine 應運而生——這是專為現代 macOS 打造的純原生全新作品。

它傳承了原作極簡的螢幕邊框行程線條概念，同時融入了游標靠近時會靈活躲藏的桌面寵物、細膩豐富的開始特效，以及對現代視訊會議與 Apple「提醒事項」的深度原生整合，帶來既實用又療癒的桌面體驗：

- **無感環境型時間線 (Zero Interference)**: 緊貼螢幕邊框，以 1–10px 的極細色彩線條安靜呈現。無需開啟笨重的行事曆視窗，即可自然掌握一天中時間的流動。線條以外區域的滑鼠點擊與捲動會 100% 穿透至下方的應用程式（瀏覽器、程式碼編輯器等），絕不干擾您專注的工作流程。
- **一鍵生產力直達 (1-Click Productivity Bridge)**: 深度支援 Google Meet、Zoom、Microsoft Teams、FaceTime 等 11 大主流視訊會議平台，一鍵瞬間加入會議；自動解構企業安全重新導向連結（Microsoft Defender SafeLinks、Google Redirects）還原純淨直達連結；更無縫辨識備忘錄中的 Notion、Slack、Things、Obsidian 等 10 大生產力工具深度連結，配以精緻的原生專屬徽章。
- **溫和優雅的感官回饋 (Calm Sensory Feedback)**: 行程開始前 5–20 分鐘，時間線會以輕柔優雅的微脈衝呼吸動畫提醒您即將到來的行程。滑鼠靠近時，陪伴在螢幕邊緣的可愛寵物（三花貓、白色珍島犬、白虎）會自然躲入邊框身後；在需要全神貫注時，只需點擊即可開啟暫停小憩（Snooze）。
- **100% 純原生與極致隱私 (Zero Overhead & Absolute Privacy)**: 零第三方外部依賴庫，基於純粹的 SwiftUI、AppKit 與 EventKit 打造，閒置記憶體佔用低於 25MB，耗電極低。零外部網路通訊，您的所有行程與提醒事項均在 Mac 本地安全記憶體中完成處理。

<div align="center">
  <video src="https://github.com/user-attachments/assets/63386ef2-a62a-44bb-a629-badb966f11a5" width="85%" controls></video>
</div>

<p align="center">
  <img src="docs/images/pet_hide_tail_peek.gif" width="130" height="167" title="隱藏 (搖尾巴)" alt="隱藏 (搖尾巴)" style="margin: 0 18px;" />&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/images/pet_hide_head_peek.gif" width="130" height="167" title="隱藏 (探出頭)" alt="隱藏 (探出頭)" style="margin: 0 18px;" />&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/images/pet_hide_pop.gif" width="130" height="167" title="消失 (啵!)" alt="消失 (啵!)" style="margin: 0 18px;" /><br>
  <em>當滑鼠游標靠近時，桌面寵物會靈活地躲至螢幕邊框後或漸隱消失（支援 6 種躲避動作）。</em>
</p>

---

## 安裝與初始化指南

### 1. 透過 Homebrew 安裝 (推薦)

在終端機中執行以下單行指令即可輕鬆完成安裝：

```bash
brew install rareram/tap/nudgeline
```

更新至最新版本：
```bash
brew upgrade rareram/tap/nudgeline
```

---

### 2. 直接下載 DMG 映像檔安裝

1. 前往 [GitHub Releases](https://github.com/rareram/NudgeLine/releases) 下載 `NudgeLine.dmg`，並將 `NudgeLine.app` 拖移至 `/Applications`（應用程式）檔案夾中。
2. 後續更新版本可透過選單列圖示的 **[檢查更新項目…]** 選單實現一鍵應用程式內靜默升級。

---

### 3. 首次啟動權限與安全須知

NudgeLine 目前處於開源發布階段，首次執行時需進行 macOS 標準的系統權限確認：

1. **Gatekeeper 安全提示確認 (僅首次啟動)**:
   - 由於未包含商業開發者憑證，首次啟動時可能會彈出安全攔截提示。
   - 在「應用程式」檔案夾中對 `NudgeLine.app` **按一下右鍵 (或按住 Control 點擊) > 選擇 [打開]**，或在終端機中執行：
     ```bash
     xattr -cr /Applications/NudgeLine.app
     ```
2. **行事曆與提醒事項取用權限 (TCC)**:
   - 首次啟動時會彈出系統提示，要求讀取行程和提醒事項以呈現時間線。
   - 您可隨時在 **系統設定 > 隱私權與安全性 > 行事曆 / 提醒事項** 中審查和管理權限狀態。
3. **Apple Events 聯動權限**:
   - 當點擊懸浮卡片在官方「行事曆」應用程式中跳轉至特定日期時，系統可能會要求授予 Apple Events 權限。
4. **完全本地化隱私保障**:
   - NudgeLine 絕不包含任何使用者追蹤、行為分析或外部資料回傳程式碼。所有資料僅在您個人的 Mac 本地安全運行。

---

## 核心特性詳解

### 1. 螢幕邊緣時間線
- **自由版面配置**: 支援靠齊在螢幕的左側、右側或底部邊緣。
- **多顯示器支援**: 僅在主顯示器顯示，或在所有連接的螢幕上同步呈現。
- **自訂粗細與懸停展開**: 預設厚度可在 1–10px 之間微調，並可開啟滑鼠懸停時優雅展開加粗效果。
- **已結束行程淡化**: 過去的行程將自動降低不透明度與飽和度（35%），滑鼠懸停時瞬間恢復原色。
- **重疊行程呼吸流轉**: 同一時段內的複數重疊行程，摒棄雜亂的斜紋斑馬線，採用滑順優雅的呼吸交叉淡入淡出（Cross-fade）動畫展示。
- **時間指示器**: 提供三角刻度、圓頂、凸起色塊、圓環 4 種造型與霓虹光暈效果。

### 2. 互動式懸浮泡泡與快捷動作
- **操作卡片**: 滑鼠懸停在時間線色塊上，即可完整檢視行程標題、時間、地點、備忘錄以及一鍵會議加入按鈕。
- **0ms 極速反應**: 剔除冗餘視圖階層包裝，提供毫無卡頓與抖動的即時懸停呈現體驗。
- **高對比度自適應**: 淺色模式與深色模式下均符合 WCAG 標準，確保清晰舒適的文字閱讀體驗。
- **智慧彙整時間線外行程**: 精確提煉整天行程及超出設定工作時間範圍的行程項目（例如：`整天: 產品研討會 · 時間線外 2 項 (21:00)`）。

### 3. 桌面寵物夥伴與物理微動態
- **3 款精美內建寵物**: 三花貓、白色珍島犬、白虎（均包含 16 格手工像素逐格動畫）。
- **6 種靈動躲避動作**:
  - `tailPeek`: 身體隱蔽於邊框後，僅俏皮地搖晃尾巴。
  - `headPeek`: 身體隱藏，僅探出小腦袋和雙眼張望。
  - `pop`: 縮小並如氣泡般「啵」一聲輕巧消失。
  - `vortex`: 伴隨漩渦優雅旋轉漸隱。
  - `squish`: 如果凍般貼著邊框扁平壓縮躲避。
  - `smoke`: 如輕煙般柔和虛化漸隱。
- **自訂逐格寵物**: 支援直接拖入個人的 PNG 動畫格序列，並可在設定面板中即時調節 FPS 與邊緣偏移。
- **寵物小憩 (Snooze)**: 點擊時間指示器或懸浮泡泡，寵物即可靜默隱退；伴有微弱柔和的呼吸光暈與水波倒數進度顯示。

### 4. 時間線整合 Apple「提醒事項」
- **精確定位標記**: 將今日到期或指定具體時間的提醒事項精準錨定在時間軸上。
- **兩類標記樣式**:
  - **SF Symbols 符號**: 旗標、菱形、愛心、星形（保持列表專屬主題色）。
  - **專屬美食點心**: 配套寵物的精緻小點心（小貓的小魚、小狗的骨頭、白虎的肉塊）。
- **快捷清單互動**: 無需喚起「提醒事項」主程式，直接在懸浮卡片中勾選完成待辦。

---

## 外部生態無縫聯動

深度對接您日常工作中最常用的高頻工具：

### 1. 視訊會議加入 11 種 (1-Click Launch)
在行程卡片中一鍵瞬間加入會議：
- **全球與企業級**: Google Meet、Zoom、Microsoft Teams、Apple FaceTime、Cisco Webex、Amazon Chime。
- **協作辦公與社群**: Discord、Lark (飛書海外版)、Whereby、Jitsi Meet。
- **區域服務**: NAVER Whale ON。
- **安全連結自動解包**: 智慧解析剝離 Microsoft Defender SafeLinks 與 Google Redirects 重新導向包裝，直達真實目標網址，支援 Teams (`msteams://`) 和 FaceTime (`facetime://`) 協定直接啟動。

### 2. 生產力工具與深度連結 10 種 + Web
自動辨識行事曆和提醒事項備忘錄中的工作連結並賦予專屬高亮徽章：
- **知識庫與協作**: Notion (`notion://`)、Slack (`slack://`)、Things 3 (`things://`)、Obsidian (`obsidian://`)、Bear (`bear://`)、Linear (`linear://`)、Figma (`figma://`)。
- **Apple 系統內建應用程式**: Apple 郵件 (`message://`)、備忘錄 (`notes://`)、提醒事項 (`x-apple-reminderkit://`)。
- **標準 Web 連結**: 自動擷取並展示整潔的網域名稱主機名稱徽章（如：`github.com`、`docs.google.com`）。
- **三重安全防護**: 嚴格阻斷惡意本地檔案調用與腳本注入協定（`file`、`javascript` 等）。

### 3. 地圖定位與導航 5 種
一鍵在您偏好的地圖服務中查詢行程地點：
- **支援服務**: Apple 地圖、Google 地圖、OpenStreetMap、NAVER 地圖、Kakao 地圖。
- **偏好設定**: 可在 **設定 > 一般 > 偏好地圖服務** 中自由切換。

---

## 快捷鍵與選單列操作

- **選單列常駐控制**: 打開設定、立即重新整理行程、檢查版本更新、檢視關於 NudgeLine。
- **原生資訊面板**: 320pt 精巧卡片視窗，清晰展示版本資訊、版本主要變更記錄及官方支援連結。
- **macOS 捷徑 (AppIntents) 支援**:
  - `重新整理 NudgeLine 行程`: 在背景立即重新同步當天行事曆項目。
  - `切換 NudgeLine 寵物`: 透過捷徑快速顯示或隱藏時間線上的桌面寵物。

---

## 建置與測試指南

### 系統需求
- macOS 15.0+ (Sequoia)
- Apple Silicon (M系列) 或 Intel 架構 Mac

### 從原始碼編譯執行

```bash
# 1. 複製程式碼儲存庫
git clone https://github.com/rareram/NudgeLine.git
cd NudgeLine

# 2. 建置本機開發偵錯版 (產生獨立的 NudgeLine (Dev).app)
./scripts/build_app.sh
open "build/NudgeLine (Dev).app"

# 或建置正式發布版本
./scripts/build_app.sh --release
open "build/NudgeLine.app"
```

### 執行自動化單元測試

直接執行涵蓋本地化字典、提醒解析器、行程切片演算法及安全過濾器的完整單元測試套件（8 大測試套件，共 54 項測試）：

```bash
./scripts/run_tests.sh
```

---

## 專案架構一覽

```
NudgeLine/
├── Sources/NudgeLine/
│   ├── Models/         # CalendarEvent, ReminderItem, AppSettings
│   ├── Services/       # CalendarService, ReminderService, Localization, UpdateService
│   └── Views/          # OverlayPanel, PopoverPanel, TimelineBarView, Settings/
├── Tests/NudgeLineTests/ # Swift Testing 單元測試套件
└── scripts/            # 打包腳本、DMG 產生工具、測試執行器、Git 掛鉤
```

---

## 多語言支援 (Localization)

NudgeLine 嚴格遵循 Apple macOS HIG 官方標準術語，原生支援以下 10 種語言環境：
- **系統預設** (自動跟隨 macOS 系統偏好語言)
- **繁體中文**
- **English** (英文)
- **한국어** (韓文)
- **日本語** (日文)
- **简体中文** (簡體中文)
- **俄文** (Русский)
- **荷蘭文** (Nederlands)
- **法文** (Français)
- **德文** (Deutsch)
- **西班牙文** (Español)
此外，亦隱藏著一種神秘的隱藏語言，等待在特定時刻或透過探索被喚醒。

您可以隨時在 **設定 > 一般 > 語言** 中自由切換介面顯示語言。

---

## 鳴謝與授權合約

- 本專案深受 Andreas Katzian 與 ARTMIXTURE 創作的經典工具 PixelScheduler (2014-2015) 設計理念啟發，並以現代 macOS 技術進行了全新詮釋。
- 授權合約: [MIT License](LICENSE)
- 版權所有: (c) 2026 rareram. All rights reserved.

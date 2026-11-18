# NudgeLine

<p align="center">
  <img src="docs/images/app_icon.png?v=2" width="128" height="128" alt="NudgeLine Icon" />
</p>

<p align="center">
  <strong>画面の端にそっと寄り添う、今日のタイムライン</strong><br>
  <em>macOS 15+ (Sequoia) / Swift 6, SwiftUI</em>
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README_KR.md">한국어</a> | <strong>日本語</strong> | <a href="README_CN.md">简体中文</a> | <a href="README_TW.md">繁體中文</a> | <a href="README_RU.md">Русский</a> | <a href="README_NL.md">Nederlands</a> | <a href="README_FR.md">Français</a> | <a href="README_DE.md">Deutsch</a> | <a href="README_ES.md">Español</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2015.0%2B%20(Sequoia)-blue.svg" alt="Platform" />
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift Version" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%2F%20Intel-success.svg" alt="Architecture" />
  <img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="License" />
</p>

---

## なぜ NudgeLine なのか？

かつて 32-bit macOS の時代、開発者自身が愛用していた [PixelScheduler](https://pixelscheduler.art-mixture.com/) という名作アプリがありました。しかし、macOS が 64-bit へと移行する中で開発が途絶えてしまいました。NudgeLine は、その愛着と惜しむ気持ちから、現代の macOS 環境に合わせてゼロから創り上げたネイティブ後継ユーティリティです。

画面の端に佇むミニマルなスケジュールバーという原作のコンセプトを受け継ぎつつ、マウスが近づくと画面のベゼル（縁）の後ろへ隠れる愛らしいマスコットペット、多彩な開始演出、そして現代のビデオ会議や Apple リマインダーとのシームレスな連携を加え、より実用的で心温まる体験へと進化させました：

- **作業を邪魔しない環境型タイムライン (Zero Interference)**: ディスプレイのベゼルに沿って 1〜10px の極細バーとして常駐。カレンダーウィンドウを開くことなく、今日の時間の流れを自然に把握できます。バーの外側で行われるマウスクリックやスクロールは 100% 背後のアプリ（ブラウザやコードエディタなど）へそのまま透過され、日々の作業フローを一切妨げません。
- **ワンクリック生産性連携 (1-Click Productivity Bridge)**: Google Meet、Zoom、Microsoft Teams、FaceTime など 11 種類のビデオ会議にワンクリックで即座に参加可能。企業メールのセキュリティリンク（Microsoft Defender SafeLinks、Google Redirects）は純粋なリンク先へ自動復元されます。さらに、メモ内の Notion、Slack、Things、Obsidian など 10 大生産性ツールのディープリンクも専用バッジで直結します。
- **穏やかな感覚フィードバック (Calm Sensory Feedback)**: 予定開始 5〜20 分前に穏やかなバーのパルスアニメーションで次の予定を自然にリマインド。マウスカーソルが近づくとベゼルの裏へひょっこり隠れるマスコットペット（三毛猫、珍島犬、白虎）がデスクトップに寄り添います。集中したいときはクリックひとつで一時停止（スヌーズ）も可能です。
- **100% ネイティブ＆プライバシー最優先 (Zero Overhead & Absolute Privacy)**: 外部サードパーティ製ライブラリを一切使わず、Apple 純正フレームワーク（SwiftUI / AppKit / EventKit）のみで構築。アイドル時のメモリ消費は 25MB 未満の超低消費電力を誇ります。外部サーバーへの通信は 0% であり、すべてのカレンダーやリマインダーのデータは Mac 内のローカルメモリでのみ安全に処理されます。

<div align="center">
  <video src="https://github.com/user-attachments/assets/63386ef2-a62a-44bb-a629-badb966f11a5" width="85%" controls></video>
</div>

<p align="center">
  <img src="docs/images/pet_hide_tail_peek.gif" width="130" height="167" title="隠れる (尻尾フリフリ)" alt="隠れる (尻尾フリフリ)" style="margin: 0 18px;" />&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/images/pet_hide_head_peek.gif" width="130" height="167" title="隠れる (頭ひょっこり)" alt="隠れる (頭ひょっこり)" style="margin: 0 18px;" />&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/images/pet_hide_pop.gif" width="130" height="167" title="消滅 (ポップ!)" alt="消滅 (ポップ!)" style="margin: 0 18px;" /><br>
  <em>マウスカーソルが近づくとベゼルの後ろへ退避したり消滅するマスコットが作業に寄り添います (6種類の隠れモーションに対応)。</em>
</p>

---

## インストールと初期設定

### 1. Homebrew によるインストール (推奨)

ターミナルから以下のコマンド 1 行で手軽にインストールできます：

```bash
brew install rareram/tap/nudgeline
```

最新バージョンへアップデートする場合：
```bash
brew upgrade rareram/tap/nudgeline
```

---

### 2. DMG ファイルの直接ダウンロード

1. [GitHub Releases](https://github.com/rareram/NudgeLine/releases) から `NudgeLine.dmg` をダウンロードし、`NudgeLine.app` を `/Applications` フォルダへドラッグ＆ドロップします。
2. 以後リリースされるアップデートは、メニューバーアイコンの **[アップデートを確認…]** からワンクリックで簡単に更新できます。

---

### 3. 初回起動時のセキュリティと権限設定について

NudgeLine はオープンソースのユーティリティであるため、初回起動時に macOS 標準のアクセス権限設定が必要です：

1. **Gatekeeper セキュリティの確認 (初回のみ)**:
   - 開発元未確認の警告が表示された場合、`/Applications` 内の `NudgeLine.app` を **右クリック (または Control + クリック) > [開く]** を選択するか、ターミナルで以下を実行してください：
     ```bash
     xattr -cr /Applications/NudgeLine.app
     ```
2. **カレンダーおよびリマインダーへのアクセス権限 (TCC)**:
   - 起動時に予定とリマインダーを表示するためのアクセス許可ダイアログが表示されます。
   - **システム設定 > プライバシーとセキュリティ > カレンダー / リマインダー** からいつでも設定を確認・変更できます。
3. **Apple Events 権限について**:
   - ポップオーバーから公式の「カレンダー」アプリを特定の日付で開く際、システムが Apple Events の許可を求める場合があります。
4. **完全ローカル動作とプライバシー保証**:
   - NudgeLine には、ユーザーの個人情報や予定データを収集・追跡・外部送信するコードは一切含まれていません。すべての情報は Mac 内部でのみ安全に処理されます。

---

## 主な機能

### 1. 画面端のタイムラインバー
- **自由な配置**: 画面の左端、右端、下端から好みの位置を選択可能。
- **マルチディスプレイ対応**: メインディスプレイ限定または接続された全画面での同時表示。
- **太さとホバー拡大**: 基本の太さ（1〜10px）を細かく調節でき、ホバー時に自然にバーを太くする演出も設定可能。
- **過去の予定を薄く表示**: 終了した予定は不透明度と彩度を下げて（35%）表示し、残りの予定に集中できます（ホバーで即座に元の色に復元）。
- **重複予定のブリーディング演出**: 同じ時間帯に重なる複数の予定は、斜線ストライプではなく滑らかなクロスフェードアニメーションで美しく表示。
- **時間インジケータ**: 三角ティック、ラウンドドーム、突出ブロック、ポイントリングの 4 形状とネオングロー効果に対応。

### 2. インタラクティブなポップオーバー
- **アクションカード**: セグメントにマウスを合わせると、タイトル、時間、場所、メモ、1クリック会議参加ボタンをすっきりと表示。
- **0ms 即時レスポンス**: 不要な中間ビューラッピングを排除し、カクつきのない滑らかなホバー表示を実現。
- **高コントラスト対応**: ライトモード・ダークモードの双方で WCAG 基準を満たす鮮明な視認性を確保。
- **タイムライン外のスマート集計**: 終日予定や表示時間外の予定を分かりやすく要約（例: `終日: カンファレンス · タイムライン外2件 (21:00)`）。

### 3. デスクトップペットと物理インタラクション
- **3種類のプリセットペット**: 三毛猫、白の珍島犬、白虎（それぞれ 16 フレームのピクセルアートアニメーション）。
- **6種類のベゼル回避モーション**:
  - `tailPeek`: 体はベゼルの裏へ隠れ、尻尾だけフリフリ。
  - `headPeek`: 体は隠れ、頭と目だけひょっこり覗き見。
  - `pop`: ポップに縮んでポンと消滅。
  - `vortex`: 渦巻きに巻き込まれるように回転消滅。
  - `squish`: ベゼルにペタッと押しつぶされて回避。
  - `smoke`: ふんわりと煙のようにぼやけて消滅。
- **カスタムペット作成**: 手持ちの PNG 連番画像をドラッグ＆ドロップして登録可能。FPS や表示位置オフセットもリアルタイムに調整できます。
- **ペットの一時停止 (スヌ즈)**: 時間インジケータやツールチップをクリックするとペットが静かに隠れ、穏やかなブリーディング発光と液体の波アニメーションで残り時間をカウントダウンします。

### 4. タイムライン上の Apple リマインダー
- **ピンポイントマーカー**: 本日期限または時間指定のリマインダーをタイムライン上に正確にマーカー表示。
- **2 つのマーカースタイル**:
  - **SF Symbols**: フラグ、ダイヤ、ハート、スター（リスト固有の色を保持）。
  - **ペットのおやつ**: キャラクターに合わせたおやつアイコン（猫は魚、犬は骨、虎は肉）。
- **チェックリスト操作**: リマインダーアプリを開くことなく、ポップオーバー上で直接完了チェックが可能。

---

## 対応している外部連携

日常の業務フローで使用するツール群とシームレスに連携します：

### 1. ビデオ会議プラットフォーム 11種 (1-Click Launch)
予定カードからワンクリックで直接ミーティングに参加できます：
- **グローバル＆エンタープライズ**: Google Meet、Zoom、Microsoft Teams、Apple FaceTime、Cisco Webex、Amazon Chime。
- **コラボレーション＆コミュニティ**: Discord、Lark、Whereby、Jitsi Meet。
- **地域サービス**: NAVER Whale ON。
- **セキュリティリンク自動復元**: Microsoft Defender SafeLinks や Google Redirects などの保護リンクを解析して本来の接続先へ自動復元し、Teams (`msteams://`) や FaceTime (`facetime://`) のネイティブ起動もサポート。

### 2. 生産性ツール＆ディープリンク 10種 ＋ Web
リマインダーやカレンダーのメモ内に含まれるリンクを自動検知し、専用バッジを表示します：
- **生産性＆ノート**: Notion (`notion://`)、Slack (`slack://`)、Things 3 (`things://`)、Obsidian (`obsidian://`)、Bear (`bear://`)、Linear (`linear://`)、Figma (`figma://`)。
- **Apple 純正アプリ**: Apple メール (`message://`)、Apple メモ (`notes://`)、Apple リマインダー (`x-apple-reminderkit://`)。
- **Web リンク**: ドメインホスト名（例: `github.com`、`docs.google.com`）をすっきりとしたバッジで表示。
- **安全な 3 段階検証**: 悪意あるローカルファイル実行やスクリプト注入（`file`、`javascript` など）を未然に遮断。

### 3. マップ＆道案内 5種
登録された予定の場所をお好みの地図サービスで即座に開きます：
- **対応サービス**: Apple マップ、Google マップ、OpenStreetMap、NAVER マップ、Kakao マップ。
- **設定方法**: **設定 > 一般 > 優先マップサービス** から自由に変更できます。

---

## ショートカットとメニューバー操作

- **メニューバー常駐操作**: 設定を開く、予定を即時更新、アップデートを確認、NudgeLine についての表示。
- **ネイティブ情報パネル**: バージョン情報、ビルドごとの主な変更点、GitHub やサポートリンクを 320pt のコンパクトな専用カードウィンドウで常時提供。
- **macOS ショートカット (AppIntents) 対応**:
  - `NudgeLine を更新`: バックグラウンドで今日の予定を再同期。
  - `NudgeLine ペット切り替え`: タイムライン上のペット表示・非表示をショートカットで切り替え。

---

## ビルドおよびテスト

### システム要件
- macOS 15.0+ (Sequoia)
- Apple Silicon または Intel Mac

### ソースコードからのビルド

```bash
# 1. リポジトリをクローン
git clone https://github.com/rareram/NudgeLine.git
cd NudgeLine

# 2. ローカル開発用ビルド (独立した NudgeLine (Dev).app を生成)
./scripts/build_app.sh
open "build/NudgeLine (Dev).app"

# または本番配布用ビルド
./scripts/build_app.sh --release
open "build/NudgeLine.app"
```

### ユニットテストの実行

言語辞書、リマインダーパーサー、予定スライス分割アルゴリズム、セキュリティフィルターを網羅する自動ユニットテスト（8 スイート 54 テスト）を実行できます：

```bash
./scripts/run_tests.sh
```

---

## プロジェクト構成

```
NudgeLine/
├── Sources/NudgeLine/
│   ├── Models/         # CalendarEvent, ReminderItem, AppSettings
│   ├── Services/       # CalendarService, ReminderService, Localization, UpdateService
│   └── Views/          # OverlayPanel, PopoverPanel, TimelineBarView, Settings/
├── Tests/NudgeLineTests/ # Swift Testing ユニットテストスイート
└── scripts/            # パッケージング、DMG ビルダー、テストランナー、Git フック
```

---

## 多言語対応 (Localization)

NudgeLine は Apple macOS HIG 公式標準用語に準拠し、以下の 10 言語をサポートしています：
- **システムデフォルト** (macOS のシステム言語に自動追従)
- **日本語**
- **英語** (English)
- **韓国語** (한국어)
- **簡体字中国語** (简体中文)
- **繁体字中国語** (繁體中文)
- **ロシア語** (Русский)
- **オランダ語** (Nederlands)
- **フランス語** (Français)
- **ドイツ語** (Deutsch)
- **スペイン語** (Español)
さらに、特別な記念日や隠されたインタラクションによって目覚める秘密の言語（イースターエッグ）がどこかに眠っています。

言語は **設定 > 一般 > 言語** からいつでも切り替えることができます。

---

## クレジットとライセンス

- 本プロジェクトは Andreas Katzian 氏および ARTMIXTURE による PixelScheduler (2014-2015) のコンセプトに着想を得て、現代の macOS 技術で再構築されたものです。
- ライセンス: [MIT License](LICENSE)
- 著作権: (c) 2026 rareram. All rights reserved.

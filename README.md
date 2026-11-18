# NudgeLine

<p align="center">
  <img src="docs/images/app_icon.png?v=2" width="128" height="128" alt="NudgeLine Icon" />
</p>

<p align="center">
  <strong>Today's schedule, quietly resting at your screen edge.</strong><br>
  <em>macOS 15+ (Sequoia) / Swift 6, SwiftUI</em>
</p>

<p align="center">
  <strong>English</strong> | <a href="README_KR.md">한국어</a> | <a href="README_JP.md">日本語</a> | <a href="README_CN.md">简体中文</a> | <a href="README_TW.md">繁體中文</a> | <a href="README_RU.md">Русский</a> | <a href="README_NL.md">Nederlands</a> | <a href="README_FR.md">Français</a> | <a href="README_DE.md">Deutsch</a> | <a href="README_ES.md">Español</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2015.0%2B%20(Sequoia)-blue.svg" alt="Platform" />
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift Version" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%2F%20Intel-success.svg" alt="Architecture" />
  <img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="License" />
</p>

---

## Why NudgeLine?

Back in the 32-bit macOS era, the developer personally loved and relied on a classic utility called [PixelScheduler](https://pixelscheduler.art-mixture.com/). After macOS transitioned to 64-bit, its development unfortunately ceased. NudgeLine was born out of that longing—crafted as a modern, native successor for today's macOS.

It inherits the original's minimal screen-edge timeline concept, but reimagines it with playful animated mascots that dodge your cursor, rich event start effects, and seamless integrations for modern video conferences and Apple Reminders:

- **Ambient & Zero Interference**: A slim 1–10px bar along your screen bezel keeps you aware of your day without opening a calendar window. Mouse clicks and scrolls pass right through outside the bar, so your active workspace (browsers, IDEs, editors) remains 100% uninterrupted.
- **1-Click Productivity Bridge**: Instantly join meetings across 11 platforms (Google Meet, Zoom, Teams, FaceTime, etc.), automatically unwrap corporate security links (SafeLinks), and jump directly to task URLs (Notion, Slack, Things, Obsidian) with clean native badges.
- **Calm Sensory Feedback**: Get a gentle bar pulse 5–20 minutes before a meeting starts. Enjoy subtle micro-mascots (Calico Cat, Jindo Dog, White Tiger) that playfully hide behind your screen bezel whenever your cursor approaches.
- **100% Native & Private**: Zero external dependencies, pure SwiftUI/AppKit/EventKit architecture, under 25MB memory footprint, and absolutely zero external network telemetry. All your data stays strictly on your Mac.

<div align="center">
  <video src="https://github.com/user-attachments/assets/a3380d76-9313-4f39-83aa-e25fc015ea8e" width="85%" controls></video>
</div>

<p align="center">
  <img src="docs/images/pet_hide_tail_peek.gif" width="130" height="167" title="Hide - Tail Wag" alt="Hide - Tail Wag" style="margin: 0 18px;" />&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/images/pet_hide_head_peek.gif" width="130" height="167" title="Hide - Head Peek" alt="Hide - Head Peek" style="margin: 0 18px;" />&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/images/pet_hide_pop.gif" width="130" height="167" title="Disappear - Pop" alt="Disappear - Pop" style="margin: 0 18px;" /><br>
  <em>Animated mascots quietly accompany your day and hide behind the bezel upon cursor proximity (6 motions supported).</em>
</p>

---

## Installation & Setup

### 1. via Homebrew (Recommended)

```bash
brew install rareram/tap/nudgeline
```

To update to the latest version:
```bash
brew upgrade rareram/tap/nudgeline
```

---

### 2. Direct Download (.dmg)

1. Download `NudgeLine.dmg` from [GitHub Releases](https://github.com/rareram/NudgeLine/releases) and drag `NudgeLine.app` to your `/Applications` folder.
2. Subsequent updates can be installed with a single click via the menu bar icon (**Check for Updates**).

---

### 3. Important Permissions & Security Notice

Because NudgeLine is an open-source project and not yet distributed through the Mac App Store, macOS requires standard system permissions on first launch:

1. **Gatekeeper Security Confirmation (First launch only)**:
   - macOS may display an unidentified developer warning.
   - Right-click (or Control + Click) `NudgeLine.app` in `/Applications` > select **Open**, or run:
     ```bash
     xattr -cr /Applications/NudgeLine.app
     ```
2. **Calendar & Reminders Access (TCC)**:
   - When prompted, grant access to **Calendars** and **Reminders** so NudgeLine can display your schedule.
   - You can review these permissions anytime in **System Settings > Privacy & Security > Calendars / Reminders**.
3. **Apple Events Permission**:
   - When clicking an event to open Apple Calendar at that specific date, macOS may ask for Apple Events permission.
4. **Zero-Telemetry Guarantee**:
   - NudgeLine contains **zero analytics, tracking, or network telemetry**. Your calendar events and reminders are processed entirely in memory on your Mac.

---

## Core Features

### 1. Screen-Edge Timeline Bar
- **Flexible Placement**: Anchor the bar along the Left, Right, or Bottom screen edge.
- **Multi-Display**: Show on your primary display or mirror across all connected screens.
- **Customizable Thickness**: Default thickness from 1px to 10px, with optional expansion on hover.
- **Past Event Dimming**: Completed events dim to 35% opacity and saturation, cleanly restoring to full color on mouse hover.
- **Overlapping Schedules**: Alternating breathing cross-fade transitions for concurrent events.
- **Time Indicators**: Triangle Tick, Round Dome, Protruding Block, or Point Ring shapes with optional neon glow.

### 2. Interactive Popovers & Instant Actions
- **Action Cards**: Hover over any event segment to view title, time, location, notes, and 1-click meeting join buttons.
- **Fast Response**: Zero unnecessary view wrapping ensures instant, stutter-free hover rendering.
- **Theme-Adaptive High Contrast**: Automatically adjusts contrast for buttons and text in Light and Dark modes.
- **Smart Outside-Timeline Counter**: Neatly summarizes all-day events and schedules falling outside your configured display window (e.g., `3 outside timeline (21:00)`).

### 3. Animated Mascots & Physical Interactions
- **3 Built-in Mascots**: Calico Cat, White Jindo Dog, and White Tiger (16-frame handcrafted pixel animations).
- **6 Smooth Hide Motions**:
  - `tailPeek`: Hides body behind the bezel with tail wagging.
  - `headPeek`: Hides body with head peeking out.
  - `pop`: Shrinks and disappears with a pop effect.
  - `vortex`: Rotates into a vortex.
  - `squish`: Squishes flat against the bezel.
  - `smoke`: Blurs away softly into smoke.
- **Custom Pets**: Import your own PNG frame sequences with FPS controls and live hide-offset tuning.
- **Pet Snooze**: Click the current time indicator or tooltip to temporarily hide the mascot. Displays a subtle breathing glow and a live liquid wave countdown.

### 4. Apple Reminders on Timeline
- **Pinpoint Markers**: Displays today's due-time reminders directly on the timeline bar.
- **Two Marker Styles**:
  - **SF Symbols**: Flag, Diamond, Heart, or Star icons matching your reminder list color.
  - **Pet Treats**: Food items tailored to your mascot (Fish for Cat, Bone for Dog, Meat for Tiger).
- **Interactive Checklist**: Check off completed reminders directly from the popover without opening the Reminders app.

---

## Supported Integrations

NudgeLine connects directly to the tools you already use every day:

### 1. Video Meeting Platforms (11 Platforms)
1-click launch from the event popover:
- **Global & Enterprise**: Google Meet, Zoom, Microsoft Teams, Apple FaceTime, Cisco Webex, Amazon Chime.
- **Collaboration & Communities**: Discord, Lark, Whereby, Jitsi Meet.
- **Regional**: Naver Whale ON.
- **SafeLinks & Deep Launch**: Automatically strips Microsoft Defender SafeLinks and Google Redirect wrappers to open clean destinations, with direct scheme launch for Teams (`msteams://`) and FaceTime (`facetime://`).

### 2. Productivity Apps & Smart Deep Links (10 Apps + Web)
Dedicated badges for task and project URLs in reminders and notes:
- **Productivity & Notes**: Notion (`notion://`), Slack (`slack://`), Things 3 (`things://`), Obsidian (`obsidian://`), Bear (`bear://`), Linear (`linear://`), Figma (`figma://`).
- **Apple System Apps**: Apple Mail (`message://`), Apple Notes (`notes://`), Apple Reminders (`x-apple-reminderkit://`).
- **Web Destinations**: Clean domain hostname badges for standard URLs (e.g., `github.com`, `docs.google.com`).
- **3-Tier Security Filter**: Blocks unsafe local file execution and script injection schemes (`file`, `javascript`, etc.).

### 3. Maps & Directions (5 Services)
Open event locations in your favorite map service:
- **Supported Maps**: Apple Maps, Google Maps, OpenStreetMap, Naver Map, Kakao Map.
- **Configurable**: Choose your default provider in **Settings > General > Preferred Map Service**.

---

## Shortcuts & Menu Bar Controls

- **Menu Bar Controls**: Quick access to Settings, Instant Refresh, Check for Updates, and About NudgeLine.
- **Native About Window**: A compact 320pt window displaying version identity, release highlights, and direct repository links.
- **macOS Shortcuts (AppIntents)**:
  - `Refresh Schedule`: Re-query EventKit and update timeline events.
  - `Toggle Mascot`: Toggle mascot visibility on the timeline bar.

---

## Requirements & Building

### Requirements
- macOS 15.0+ (Sequoia)
- Apple Silicon or Intel Mac

### Build from Source

```bash
# 1. Clone repository
git clone https://github.com/rareram/NudgeLine.git
cd NudgeLine

# 2. Build local debug application
./scripts/build_app.sh
open "build/NudgeLine (Dev).app"

# Or build production release bundle
./scripts/build_app.sh --release
open "build/NudgeLine.app"
```

### Running Unit Tests

Run the full automated test suite (54 tests across 8 suites) covering localization, reminder parsing, event segmentation, and security filters:

```bash
./scripts/run_tests.sh
```

---

## Project Architecture

```
NudgeLine/
├── Sources/NudgeLine/
│   ├── Models/         # CalendarEvent, ReminderItem, AppSettings
│   ├── Services/       # CalendarService, ReminderService, Localization, UpdateService
│   └── Views/          # OverlayPanel, PopoverPanel, TimelineBarView, Settings/
├── Tests/NudgeLineTests/ # Swift Testing unit test suite
└── scripts/            # Packaging, DMG builder, test runners, git hooks
```

---

## Localization

NudgeLine natively supports 10 languages adhering strictly to Apple macOS HIG standards:
- **System Default** (matches your macOS language)
- **English**
- **Korean** (한국어)
- **Japanese** (日本語)
- **Simplified Chinese** (简体中文)
- **Traditional Chinese** (繁體中文)
- **Russian** (Русский)
- **Dutch** (Nederlands)
- **French** (Français)
- **German** (Deutsch)
- **Spanish** (Español)

Plus a secret hidden language waiting to be discovered on special occasions or through subtle interactions.

Change your language preference anytime in **Settings > General > Language**.

---

## Credits & License

- Inspired by the concept of PixelScheduler (2014-2015) by Andreas Katzian & ARTMIXTURE.
- License: [MIT License](LICENSE).
- Copyright: (c) 2026 rareram. All rights reserved.

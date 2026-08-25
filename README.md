# NudgeLine

<p align="center">
  <img src="docs/images/app_icon.png" width="128" height="128" alt="NudgeLine Icon" />
</p>

<p align="center">
  <strong>A subtle macOS screen-edge timeline bar for today's calendar events</strong><br>
  <em>Built with Swift 6 and SwiftUI for macOS 14+ (Sonoma / Sequoia)</em>
</p>

<p align="center">
  <strong>English</strong> | <a href="README_KR.md">한국어</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2014.0%2B%20(Sonoma%2FSequoia)-blue.svg" alt="Platform" />
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift Version" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%2F%20Intel-success.svg" alt="Architecture" />
  <img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="License" />
</p>

---

## Overview

NudgeLine shows your daily schedule as a subtle ambient bar along the edge of your screen (Left, Right, or Bottom).

It doesn't disrupt your workflow with aggressive full-screen popups. Instead, it quietly nudges you with today's events at a glance:

- **Mouse Passthrough**: Clicks and scrolls outside the thin bar pass directly to windows behind it (`ignoresMouseEvents` toggle + AppKit `hitTest`).
- **Clean Visuals**: Dark gradient track, 1px event boundaries, and geometric time indicators.
- **Overlapping Events**: Breathing cross-fade between concurrent events.
- **Mascot Companions**: 3 built-in animated pets with 6 hide motions, plus a custom sprite importer.
- **Meeting Links**: Auto-detects Google Meet, Zoom, MS Teams, and Webex links with one-click launch buttons.
- **Native & Low Power**: Built with EventKit, AppKit, and Combine directly with zero third-party dependencies.

---

## Installation via Homebrew

```bash
brew install rareram/tap/nudgeline
```

---

## Features

### 1. Screen-Edge Timeline
- **Position**: Left, Right, or Bottom screen edge.
- **Multi-Monitor**: Show on the primary display or across all connected screens.
- **Thickness**: Adjustable from 1px to 10px, with optional expansion on hover.
- **Overlaps**: Breathing cross-fade between concurrent events.

### 2. Time Indicators
- **Styles**: Triangle Tick, Round Dome, Protruding Block, and Point Ring.
- **Customization**: Custom indicator color, rim highlight, and neon glow toggles.
- **Time Tooltip**: Shows current date/time and remaining hours on hover.
- **Focus Lift**: Automatically highlights the shortest event when hovering over overlapping meetings.

### 3. Mascot Indicators & Custom Pets
- **Built-in Pets**: Calico Cat, White Jindo Dog, and White Tiger (16-frame loop).
- **6 Hide Motions**:
  - `tailPeek`: Rotates -85° behind the bezel; tail stays visible.
  - `headPeek`: Rotates +85° behind the bezel; head peeks out.
  - `pop`: Shrinks and disappears with a pop.
  - `vortex`: Fast 720° spin vortex disappearance.
  - `squish`: Squishes horizontally like jelly.
  - `smoke`: Expands with blur and disappears.
- **Custom Pets**: Import PNG frame sequences, adjust FPS, tune left/right hide offsets with live preview.

### 4. Event Popovers
- **Action Card**: Full summary with meeting join buttons, Apple Calendar shortcut, and a 0.22s hover bridge.
- **Simple Tooltip**: Compact pill bubble that disappears 0.04s after cursor leaves.

### 5. Settings Window (4 Tabs)
- **Timeline**: Position, thickness, hover expand, background style (Auto, Dark, Light, Custom), and track opacity.
- **Indicators**: Card style/theme/opacity, time indicator shape/color, pet selection, hide motion, and custom pet list.
- **Schedule**: 24-hour mode, work hours (start/end), visible calendars with color pickers, and system accounts shortcut.
- **General**: Language (System, Korean, English), launch at login (`SMAppService`), multi-display toggle, and app info.

---

## Requirements & Build

### Requirements
- macOS 14.0 (Sonoma) or macOS 15.0+ (Sequoia)
- Apple Silicon or Intel Mac

### Build from Source

```bash
# 1. Clone repository
git clone https://github.com/rareram/NudgeLine.git
cd NudgeLine

# 2. Build release bundle
./scripts/build_app.sh

# 3. Launch app
open build/NudgeLine.app
```

---

## Project Structure

```
NudgeLine/
├── Package.swift                         # SPM Manifest (macOS 14+)
├── docs/
│   └── images/                           # README screenshots and icon assets
├── Resources/
│   ├── Info.plist                        # LSUIElement and calendar usage descriptions
│   └── AppIcon.icns                      # App icon
├── Sources/
│   └── NudgeLine/
│       ├── AppDelegate.swift             # App lifecycle and screen change observers
│       ├── main.swift                    # Entry point
│       ├── Models/
│       │   ├── AppSettings.swift         # Settings persistence via UserDefaults
│       │   └── CalendarEvent.swift       # Event model, meeting parser, safe indexing
│       ├── Services/
│       │   ├── CalendarService.swift     # EventKit background query service
│       │   ├── CustomPetService.swift    # Thread-safe custom pet file manager
│       │   ├── LaunchAtLoginHelper.swift # SMAppService login item wrapper
│       │   └── Localization.swift        # English/Korean L10n dictionary
│       └── Views/
│           ├── OverlayPanel.swift        # Edge floating NSPanel with mouse passthrough
│           ├── PopoverPanel.swift        # Floating popover panel with .common runloop timer
│           ├── TimelineBarView.swift     # Main timeline rendering & gesture coordinator
│           ├── HangingPetIndicatorView.swift # Mascot renderer & orbit physics
│           ├── HoverRenderers.swift      # Popover renderer protocol
│           ├── EventPopoverView.swift    # Action card popover
│           ├── SimpleInfoPopoverView.swift # Simple tooltip bubble
│           ├── CustomPetEditorSheet.swift# Custom pet drag-and-drop modal
│           ├── SettingsView.swift        # 4-tab preferences window
│           └── Pets/                     # Built-in 16-frame Base64 pet assets
│               ├── PetProtocol.swift
│               ├── CatPetAsset.swift
│               ├── JindoDogPetAsset.swift
│               └── WhiteTigerPetAsset.swift
└── scripts/
    ├── generate_app_icon.sh              # Icon generator script
    ├── build_app.sh                      # Release build & bundle script
    └── check_security.sh                 # Static secret check script
```

---

## Localization

NudgeLine supports:
- English (Default)
- Korean (한국어)

You can change the language in **Settings > General > Language**.

---

## Credits & License

- Inspired by the concept of PixelScheduler (2014-2015) by Andreas Katzian & ARTMIXTURE.
- License: [MIT License](LICENSE).
- Copyright: (c) 2026 rareram. All rights reserved.


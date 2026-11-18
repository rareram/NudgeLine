# NudgeLine

<p align="center">
  <img src="docs/images/app_icon.png?v=2" width="128" height="128" alt="NudgeLine Icon" />
</p>

<p align="center">
  <strong>Het schema van vandaag, subtiel rustend aan uw schermrand.</strong><br>
  <em>macOS 15+ (Sequoia) / Swift 6, SwiftUI</em>
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README_KR.md">한국어</a> | <a href="README_JP.md">日本語</a> | <a href="README_CN.md">简体中文</a> | <a href="README_TW.md">繁體中文</a> | <a href="README_RU.md">Русский</a> | <strong>Nederlands</strong> | <a href="README_FR.md">Français</a> | <a href="README_DE.md">Deutsch</a> | <a href="README_ES.md">Español</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2015.0%2B%20(Sequoia)-blue.svg" alt="Platform" />
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift Version" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%2F%20Intel-success.svg" alt="Architecture" />
  <img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="License" />
</p>

---

## Waarom NudgeLine?

In het 32-bits macOS-tijdperk vertrouwde de ontwikkelaar dagelijks op het klassieke hulpprogramma [PixelScheduler](https://pixelscheduler.art-mixture.com/). Na de overgang van macOS naar 64-bits stopte de ontwikkeling helaas. NudgeLine is ontstaan uit die nostalgie—opnieuw ontworpen als een moderne, native opvolger voor hedendaags macOS.

Het combineert het minimalistische tijdbalkconcept langs de schermrand van het origineel met interactieve geanimeerde mascottes die wegduiken voor uw cursor, verfijnde starteffecten en naadloze integratie met moderne videovergaderingen en Apple Herinneringen:

- **Omgevingsbewust & zonder onderbreking (Zero Interference)**: Een subtiele balk van 1–10 px langs de schermrand houdt u op de hoogte van uw dag zonder dat u een agenda-venster hoeft te openen. Muisklikken en scrollen buiten de balk gaan 100% door naar de actieve werkruimte (browsers, editors), zodat uw workflow intact blijft.
- **Productiviteit in 1 klik (1-Click Productivity Bridge)**: Neem direct deel aan vergaderingen op 11 platforms (Google Meet, Zoom, Teams, FaceTime, etc.), ontkoppel zakelijke beveiligingslinks (SafeLinks, Google Redirects) automatisch en open taak-URL's (Notion, Slack, Things, Obsidian) met native badges.
- **Rustgevende feedback (Calm Sensory Feedback)**: Een zachte pulserende balkanimatie 5–20 minuten voor aanvang herinnert u discreet aan de volgende afspraak. Geanimeerde mascottes (Lapjeskat, Jindo-hond, Witte tijger) verstoppen zich speels achter de rand zodra de cursor nadert.
- **100% native en privacygericht (Zero Overhead & Absolute Privacy)**: Zonder externe bibliotheken gebouwd in pure SwiftUI, AppKit en EventKit met een geheugengebruik van minder dan 25 MB in rust. Volledig offline zonder externe netwerkcommunicatie: alle agendapunten en herinneringen worden uitsluitend in het lokale geheugen van uw Mac verwerkt.

<div align="center">
  <video src="https://github.com/user-attachments/assets/63386ef2-a62a-44bb-a629-badb966f11a5" width="85%" controls></video>
</div>

<p align="center">
  <img src="docs/images/pet_hide_tail_peek.gif" width="130" height="167" title="Verstoppen (Kwispelende staart)" alt="Verstoppen (Kwispelende staart)" style="margin: 0 18px;" />&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/images/pet_hide_head_peek.gif" width="130" height="167" title="Verstoppen (Glurend hoofd)" alt="Verstoppen (Glurend hoofd)" style="margin: 0 18px;" />&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/images/pet_hide_pop.gif" width="130" height="167" title="Verdwijnen (Plop)" alt="Verdwijnen (Plop)" style="margin: 0 18px;" /><br>
  <em>Geanimeerde mascottes vergezellen u tijdens uw werkdag en verstoppen zich achter de schermrand (6 verstopbewegingen ondersteund).</em>
</p>

---

## Installatie en configuratie

### 1. Via Homebrew (Aanbevolen)

```bash
brew install rareram/tap/nudgeline
```

Bijwerken naar de nieuwste versie:
```bash
brew upgrade rareram/tap/nudgeline
```

---

### 2. Handmatig downloaden (.dmg)

1. Download `NudgeLine.dmg` via [GitHub Releases](https://github.com/rareram/NudgeLine/releases) en sleep `NudgeLine.app` naar uw map «Programma's» (`/Applications`).
2. Toekomstige updates kunnen met één klik worden geïnstalleerd via het menubalkicoon (**Zoek naar updates...**).

---

### 3. Beveiligings- en privacyrechten

Omdat NudgeLine een open-sourceproject is en niet via de Mac App Store wordt verspreid, vraagt macOS bij de eerste start om standaardtoestemmingen:

1. **Gatekeeper-beveiliging (Alleen bij eerste start)**:
   - macOS kan een melding tonen over een onbekende ontwikkelaar.
   - Klik met de rechtermuisknop (of Control + klik) op `NudgeLine.app` in `/Applications` > kies **Open**, of voer het volgende commando uit in Terminal:
     ```bash
     xattr -cr /Applications/NudgeLine.app
     ```
2. **Toegang tot Agenda's en Herinneringen (TCC)**:
   - Verleen toegang tot **Agenda's** en **Herinneringen** wanneer hierom wordt gevraagd, zodat NudgeLine uw afspraken kan weergeven.
   - U kunt deze machtigingen op elk moment beheren via **Systeeminstellingen > Privacy en beveiliging > Agenda's / Herinneringen**.
3. **Apple Events-toestemming**:
   - Wanneer u op een afspraak klikt om deze in Apple Agenda te openen, kan macOS om toestemming vragen voor Apple Events.
4. **Volledige privacygarantie**:
   - NudgeLine bevat geen analyse- of trackingsoftware en verstuurt geen netwerktelemetrie. Uw gegevens blijven veilig op uw Mac.

---

## Belangrijkste functies

### 1. Tijdlijnbalk aan de schermrand
- **Flexibele positie**: Plaats de balk aan de linker-, rechter- of onderrand van het scherm.
- **Ondersteuning voor meerdere beeldschermen**: Weergeven op het hoofdscherm of spiegelen over alle aangesloten schermen.
- **Aanpasbare dikte**: Van 1 tot 10 px, met optionele verbreding bij aanwijzen.
- **Gedimde voltooide afspraken**: Afgelopen afspraken worden gedimd naar 35% dekking en herstellen bij aanwijzen.
- **Overlappende afspraken**: Vloeiende ademende overgangen tussen gelijktijdige afspraken.
- **Tijdmarkeringen**: Driehoekige inkeping, ronde koepel, uitstekend blok of puntring met optionele neongloed.

### 2. Interactieve popovers en snelle acties
- **Informatiekaarten**: Wijs een segment aan om titel, tijd, locatie, notities en de deelnameknop te bekijken.
- **Snelle weergave**: Geen onnodige weergavelagen voor een directe, soepele popover-ervaring.
- **Hoog contrast**: Automatische aanpassing van tekst en knoppen voor lichte en donkere modus.
- **Teller buiten het bereik**: Compact overzicht van dagactiviteiten en afspraken buiten het zichtbare venster (bijv. `3 buiten tijdlijn (21:00)`).

### 3. Geanimeerde mascottes en micro-interacties
- **3 ingebouwde mascottes**: Lapjeskat, Jindo-hond en Witte tijger (handgemaakte pixelanimaties met 16 frames).
- **6 verstopbewegingen**:
  - `tailPeek`: Lichaam achter de schermrand, staart kwispelt.
  - `headPeek`: Lichaam verstopt, hoofd gluurt tevoorschijn.
  - `pop`: Krimpt snel en verdwijnt met een plop-effect.
  - `vortex`: Draait weg in een draaikolk.
  - `squish`: Drukt plat tegen de schermrand.
  - `smoke`: Vervaagt zachtjes als rook.
- **Aangepaste mascottes**: Importeer uw eigen PNG-reeksen met aanpasbare beeldsnelheid (FPS) en verstopafstand.
- **Snooze-modus**: Klik op de huidige tijdmarkering om de mascotte tijdelijk te verbergen met een aftellende vloeibare golf.

### 4. Apple Herinneringen op de tijdlijn
- **Tijdgebonden markeringen**: Toont de herinneringen van vandaag met een specifieke eindtijd direct op de balk.
- **Twee markerstijlen**:
  - **SF Symbols-iconen**: Vlag, ruit, hart of ster in de kleur van de herinneringenlijst.
  - **Traktaties**: Vis voor de kat, bot voor de hond, vlees voor de tijger.
- **Interactieve checklist**: Vink voltooide herinneringen direct af vanuit het popover-venster.

---

## Ondersteunde integraties

### 1. Videovergaderingen (11 platforms)
Deelnemen in 1 klik vanuit de popover:
- **Zakelijk en wereldwijd**: Google Meet, Zoom, Microsoft Teams, Apple FaceTime, Cisco Webex, Amazon Chime.
- **Samenwerking en community**: Discord, Lark, Whereby, Jitsi Meet.
- **Regionaal**: Naver Whale ON.
- **Veilige links**: Automatisch ontkoppelen van Microsoft Defender SafeLinks en Google Redirects met directe schema-start voor Teams (`msteams://`) en FaceTime (`facetime://`).

### 2. Productiviteits-apps (10 apps + web)
Herkenbare badges voor taak- en project-URL's in notities en herinneringen:
- **Notities en taakbeheer**: Notion (`notion://`), Slack (`slack://`), Things 3 (`things://`), Obsidian (`obsidian://`), Bear (`bear://`), Linear (`linear://`), Figma (`figma://`).
- **Apple-systeemapps**: Mail (`message://`), Notities (`notes://`), Herinneringen (`x-apple-reminderkit://`).
- **Webbestemmingen**: Duidelijke domeinbadges voor standaard internetlinks.
- **Drietraps beveiligingsfilter**: Blokkeert onveilige schema's (`file`, `javascript`, etc.).

### 3. Kaartendiensten (5 diensten)
Locaties openen in uw voorkeursdienst: Apple Maps, Google Maps, OpenStreetMap, Naver Map, Kakao Map.

---

## Vereisten en bouwen

### Systeemvereisten
- macOS 15.0+ (Sequoia)
- Apple Silicon of Intel Mac

### Bouwen vanuit broncode

```bash
# 1. Repository klonen
git clone https://github.com/rareram/NudgeLine.git
cd NudgeLine

# 2. Lokale ontwikkelingsversie bouwen
./scripts/build_app.sh
open "build/NudgeLine (Dev).app"

# Of officiële productieversie bouwen
./scripts/build_app.sh --release
open "build/NudgeLine.app"
```

### Unittests uitvoeren

Voer de volledige geautomatiseerde testsuite uit (54 tests verdeeld over 8 suites) die lokalisatie, herinneringen, afspraaksegmentatie en beveiligingsfilters valideert:

```bash
./scripts/run_tests.sh
```

---

## Projectarchitectuur

```
NudgeLine/
├── Sources/NudgeLine/
│   ├── Models/         # CalendarEvent, ReminderItem, AppSettings
│   ├── Services/       # CalendarService, ReminderService, Localization, UpdateService
│   └── Views/          # OverlayPanel, PopoverPanel, TimelineBarView, Settings/
├── Tests/NudgeLineTests/ # Swift Testing unittests
└── scripts/            # Verpakkingsscripts, DMG-maker, testrunners en git-hooks
```

---

## Lokalisatie (Localization)

NudgeLine ondersteunt 10 officiële talen conform de Apple macOS HIG-standaarden:
- **Systeemstandaard** (volgt de taal van uw macOS)
- **Nederlands**
- **English** (Engels)
- **한국어** (Koreaans)
- **日本語** (Japans)
- **简体中文** (Vereenvoudigd Chinees)
- **繁體中文** (Traditioneel Chinees)
- **Русский** (Russisch)
- **Français** (Frans)
- **Deutsch** (Duits)
- **Español** (Spaans)
En een geheime verborgen taal die op speciale momenten of via verborgen interacties ontdekt kan worden.

U kunt de weergavetaal op elk moment wijzigen via **Instellingen > Algemeen > Taal**.

---

## Credits en licentie

- Geïnspireerd op het concept van PixelScheduler (2014-2015) door Andreas Katzian & ARTMIXTURE.
- Licentie: [MIT License](LICENSE).
- Auteursrecht: (c) 2026 rareram. Alle rechten voorbehouden.

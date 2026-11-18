# NudgeLine

<p align="center">
  <img src="docs/images/app_icon.png?v=2" width="128" height="128" alt="NudgeLine Icon" />
</p>

<p align="center">
  <strong>L'emploi du temps d'aujourd'hui, discrètement posé au bord de votre écran.</strong><br>
  <em>macOS 15+ (Sequoia) / Swift 6, SwiftUI</em>
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README_KR.md">한국어</a> | <a href="README_JP.md">日本語</a> | <a href="README_CN.md">简体中文</a> | <a href="README_TW.md">繁體中文</a> | <a href="README_RU.md">Русский</a> | <a href="README_NL.md">Nederlands</a> | <strong>Français</strong> | <a href="README_DE.md">Deutsch</a> | <a href="README_ES.md">Español</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2015.0%2B%20(Sequoia)-blue.svg" alt="Plateforme" />
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Version de Swift" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%2F%20Intel-success.svg" alt="Architecture" />
  <img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="Licence" />
</p>

---

## Pourquoi NudgeLine ?

À l'époque de macOS 32 bits, le développeur appréciait et utilisait au quotidien un utilitaire classique nommé [PixelScheduler](https://pixelscheduler.art-mixture.com/). Après la transition de macOS vers le 64 bits, son développement s'est malheureusement arrêté. NudgeLine est né de cette nostalgie : conçu comme un successeur moderne et natif pour le macOS d'aujourd'hui.

Il reprend le concept original d'une ligne de temps discrète au bord de l'écran, enrichi de mascottes animées qui s'esquivent à l'approche du curseur, d'effets visuels de début d'événement et d'intégrations fluides avec les visioconférences modernes et les Rappels Apple :

- **Présence ambiante & Zéro interférence** : Une fine barre de 1 à 10 px le long du bord de l'écran vous permet de suivre votre journée sans ouvrir de fenêtre de calendrier. Les clics de souris et les défilements en dehors de la barre traversent directement l'espace de travail (navigateurs, éditeurs de code), sans jamais interrompre votre flux de travail.
- **Pont de productivité en 1 clic** : Rejoignez instantanément vos réunions sur 11 plateformes (Google Meet, Zoom, Teams, FaceTime, etc.), déballez automatiquement les liens de sécurité d'entreprise (SafeLinks, redirections Google) et ouvrez directement vos liens de tâches (Notion, Slack, Things, Obsidian) grâce à des badges natifs.
- **Rappels sensoriels discrets** : Une douce pulsation de la barre 5 à 20 minutes avant le début d'un événement attire délicatement votre attention. De petites mascottes animées (Chat calico, Chien Jindo blanc, Tigre blanc) se cachent facétieusement derrière le bord de l'écran lorsque votre curseur s'approche.
- **100% natif & Confidentialité totale** : Développé sans dépendance externe en pur SwiftUI, AppKit et EventKit, avec une empreinte mémoire inférieure à 25 Mo en veille. Zéro télémétrie réseau externe : tous vos événements de calendrier et rappels sont traités exclusivement en mémoire locale sur votre Mac.

<div align="center">
  <video src="https://github.com/user-attachments/assets/a3380d76-9313-4f39-83aa-e25fc015ea8e" width="85%" controls></video>
</div>

<p align="center">
  <img src="docs/images/pet_hide_tail_peek.gif" width="130" height="167" title="Se cacher (Queue remuante)" alt="Se cacher (Queue remuante)" style="margin: 0 18px;" />&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/images/pet_hide_head_peek.gif" width="130" height="167" title="Se cacher (Tête curieuse)" alt="Se cacher (Tête curieuse)" style="margin: 0 18px;" />&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/images/pet_hide_pop.gif" width="130" height="167" title="Disparaître (Pop)" alt="Disparaître (Pop)" style="margin: 0 18px;" /><br>
  <em>Les mascottes animées vous accompagnent discrètement et s'effacent derrière le bord de l'écran à l'approche du curseur (6 mouvements pris en charge).</em>
</p>

---

## Installation & Configuration

### 1. Via Homebrew (Recommandé)

```bash
brew install rareram/tap/nudgeline
```

Pour mettre à jour vers la dernière version :
```bash
brew upgrade rareram/tap/nudgeline
```

---

### 2. Téléchargement direct (.dmg)

1. Téléchargez `NudgeLine.dmg` depuis la page des [GitHub Releases](https://github.com/rareram/NudgeLine/releases) et glissez `NudgeLine.app` dans votre dossier `/Applications`.
2. Les mises à jour ultérieures peuvent être installées en un clic depuis l'icône de la barre des menus (**Rechercher les mises à jour…**).

---

### 3. Autorisations et avis de sécurité

NudgeLine étant un projet open-source non distribué sur le Mac App Store, macOS demande les autorisations système standard lors du premier lancement :

1. **Confirmation de sécurité Gatekeeper (Premier lancement uniquement)** :
   - macOS peut afficher un avertissement de développeur non identifié.
   - Faites un clic droit (ou Contrôle + Clic) sur `NudgeLine.app` dans `/Applications` > sélectionnez **Ouvrir**, ou exécutez :
     ```bash
     xattr -cr /Applications/NudgeLine.app
     ```
2. **Accès aux Calendriers et Rappels (TCC)** :
   - Lors de l'invite, accordez l'accès aux **Calendriers** et aux **Rappels** pour permettre à NudgeLine d'afficher votre emploi du temps.
   - Vous pouvez modifier ces autorisations à tout moment dans **Réglages Système > Confidentialité et sécurité > Calendriers / Rappels**.
3. **Autorisation Apple Events** :
   - Lors d'un clic sur un événement pour ouvrir l'application Calendrier d'Apple à cette date spécifique, macOS peut demander une autorisation Apple Events.
4. **Garantie de zéro télémétrie** :
   - NudgeLine ne contient **aucun outil d'analyse, de traçage ou de télémétrie réseau**. Vos données restent strictement confinées sur votre Mac.

---

## Fonctionnalités principales

### 1. Barre de chronologie au bord de l'écran
- **Positionnement flexible** : Ancrez la barre le long du bord gauche, droit ou inférieur de votre écran.
- **Multi-écrans** : Affichez la barre sur votre écran principal ou dupliquez-la sur tous les écrans connectés.
- **Épaisseur personnalisable** : Épaisseur normale de 1 px à 10 px, avec extension optionnelle au survol.
- **Atténuation des événements passés** : Les événements terminés s'atténuent à 35% d'opacité et de saturation, et retrouvent leurs couleurs vives au survol de la souris.
- **Horaires superposés** : Transitions en fondu croisé alterné pour les événements simultanés.
- **Indicateurs horaires** : Styles Triangle, Dôme arrondi, Bloc saillant ou Anneau ponctuel avec lueur néon optionnelle.

### 2. Cartes contextuelles interactives & Actions instantanées
- **Cartes détaillées** : Survolez un segment pour afficher le titre, l'horaire, le lieu, les notes et le bouton d'accès en 1 clic à la réunion.
- **Réponse instantanée** : Rendu sans latence ni scintillement au survol du curseur.
- **Contraste élevé adaptatif** : Ajuste automatiquement le contraste du texte et des boutons selon les modes Clair et Sombre.
- **Compteur hors chronologie** : Résume proprement les événements de la journée entière et ceux situés hors de la plage horaire définie (ex. : `3 hors plage (21:00)`).

### 3. Mascottes animées & Interactions physiques
- **3 mascottes intégrées** : Chat calico, Chien Jindo blanc et Tigre blanc (animations pixelisées artisanales de 16 images).
- **6 mouvements de dissimulation fluides** :
  - `tailPeek` : Corps caché derrière le bord, remuant la queue.
  - `headPeek` : Corps caché, tête curieuse jetant un coup d'œil.
  - `pop` : Rétrécit et s'efface avec un effet pop.
  - `vortex` : Disparaît en tourbillon.
  - `squish` : S'écrase doucement contre le bord de l'écran.
  - `smoke` : Se dissipe progressivement dans une fumée légère.
- **Mascottes personnalisées** : Importez vos propres séquences d'images PNG avec réglage des FPS et décalages en direct.
- **Mise en pause (Snooze)** : Cliquez sur l'indicateur de temps ou le message d'aide pour masquer temporairement la mascotte. Affiche une lueur pulsée et un décompte en onde liquide.

### 4. Rappels Apple intégrés à la chronologie
- **Marqueurs précis** : Affiche les rappels du jour ayant une heure définie directement sur la barre de chronologie.
- **Deux styles de marqueurs** :
  - **Symboles SF** : Icônes Drapeau, Diamant, Cœur ou Étoile reprenant la couleur de votre liste de rappels.
  - **Friandises pour mascottes** : Objets adaptés à chaque mascotte (Poisson pour le chat, Os pour le chien, Viande pour le tigre).
- **Liste interactive** : Cochez les rappels terminés directement depuis la carte contextuelle sans ouvrir l'application Rappels.

---

## Intégrations prises en charge

NudgeLine se connecte directement aux outils que vous utilisez au quotidien :

### 1. Plateformes de visioconférence (11 plateformes)
Lancement en 1 clic depuis la carte contextuelle :
- **Entreprise & Mondial** : Google Meet, Zoom, Microsoft Teams, Apple FaceTime, Cisco Webex, Amazon Chime.
- **Collaboration & Communautés** : Discord, Lark, Whereby, Jitsi Meet.
- **Régional** : Naver Whale ON.
- **Liens sécurisés & Schémas natifs** : Déballe automatiquement les liens Microsoft Defender SafeLinks et les redirections Google pour ouvrir l'URL directe, avec lancement via schémas natifs pour Teams (`msteams://`) et FaceTime (`facetime://`).

### 2. Applications de productivité & Liens profonds (10 applications + Web)
Badges dédiés pour les URL de tâches et projets dans les rappels et notes :
- **Productivité & Notes** : Notion (`notion://`), Slack (`slack://`), Things 3 (`things://`), Obsidian (`obsidian://`), Bear (`bear://`), Linear (`linear://`), Figma (`figma://`).
- **Applications système Apple** : Apple Mail (`message://`), Notes (`notes://`), Rappels (`x-apple-reminderkit://`).
- **Destinations Web** : Badges de domaine épurés pour les URL standards (ex. : `github.com`, `docs.google.com`).
- **Sécurité à 3 niveaux** : Bloque l'exécution de fichiers locaux dangereux et les injections de scripts (`file`, `javascript`, etc.).

### 3. Services de cartographie (5 services)
Ouvrez le lieu d'un événement dans votre service de cartes favori :
- **Services pris en charge** : Apple Plans, Google Maps, OpenStreetMap, Naver Map, Kakao Map.
- **Configurable** : Choisissez votre service par défaut dans **Réglages > Général > Service de cartes préféré**.

---

## Raccourcis & Barre des menus

- **Contrôles de la barre des menus** : Accès rapide aux Réglages, à l'Actualisation instantanée, à la Recherche de mises à jour et À propos de NudgeLine.
- **Fenêtre À propos native** : Une fenêtre épurée de 320 pt présentant la version, les nouveautés marquantes et les liens vers le dépôt officiel.
- **Raccourcis macOS (AppIntents)** :
  - `Refresh Schedule` : Actualiser les événements et interroger EventKit.
  - `Toggle Mascot` : Basculer la visibilité de la mascotte sur la chronologie.

---

## Prérequis & Compilation

### Prérequis
- macOS 15.0+ (Sequoia)
- Mac avec puce Apple Silicon ou processeur Intel

### Compiler depuis les sources

```bash
# 1. Cloner le dépôt
git clone https://github.com/rareram/NudgeLine.git
cd NudgeLine

# 2. Compiler la version de développement
./scripts/build_app.sh
open "build/NudgeLine (Dev).app"

# Ou compiler la version finale de production
./scripts/build_app.sh --release
open "build/NudgeLine.app"
```

### Exécuter les tests unitaires

Exécutez la suite de tests automatisés (54 tests répartis en 8 suites) couvrant la localisation, l'analyse des rappels, la segmentation des événements et les filtres de sécurité :

```bash
./scripts/run_tests.sh
```

---

## Architecture du projet

```
NudgeLine/
├── Sources/NudgeLine/
│   ├── Models/         # CalendarEvent, ReminderItem, AppSettings
│   ├── Services/       # CalendarService, ReminderService, Localization, UpdateService
│   └── Views/          # OverlayPanel, PopoverPanel, TimelineBarView, Settings/
├── Tests/NudgeLineTests/ # Suite de tests unitaires Swift Testing
└── scripts/            # Scripts d'empaquetage, création de DMG, tests et hooks git
```

---

## Localisation

NudgeLine prend en charge nativement 10 langues conformes aux directives Apple HIG :
- **Langue du système** (s'adapte à la langue configurée sur votre macOS)
- **Français**
- **English** (Anglais)
- **한국어** (Coréen)
- **日本語** (Japonais)
- **简体中文** (Chinois simplifié)
- **繁體中文** (Chinois traditionnel)
- **Русский** (Russe)
- **Nederlands** (Néerlandais)
- **Deutsch** (Allemand)
- **Español** (Espagnol)

Ainsi qu'une langue secrète attendant d'être découverte lors d'occasions particulières ou au détour d'interactions subtiles.

Changez votre langue d'affichage à tout moment dans **Réglages > Général > Langue**.

---

## Crédits & Licence

- Inspiré par le concept de PixelScheduler (2014-2015) par Andreas Katzian & ARTMIXTURE.
- Licence : [Licence MIT](LICENSE).
- Droit d'auteur : (c) 2026 rareram. Tous droits réservés.

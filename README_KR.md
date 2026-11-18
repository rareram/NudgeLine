# NudgeLine

<p align="center">
  <img src="docs/images/app_icon.png?v=2" width="128" height="128" alt="NudgeLine Icon" />
</p>

<p align="center">
  <strong>화면 모서리에 머무는 오늘의 타임라인</strong><br>
  <em>macOS 15+ (Sequoia) / Swift 6, SwiftUI</em>
</p>

<p align="center">
  <a href="README.md">English</a> | <strong>한국어</strong> | <a href="README_JP.md">日本語</a> | <a href="README_CN.md">简体中文</a> | <a href="README_TW.md">繁體中文</a> | <a href="README_RU.md">Русский</a> | <a href="README_NL.md">Nederlands</a> | <a href="README_FR.md">Français</a> | <a href="README_DE.md">Deutsch</a> | <a href="README_ES.md">Español</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2015.0%2B%20(Sequoia)-blue.svg" alt="Platform" />
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift Version" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%2F%20Intel-success.svg" alt="Architecture" />
  <img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="License" />
</p>

---

## 왜 NudgeLine인가요?

과거 32-bit macOS 시절 개인적으로 매우 유용하게 쓰던 [PixelScheduler](https://pixelscheduler.art-mixture.com/)라는 앱이 있었습니다. 하지만 macOS가 64-bit로 전환되면서 더 이상 개발이 이어지지 않아 늘 아쉬움이 남았습니다. NudgeLine은 그 아쉬움을 달래고자 현대적인 macOS 환경에 맞추어 직접 만든 대안입니다.

원작의 미니멀한 화면 테두리 스케줄 바 콘셉트를 계승하되, 마우스가 다가오면 화면 뒤로 숨는 귀여운 마스코트 펫과 다채로운 시작 이펙트, 그리고 최신 화상회의 및 Apple 미리알림 연동을 더해 한층 풍성하고 실용적인 경험으로 재탄생시켰습니다:

- **무간섭 앰비언트 타임라인 (Zero Interference)**: 화면 베젤을 따라 1~10px의 얇은 선 형태로 상주하여, 캘린더 창을 열지 않고도 오늘 하루의 시간 흐름을 자연스럽게 인지할 수 있습니다. 바 바깥 영역의 마우스 클릭과 스크롤은 100% 뒤쪽 창(브라우저, 개발 도구 등)으로 통과되어 현재 작업 흐름을 전혀 방해하지 않습니다.
- **원클릭 생산성 연결 (1-Click Productivity Bridge)**: Google Meet, Zoom, Teams, FaceTime 등 11개 화상회의에 한 번의 클릭으로 즉시 입장할 수 있으며, 사내 보안 링크(Microsoft Defender SafeLinks, Google Redirects)는 깨끗한 원본 주소로 자동 복원합니다. 또한 미리알림 메모에 포함된 Notion, Slack, Things, Obsidian 등 10대 생산성 앱 딥링크를 전용 배지로 즉시 연결합니다.
- **은은한 감각 피드백 (Calm Sensory Feedback)**: 회의 시작 5~20분 전 부드러운 바 펄스 애니메이션으로 집중을 깨지 않고 다가오는 일정을 리마인드합니다. 마우스 커서가 다가오면 화면 베젤 뒤로 쏙 숨는 귀여운 마스코트 펫(삼색고양이, 진도백구, 백호)이 함께 머물며, 필요할 땐 언제든 스누즈할 수 있습니다.
- **100% 순정 네이티브 & 프라이버시 (Zero Overhead & Absolute Privacy)**: 외부 서드파티 라이브러리 없이 순수 SwiftUI/AppKit/EventKit으로 구현되어 유휴 상태 메모리 25MB 미만의 극저전력으로 동작합니다. 외부 서버 통신은 0%이며, 모든 일정과 미리알림 데이터는 Mac 로컬 메모리에서만 안전하게 처리됩니다.

<div align="center">
  <video src="https://github.com/user-attachments/assets/63386ef2-a62a-44bb-a629-badb966f11a5" width="85%" controls></video>
</div>

<p align="center">
  <img src="docs/images/pet_hide_tail_peek.gif" width="130" height="167" title="숨기 (꼬리 살랑)" alt="숨기 (꼬리 살랑)" style="margin: 0 18px;" />&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/images/pet_hide_head_peek.gif" width="130" height="167" title="숨기 (머리 빼꼼)" alt="숨기 (머리 빼꼼)" style="margin: 0 18px;" />&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/images/pet_hide_pop.gif" width="130" height="167" title="사라지기 (퐁!)" alt="사라지기 (퐁!)" style="margin: 0 18px;" /><br>
  <em>마우스 커서 접근 시 베젤 뒤로 회피하거나 사라지는 마스코트 펫이 함께합니다 (6종 숨김 모션 지원).</em>
</p>

---

## 설치 및 최초 설정 안내

### 1. Homebrew 설치 (권장)

터미널에서 명령어 한 줄로 간편하게 설치할 수 있습니다:

```bash
brew install rareram/tap/nudgeline
```

최신 버전으로 업데이트할 때:
```bash
brew upgrade rareram/tap/nudgeline
```

---

### 2. DMG 파일 직접 다운로드

1. [GitHub Releases](https://github.com/rareram/NudgeLine/releases)에서 `NudgeLine.dmg`를 다운로드하여 `NudgeLine.app`을 `/Applications` 폴더로 드래그합니다.
2. 이후 배포되는 최신 버전은 메뉴바 아이콘의 **[새 버전 업데이트]** 메뉴를 통해 원클릭으로 간편하게 인앱 업데이트할 수 있습니다.

---

### 3. 유의점: 시스템 권한 및 보안 설정 안내

NudgeLine은 현재 Mac App Store 등록 전 단계의 오픈소스 유틸리티이므로, 최초 실행 시 macOS 표준 보안 권한 설정이 필요합니다:

1. **Gatekeeper 보안 확인 (최초 1회 실행 시)**:
   - 개발자 인증서 미포함 오픈소스 앱이므로 최초 실행 시 확인 메시지가 표시될 수 있습니다.
   - 응용 프로그램 폴더의 `NudgeLine.app`을 **우클릭(Control+클릭) > [열기]**를 선택하거나, 터미널에서 다음 명령어를 실행합니다:
     ```bash
     xattr -cr /Applications/NudgeLine.app
     ```
2. **캘린더 및 미리알림 접근 권한 (TCC)**:
   - 앱 실행 시 일정과 미리알림을 표시하기 위한 접근 권한 확인 창이 나타납니다.
   - 시스템 설정 > 개인정보 보호 및 보안 > **캘린더** 및 **미리알림**에서 언제든 권한 상태를 확인하고 변경할 수 있습니다.
3. **Apple Events 권한 안내**:
   - 팝오버에서 캘린더 바로가기를 클릭하여 Apple 공식 캘린더의 해당 날짜로 이동할 때 시스템이 Apple Events 허용을 요청할 수 있습니다.
4. **무통신 프라이버시 보증**:
   - NudgeLine은 사용자의 개인정보나 일정을 수집·분석·외부 전송하는 코드가 전혀 포함되어 있지 않습니다. 모든 데이터는 오직 사용자의 Mac 내부에서만 안전하게 동작합니다.

---

## 주요 기능 상세

### 1. 화면 테두리 타임라인 바
- **자유로운 위치 배치**: 화면 좌측, 우측, 하단 모서리 중 원하는 위치 선택.
- **다중 디스플레이 지원**: 주 모니터 전용 또는 연결된 전체 모니터 동시 표시.
- **두께 및 호버 확장**: 기본 두께(1~10px)를 조절할 수 있으며, 마우스 호버 시 자연스럽게 두께가 확장되도록 설정 가능.
- **지난 일정 흐리게 표시**: 종료된 일정은 불투명도와 채도를 낮추어(35%) 표시하여 남은 일정에 집중할 수 있게 하며, 마우스를 올리면 원래 색상으로 즉각 복원.
- **중복 일정 교차 페이드**: 동시간대 중복 일정은 사선 줄무늬 대신 부드러운 크로스페이드 애니메이션으로 세련되게 표현.
- **시간 인디케이터**: 삼각 틱, 라운드 돔, 돌출 블록, 포인트 링 4종 모양과 네온 글로우 지원.

### 2. 인터랙티브 팝오버 및 즉각 액션
- **액션 카드 팝오버**: 세그먼트에 마우스를 올리면 일정 제목, 시간, 장소, 메모와 함께 1클릭 회의 참여 버튼을 즉시 표시.
- **0ms 즉각 반응성**: 불필요한 중간 뷰 래핑을 배제하여 렉이나 지터 없는 쾌적한 호버 반응성 제공.
- **라이트/다크 적응형 고대비**: 라이트 모드와 다크 모드 각각에서 WCAG 규격을 준수하는 선명한 가독성 보장.
- **타임라인 외 일정 스마트 요약**: 종일 일정 및 현재 표시 시간 범위 바깥의 일정을 명확하게 요약 (예: `종일: 워크샵 · 타임라인 외 2건 (21:00)`).

### 3. 마스코트 펫과 물리 인터랙션
- **기본 내장 펫 3종**: 삼색고양이, 진도백구, 백호 (각 16프레임 핸드크래프트 픽셀 아트 애니메이션).
- **6가지 베젤 회피 모션**:
  - `tailPeek`: 상체는 베젤 뒤로 숨고 꼬리만 살랑살랑 흔들림.
  - `headPeek`: 몸통은 숨고 머리와 눈만 쏙 빼꼼 노출.
  - `pop`: 작아지며 톡 터지듯 사라짐.
  - `vortex`: 소용돌이 속으로 회전하며 소멸.
  - `squish`: 젤리처럼 납작하게 찌그러지며 회피.
  - `smoke`: 부드럽게 연기처럼 블러되며 소멸.
- **커스텀 펫 등록**: 나만의 PNG 시퀀스 이미지를 드래그하여 등록하고 FPS 및 오프셋을 실시간 프리뷰로 튜닝 가능.
- **펫 일시 숨김 (스누즈)**: 시간 인디케이터나 툴팁을 클릭하면 펫이 부드럽게 숨겨지며, 은은한 브리딩 효과와 액체 파동 카운트다운 게이지 표시.

### 4. 타임라인 위 Apple 미리알림 (Reminders)
- **핀포인트 마커**: 오늘 마감/지정 시간 미리알림을 타임라인 바 위에 정밀하게 표시.
- **투 트랙 마커 스타일**:
  - **SF 심볼**: 깃발, 다이아몬드, 하트, 별 모양 (미리알림 목록 고유 색상 유지).
  - **펫 먹이 아이템**: 펫 캐릭터에 어울리는 간식 아이템 (고양이 생선, 강아지 뼈다귀, 호랑이 고기).
- **인터랙티브 체크리스트**: 미리알림 앱을 직접 띄우지 않고도 팝오버에서 할 일을 즉시 완료 처리.

---

## 지원 연동 목록 (Supported Integrations)

NudgeLine은 매일 사용하는 업무 도구들과 긴밀하게 연동됩니다:

### 1. 화상회의 플랫폼 11종 (1-Click Launch)
일정 상세 카드에서 한 번의 클릭으로 즉시 회의실에 입장합니다:
- **글로벌 & 엔터프라이즈**: Google Meet, Zoom, Microsoft Teams, Apple FaceTime, Cisco Webex, Amazon Chime.
- **협업 툴 & 커뮤니티**: Discord, Lark, Whereby, Jitsi Meet.
- **국내 서비스**: 네이버 웨일온 (Whale ON).
- **보안 링크 자동 복원 & 네이티브 실행**: 사내 메일 보안 솔루션이 래핑한 URL(Microsoft Defender SafeLinks, Google Redirects)을 분석하여 순수 목적지 URL을 자동 복원하며, Teams(`msteams://`) 및 FaceTime(`facetime://`)의 네이티브 앱 스킴 직결 지원.

### 2. 생산성 앱 및 스마트 딥링크 10종 + 웹
미리알림과 캘린더 메모에 적힌 업무 링크를 자동으로 감지하여 전용 배지로 연결합니다:
- **생산성 & 노트 도구**: Notion (`notion://`), Slack (`slack://`), Things 3 (`things://`), Obsidian (`obsidian://`), Bear (`bear://`), Linear (`linear://`), Figma (`figma://`).
- **Apple 순정 앱**: Apple Mail (`message://`), Apple Notes (`notes://`), Apple Reminders (`x-apple-reminderkit://`).
- **일반 웹 링크**: 깔끔한 도메인 호스트명 배지 표시 (예: `github.com`, `docs.google.com`).
- **3단계 안전 파서**: 악성 로컬 파일 실행이나 스크립트 주입 스킴(`file`, `javascript` 등)을 철저히 차단.

### 3. 지도 및 길찾기 서비스 5종
일정에 입력된 장소를 선호하는 지도 서비스로 원클릭 조회합니다:
- **지원 지도**: Apple 지도, Google 지도, OpenStreetMap, 네이버 지도, 카카오맵.
- **설정 방법**: **설정 > 일반 > 선호하는 지도 서비스**에서 기본 서비스를 자유롭게 선택할 수 있습니다.

---

## 단축어 및 메뉴바 제어

- **메뉴바 상시 제어**: 설정 열기, 일정 즉시 새로고침, 업데이트 확인, NudgeLine 정보 창 열기 지원.
- **네이티브 정보 창**: 버전 정보, 빌드별 주요 변경 사항 및 공식 GitHub/피드백 링크를 한눈에 볼 수 있는 320pt 컴팩트 창 제공.
- **macOS 단축어 (AppIntents) 지원**:
  - `NudgeLine 새로고침`: 오늘 일정을 백그라운드에서 즉시 재조회.
  - `NudgeLine 펫 토글`: 타임라인 바 위의 펫 표시 여부를 단축어로 전환.

---

## 빌드 및 테스트 방법

### 시스템 요구 사양
- macOS 15.0+ (Sequoia)
- Apple Silicon 또는 Intel Mac

### 소스코드 빌드

```bash
# 1. 저장소 클론
git clone https://github.com/rareram/NudgeLine.git
cd NudgeLine

# 2. 로컬 개발용 빌드 (독립된 NudgeLine (Dev).app 생성)
./scripts/build_app.sh
open "build/NudgeLine (Dev).app"

# 또는 프로덕션 배포용 빌드
./scripts/build_app.sh --release
open "build/NudgeLine.app"
```

### 단위 테스트 실행

현지화 사전, 미리알림 파서, 일정 분할 알고리즘 및 보안 필터를 포괄하는 자동화 단위 테스트(8개 스위트 54개 테스트)를 직접 실행할 수 있습니다:

```bash
./scripts/run_tests.sh
```

---

## 프로젝트 아키텍처

```
NudgeLine/
├── Sources/NudgeLine/
│   ├── Models/         # CalendarEvent, ReminderItem, AppSettings
│   ├── Services/       # CalendarService, ReminderService, Localization, UpdateService
│   └── Views/          # OverlayPanel, PopoverPanel, TimelineBarView, Settings/
├── Tests/NudgeLineTests/ # Swift Testing 단위 테스트 스위트
└── scripts/            # 패키징, DMG 빌더, 테스트 러너, Git 훅
```

---

## 다국어 지원

NudgeLine은 Apple macOS HIG 공식 표준 용어를 준수하여 10개 언어를 기본 지원합니다:
- **시스템 기본값** (macOS 시스템 언어 자동 추종)
- **한국어**
- **영어** (English)
- **일본어** (日本語)
- **중국어 간체** (简体中文)
- **중국어 번체** (繁體中文)
- **러시아어** (Русский)
- **네덜란드어** (Nederlands)
- **프랑스어** (Français)
- **독일어** (Deutsch)
- **스페인어** (Español)

또한 특별한 순간이나 숨겨진 인터랙션을 통해 발견할 수 있는 비밀 언어가 숨겨져 있습니다.

언어 설정은 **설정 > 일반 > 언어**에서 언제든 변경할 수 있습니다.

---

## 크레딧 및 라이선스

- 본 프로젝트는 Andreas Katzian & ARTMIXTURE의 PixelScheduler(2014-2015) 콘셉트에서 영감을 받아 현대적인 macOS 기술로 재해석되었습니다.
- 라이선스: [MIT License](LICENSE)
- 저작권: (c) 2026 rareram. All rights reserved.

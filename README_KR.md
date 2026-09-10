# NudgeLine

<p align="center">
  <img src="docs/images/app_icon.png?v=2" width="128" height="128" alt="NudgeLine Icon" />
</p>

<p align="center">
  <strong>화면 가장자리에 오늘 일정을 표시하는 macOS 캘린더 타임라인 바</strong><br>
  <em>macOS 15+ (Sequoia) / Swift 6, SwiftUI</em>
</p>

<p align="center">
  <a href="README.md">English</a> | <strong>한국어</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2015.0%2B%20(Sequoia)-blue.svg" alt="Platform" />
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift Version" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%2F%20Intel-success.svg" alt="Architecture" />
  <img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="License" />
</p>

<p align="center">
  <a href="docs/images/settings_timeline_kr.png"><img src="docs/images/settings_timeline_kr.png" width="32%" style="vertical-align: top;" alt="타임라인 설정" /></a>
  <a href="docs/images/settings_indicator_kr.png"><img src="docs/images/settings_indicator_kr.png" width="32%" style="vertical-align: top;" alt="인디케이터 설정" /></a>
  <a href="docs/images/custom_pet_editor_kr.png"><img src="docs/images/custom_pet_editor_kr.png" width="32%" style="vertical-align: top;" alt="사용자 설정 펫 편집기" /></a>
</p>

---

## 소개

NudgeLine은 화면 테두리(좌측, 우측, 하단)에 얇은 선 형태로 오늘 일정을 표시하는 macOS 유틸리티입니다.

<p align="center">
  <img src="docs/images/pet_hide_tail_peek.gif" width="130" height="167" title="숨기 (꼬리 살랑)" alt="숨기 (꼬리 살랑)" style="margin: 0 18px;" />&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/images/pet_hide_head_peek.gif" width="130" height="167" title="숨기 (머리 빼꼼)" alt="숨기 (머리 빼꼼)" style="margin: 0 18px;" />&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/images/pet_hide_pop.gif" width="130" height="167" title="사라지기 (퐁!)" alt="사라지기 (퐁!)" style="margin: 0 18px;" /><br>
  <em>마우스 커서 접근 시 베젤 뒤로 회피하거나 사라지는 동작을 지원합니다 (6종).</em>
</p>

주요 특징:

- **마우스 패스스루**: 바 영역 외 클릭/스크롤이 통과되어 뒤쪽 창 조작 유지
- **타임라인 표시**: 배경 트랙, 이벤트 구분선, 4종 인디케이터 지원
- **일정 중복 처리**: 동시간대 중복 일정 간 색상 교차 전환
- **마스코트 펫**: 마우스 접근 시 회피 동작을 지원하는 펫 3종 및 커스텀 펫 등록
- **화상회의 링크 연동**: 10개 화상회의 플랫폼(Google Meet, Zoom, MS Teams, Webex 등) 1클릭 입장 및 미검증 링크 안내
- **화면 공유 및 전체 화면 대응**: 화면 공유/녹화 시 자동 숨김 및 전체 화면 전환 시 간섭 배제
- **순정 프레임워크 구현**: 외부 라이브러리 없이 SwiftUI, AppKit, EventKit으로 구현

---

## 설치 방법

### 1. Homebrew 설치 (권장)

터미널에서 한 줄로 간편하게 설치하고 업데이트할 수 있습니다:

```bash
brew install rareram/tap/nudgeline
```

---

### 2. DMG 파일 직접 다운로드

1. [GitHub Releases](https://github.com/rareram/NudgeLine/releases)에서 `NudgeLine.dmg`를 다운로드하여 설치합니다.
2. **보안 확인 메시지 발생 시 (최초 1회)**:
   - 개발자 인증서 미포함 오픈소스 앱이므로 최초 실행 시 확인 메시지가 표시될 수 있습니다.
   - **해결 방법**: `NudgeLine.app`을 **우클릭(Control+클릭) > [열기]**를 선택하거나, 터미널에서 다음 명령어를 실행합니다:
     ```bash
     xattr -cr /Applications/NudgeLine.app
     ```

---

## 기능 상세

### 1. 화면 테두리 타임라인 바
- **위치**: 화면 좌측, 우측, 하단
- **다중 디스플레이**: 주 모니터 전용 또는 전체 모니터 동시 표시
- **두께 조절**: 기본 두께(1~10px) 및 마우스 호버 시 확장 두께 설정
- **겹침 처리**: 동시간대 중복 일정 교차 전환
- **지난 일정 흐리게**: 종료된 일정은 불투명도와 채도를 낮추어(35%) 표시하며, 호버 시 원래 색상으로 복원

### 2. 시간 표시자 (인디케이터)
- **표시자 모양**: 삼각 틱, 라운드 돔, 돌출 블록, 포인트 링
- **시각 효과**: 색상 변경, 테두리 강조, 네온 효과 토글
- **단기 일정 우선 포커스**: 중복 일정 구간 호버 시 소요 시간이 짧은 일정 우선 강조

### 3. 일정 시작 전 알림 및 시작 효과
- **일정 시작 전 알림**: 회의 시작 5/10/15/20분 전 바 펄스 애니메이션(3초)으로 사전 알림
- **일정 시작 알림 효과**: 체리 블라섬, 네온 썬더, 메이플 리프, 스노우 플러리 4종 효과 지원
- **정각 알림**: 매시간 00분 정각 알림 효과 토글
- **발동 제어**: 일정 시작 시점에 1회 발동 (3분 쿨다운)

### 4. 마스코트 펫과 숨김 모션
- **기본 펫 3종**: 삼색고양이, 진도백구, 백호
- **6가지 숨김 동작**:
  - `tailPeek`: 베젤 뒤로 숨고 꼬리만 표시
  - `headPeek`: 몸은 숨고 머리만 표시
  - `pop`: 축소되며 사라짐
  - `vortex`: 회전하며 사라짐
  - `squish`: 납작해지며 사라짐
  - `smoke`: 흐려지며 사라짐
- **커스텀 펫 편집기**: PNG 프레임 등록, 속도(FPS), 좌/우 숨김 오프셋 설정 및 미리보기 지원

### 5. 팝오버 카드
- **상세 액션 카드**: 일정 상세 정보, 화상회의 입장 버튼, 미검증 링크 안내, 캘린더 앱 열기
- **심플 툴팁**: 제목과 시간 중심의 간결한 툴팁
- **카드 테마**: 시스템 설정 연동(Adaptive), 다크, 라이트 테마 지원 (라이트 모드 배경에 맞춘 버튼/링크 명암 보정 적용)
- **종일 일정 표시**: 시간 지정 일정과 함께 당일 종일 일정 표시
- **빈 바 호버 안내**: 일정이 없는 구간 호버 시 일정 상태 안내 툴팁 표시

### 6. 단축어(Shortcuts) 및 Siri 연동
- **AppIntents 지원**:
  - `NudgeLine 새로고침`: 오늘 일정 즉시 재동기화
  - `NudgeLine 펫 토글`: 타임라인 펫 마스코트 표시/숨김 전환

### 7. 환경설정
- **타임라인**: 바 위치, 두께, 호버 확장, 블록 테두리 및 네온 강조, 지난 일정 흐리게 토글, 배경 스타일(자동/다크/라이트/커스텀) 및 투명도
- **표시 및 효과**: 일정 카드 스타일/테마/투명도, 시간 표시자 모양/색상, 일정 시작 전 알림, 일정 시작 효과, 정각 알림, 펫 선택 및 숨김 동작, 커스텀 펫 관리
- **시간 및 캘린더**: 24시간 모드, 업무 시간 범위 설정, 표시할 캘린더 선택 및 색상 지정, 시스템 설정 딥링크
- **일반**: 언어 설정(시스템 기본/한국어/영어), 로그인 시 자동 실행, 다중 모니터 표시, 화면 공유 시 숨김, 전체 화면 시 숨김, 앱 정보

---

## 요구 사양 및 빌드

### 요구 사양
- macOS 15.0+ (Sequoia)
- Apple Silicon (M1~M4) 또는 Intel Mac

### 소스코드에서 빌드하기

```bash
# 1. 저장소 복제
git clone https://github.com/rareram/NudgeLine.git
cd NudgeLine

# 2. 로컬 개발 빌드 (격리된 NudgeLine (Dev).app)
./scripts/build_app.sh
open "build/NudgeLine (Dev).app"

# 또는 정식 배포용 빌드
./scripts/build_app.sh --release
open "build/NudgeLine.app"
```

### 단위 테스트 실행 (수동 테스트)

NudgeLine의 다국어 사전(L10n), 환경설정 기본값(AppSettings), 캘린더 이벤트 모델 정합성을 검증하는 단위 테스트를 직접 수동으로 실행할 수 있습니다:

```bash
# 로컬 단위 테스트 스위트 실행
./scripts/run_tests.sh

# 또는 Swift Package Manager 직접 실행 (Xcode 환경)
swift test
```

---

## 프로젝트 구조

```
NudgeLine/
├── Package.swift                         # SPM 매니페스트 (macOS 15+)
├── docs/
│   └── images/                           # README 스크린샷 및 아이콘 에셋
├── Resources/
│   ├── Info.plist                        # LSUIElement 및 캘린더 접근 권한 설명
│   └── AppIcon.icns                      # 앱 아이콘
├── Sources/
│   └── NudgeLine/
│       ├── AppDelegate.swift             # 앱 수명주기 및 화면 변경 옵저버
│       ├── main.swift                    # 진입점 및 단일 인스턴스 중복 실행 방지
│       ├── Models/
│       │   ├── AppSettings.swift         # UserDefaults 기반 환경설정 영속화
│       │   └── CalendarEvent.swift       # 이벤트 모델, 회의 링크 파서, 안전한 인덱싱
│       ├── Services/
│       │   ├── CalendarService.swift     # EventKit 백그라운드 캘린더 조회 서비스
│       │   ├── CustomPetService.swift    # 스레드 안전한 사용자 설정 펫 파일 매니저
│       │   ├── LaunchAtLoginHelper.swift # SMAppService 로그인 시 자동 실행 래퍼
│       │   ├── Localization.swift        # 한국어/영어 다국어 L10n 사전
│       │   └── NudgeLineShortcuts.swift  # 단축어 및 Siri 자동화를 위한 AppIntents
│       └── Views/
│           ├── OverlayPanel.swift        # 마우스 패스스루 지원 화면 테두리 플로팅 NSPanel
│           ├── PopoverPanel.swift        # .common 런루프 타이머 기반 팝오버 패널 및 빈 바 툴팁
│           ├── TimelineBarView.swift     # 메인 타임라인 렌더링 및 제스처 코디네이터
│           ├── HangingPetIndicatorView.swift # 마스코트 렌더러 및 궤도 물리 엔진
│           ├── HoverRenderers.swift      # 팝오버 렌더러 프로토콜
│           ├── EventPopoverView.swift    # 액션 카드 팝오버 (시간 지정 및 종일 일정 멀티 스택)
│           ├── SimpleInfoPopoverView.swift # 심플 툴팁 말풍선
│           ├── CustomPetEditorSheet.swift# 사용자 설정 펫 드래그 앤 드롭 모달
│           ├── SettingsView.swift        # 환경설정 탭 컨테이너
│           ├── SettingsWindowController.swift # 전용 환경설정 윈도우 수명주기 관리자
│           ├── Settings/                 # 모듈형 환경설정 탭
│           │   ├── TimelineTab.swift
│           │   ├── AppearanceTab.swift
│           │   ├── ScheduleTab.swift
│           │   └── GeneralTab.swift
│           ├── Effects/                  # 16프레임 1.0초 마이크로 이벤트 시작 알림 효과
│           │   ├── EventTriggerEffectView.swift
│           │   ├── CherryBlossomEffectAsset.swift
│           │   ├── ThunderEffectAsset.swift
│           │   ├── AutumnLeavesEffectAsset.swift
│           │   └── WinterSnowEffectAsset.swift
│           └── Pets/                     # 내장 16프레임 Base64 펫 에셋 및 상호작용
│               ├── PetProtocol.swift
│               ├── InteractivePetView.swift
│               ├── InteractiveCustomPetView.swift
│               ├── CatPetAsset.swift
│               ├── JindoDogPetAsset.swift
│               └── WhiteTigerPetAsset.swift
├── Tests/
│   └── NudgeLineTests/                   # Swift Testing 단위 테스트 스위트
└── scripts/
    ├── build_app.sh                      # 로컬 개발용(Dev) 및 정식 배포용 번들 빌드 스크립트
    ├── create_dmg.sh                     # 배포용 DMG 패키징 스크립트
    ├── run_tests.sh                      # 로컬 단위 테스트 러너
    ├── generate_dev_icon.swift           # DEV 아이콘 뱃징 스크립트
    ├── generate_app_icon.sh              # 정식 앱 아이콘 생성 스크립트
    ├── generate_custom_pet.py            # Swift 모델용 CLI 스프라이트 생성기
    └── check_security.sh                 # 정적 시크릿 스캔 스크립트
```


---

## 다국어 지원

- 영어 (English - 기본값)
- 한국어 (Korean)

**설정 > 일반 > 언어**에서 언제든 바꿀 수 있습니다.

---

## 크레딧 및 라이선스

- 원작 컨셉: Andreas Katzian & ARTMIXTURE의 PixelScheduler (2014-2015)
- 라이선스: [MIT License](LICENSE)
- 저작권: (c) 2026 rareram. All rights reserved.



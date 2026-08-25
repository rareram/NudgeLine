# NudgeLine (귀띔)

<p align="center">
  <img src="docs/images/app_icon.png" width="128" height="128" alt="NudgeLine Icon" />
</p>

<p align="center">
  <strong>화면 가장자리에서 오늘 일정을 살며시 귀띔해 주는 macOS 캘린더 타임라인 바</strong><br>
  <em>macOS 14+ (Sonoma / Sequoia) 환경을 위해 Swift 6 및 SwiftUI로 제작</em>
</p>

<p align="center">
  <a href="README.md">English</a> | <strong>한국어</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2014.0%2B%20(Sonoma%2FSequoia)-blue.svg" alt="Platform" />
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift Version" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%2F%20Intel-success.svg" alt="Architecture" />
  <img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="License" />
</p>

---

## 소개

NudgeLine(귀띔)은 화면 테두리(좌측, 우측, 하단)에 얇은 선 형태로 오늘 일정을 띄워주는 macOS 앰비언트 유틸리티입니다.

작업을 방해하는 시끄러운 전체 화면 팝업 대신, 마우스를 스칠 때 부드럽게 일정을 넌지시 알려줍니다:

- **마우스 패스스루**: 얇은 바 영역 바깥의 클릭이나 스크롤은 뒤에 있는 창(IDE, 브라우저 등)으로 그대로 통과됩니다.
- **깔끔한 시각 요소**: 차콜 다크 배경, 1px 이벤트 구분선, 커스텀 시간 표시자를 사용합니다.
- **겹치는 일정 표시**: 같은 시간대에 겹치는 일정은 부드럽게 색이 번갈아 바뀝니다.
- **마스코트 캐릭터**: 마우스 커서가 다가오면 화면 밖으로 자연스럽게 돌아 숨는 애니메이션 펫 3종(6가지 숨김 모션)과 사용자 정의 펫 불러오기를 지원합니다.
- **화상회의 바로가기**: Google Meet, Zoom, MS Teams, Webex 회의 링크를 자동으로 인식해 바로 접속할 수 있는 버튼을 띄웁니다.
- **가볍고 낮은 전력 소모**: 외부 라이브러리 없이 순수 Swift/SwiftUI와 AppKit, EventKit만으로 동작합니다.

---

## Homebrew로 설치하기

```bash
brew install rareram/tap/nudgeline
```

---

## 주요 기능

### 1. 화면 테두리 타임라인 바
- **위치**: 화면 좌측, 우측, 하단 중 선택
- **다중 모니터**: 메인 디스플레이에만 띄우거나 연결된 모든 모니터에 동시 표시
- **두께 조절**: 1px~10px 조절 및 마우스 올렸을 때 두께 자동 확장 옵션
- **겹침 처리**: 겹치는 일정 간 크로스페이드 전환

### 2. 시간 표시자 (인디케이터)
- **모양**: 삼각 틱, 라운드 돔, 돌출 블록, 포인트 링
- **커스텀**: 표시자 색상 변경, 테두리 강조, 네온 효과 토글
- **시간 툴팁**: 표시자에 마우스를 올리면 현재 시각과 남은 업무/하루 시간 확인
- **단기 일정 포커스**: 여러 일정이 겹친 곳을 가리킬 때 더 짧은 일정을 자동으로 우선 강조

### 3. 마스코트 펫과 숨김 모션
- **기본 펫 3종**: 삼색고양이, 진도백구, 백호 (16프레임 애니메이션)
- **6가지 숨김 동작**:
  - `tailPeek` (왼쪽으로 숨기): 머리부터 베젤 뒤로 숨고 꼬리만 살랑거림
  - `headPeek` (오른쪽으로 숨기): 몸은 숨고 머리와 눈만 쏙 빼꼼 내밈
  - `pop` (없어지기 - 팝/소멸): 작아지며 톡 터지듯 사라짐
  - `vortex` (없어지기 - 회오리): 720도 회전하며 소용돌이 속으로 사라짐
  - `squish` (없어지기 - 슬라임): 젤리처럼 납작하게 찌그러지며 사라짐
  - `smoke` (없어지기 - 연기): 흐려지고 퍼지며 연기처럼 사라짐
- **커스텀 펫 편집기**: PNG 프레임 시퀀스 등록, 속도(FPS) 조절, 좌/우 숨김 오프셋 튜닝 및 실시간 미리보기 지원

### 4. 팝오버 카드
- **상세 액션 카드**: 일정 상세 내용, 화상회의 원클릭 버튼, Apple 캘린더 바로가기 (0.22초 호버 브릿지)
- **심플 툴팁**: 제목과 시간만 간결하게 보여주는 말풍선 (마우스 벗어나면 0.04초 만에 즉시 닫힘)

### 5. 환경설정 (4개 탭)
- **타임라인**: 바 위치, 두께, 호버 확장, 배경 스타일(자동/다크/라이트/커스텀) 및 투명도
- **인디케이터**: 일정 카드 스타일/테마, 시간 표시자 모양/색상, 펫 선택, 숨김 동작, 커스텀 펫 관리
- **시간 및 캘린더**: 24시간 모드, 업무 시작/종료 시각, 표시할 캘린더 선택 및 캘린더별 색상 지정
- **일반**: 언어 선택 (시스템 기본/한국어/영어), 로그인 시 자동 실행, 다중 모니터 표시, 앱 정보

---

## 요구 사양 및 빌드

### 요구 사양
- macOS 14.0 (Sonoma) 또는 macOS 15.0+ (Sequoia)
- Apple Silicon (M1~M4) 또는 Intel Mac

### 소스코드에서 빌드하기

```bash
# 1. 저장소 복제
git clone https://github.com/rareram/NudgeLine.git
cd NudgeLine

# 2. 릴리즈 번들 빌드
./scripts/build_app.sh

# 3. 앱 실행
open build/NudgeLine.app
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



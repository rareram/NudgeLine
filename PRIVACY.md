# Privacy Policy for NudgeLine

Last Updated: September 12, 2026

NudgeLine ("we", "our", or "the application") is committed to protecting your privacy. This Privacy Policy explains our practices regarding the handling of your data.

---

## 1. Zero Personal Data Collection (로컬 우선 및 개인정보 수집 배제)

NudgeLine does not collect, store, or transmit any of your personal information, calendar events, or usage metrics.

- **Calendar Data**: Your calendar events, including event titles, start/end times, locations, notes, attendees, and meeting URLs, are read directly from your Mac's local system database via Apple's native `EventKit` framework. This information is processed exclusively in memory on your device to display the edge timeline bar and detail popovers. It is never uploaded to any remote server or third party.
- **Custom Pets & Preferences**: User preferences (such as timeline thickness, theme, and pet options) and custom pet image frames are stored strictly on your local disk within your standard macOS Application Support directory.

## 2. Network Communications (네트워크 통신 범위)

NudgeLine minimizes all network activity:

- **Action Links**: When you explicitly click on an external link (such as a Microsoft Teams meeting, Zoom call, Google Meet, or map service), the link is opened in your default web browser or designated native application via macOS system handlers.
- **Update Checks (Non-App Store Builds)**: In non-sandbox builds distributed via GitHub Releases or Homebrew, NudgeLine queries the public GitHub API (`api.github.com`) solely to determine if a newer version is available. No user-identifiable data is transmitted during this check.
- **Mac App Store Builds**: Builds distributed through the Mac App Store have all external in-app update checks completely disabled; updates are handled entirely by Apple's App Store mechanism.

## 3. Third-Party SDKs and Tracking (서드파티 분석 및 트래커 부재)

NudgeLine contains **zero** third-party analytics, crash-reporting SDKs, advertising frameworks, or tracking libraries.

## 4. Calendar Access Permissions (캘린더 접근 권한)

NudgeLine requires macOS Calendar access (`NSCalendarsFullAccessUsageDescription`) exclusively to visualize today's schedule along your screen edges. You can grant or revoke this permission at any time in macOS `System Settings > Privacy & Security > Calendars`.

## 5. Contact & Inquiries (문의처)

If you have any questions or feedback regarding this Privacy Policy, please open an issue at our official repository:
- GitHub Repository: [https://github.com/rareram/NudgeLine](https://github.com/rareram/NudgeLine)
- Issue Tracker: [https://github.com/rareram/NudgeLine/issues](https://github.com/rareram/NudgeLine/issues)

---

# 개인정보 처리방침 (국문)

최종 수정일: 2026년 9월 12일

NudgeLine은 사용자의 개인정보와 프라이버시를 최우선으로 존중합니다. 본 방침은 NudgeLine 앱의 데이터 처리 방식을 설명합니다.

### 1. 개인정보 수집 및 전송 배제
NudgeLine은 사용자의 개인정보나 캘린더 일정 데이터를 일체 수집, 저장, 또는 외부 서버로 전송하지 않습니다.
- 캘린더 데이터(일정 제목, 시간, 장소, 메모, 회의 링크 등)는 Apple의 순정 `EventKit` 프레임워크를 통해 Mac 로컬 기기 메모리에서만 읽고 렌더링됩니다.
- 사용자 환경설정 및 커스텀 펫 이미지는 사용자의 Mac 로컬 디스크(`Application Support/NudgeLine/`)에만 저장됩니다.

### 2. 네트워크 사용 범위
- 사용자가 일정 카드의 회의 참여 버튼, 지도 링크, 웹 링크를 직접 클릭했을 때만 해당 웹페이지 또는 네이티브 앱을 실행합니다.
- GitHub/Homebrew 배포판에 한하여 신규 버전 확인을 위해 GitHub 공식 릴리스 API를 단방향 조회하며, 어떠한 사용자 식별 정보도 전송하지 않습니다. Mac App Store 배포판에서는 해당 네트워크 조회 기능이 비활성화됩니다.

### 3. 서드파티 분석 툴 미탑재
NudgeLine에는 구글 애널리틱스, 파이어베이스, 광고 SDK 등 어떠한 제3자 트래커도 포함되어 있지 않습니다.

### 4. 캘린더 접근 권한
NudgeLine의 캘린더 접근 권한은 오직 화면 모서리에 당일 일정을 시각화하기 위한 목적으로만 사용되며, `macOS 시스템 설정 > 개인정보 보호 및 보안 > 캘린더`에서 언제든지 권한을 허용하거나 취소할 수 있습니다.

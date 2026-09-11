import Testing
import Foundation
import SwiftUI
@testable import NudgeLine

@Suite("Localization Tests")
struct LocalizationTests {
    @Test("한/영 다국어 주요 키 번역 검증")
    func testLocalizationKeys() {
        // 오늘 예정된 일정 없음 키
        #expect(L10n.tr(.noEventsToday, lang: .ko) == "오늘 예정된 일정이 없습니다.")
        #expect(L10n.tr(.noEventsToday, lang: .en) == "No events scheduled for today.")

        // 종일 일정 안내 키
        #expect(L10n.tr(.allDayNotice("전사 휴무"), lang: .ko) == "하루 종일: 전사 휴무")
        #expect(L10n.tr(.allDayNotice("Company Holiday"), lang: .en) == "All Day: Company Holiday")
        #expect(L10n.tr(.allDayNoticeWithCount("전사 휴무", 2), lang: .ko) == "하루 종일: 전사 휴무 외 2건")
        #expect(L10n.tr(.allDayNoticeWithCount("Company Holiday", 2), lang: .en) == "All Day: Company Holiday +2")

        // 시스템 설정 열기 키
        #expect(L10n.tr(.openSystemPrivacy, lang: .ko) == "시스템 설정 열기")
        #expect(L10n.tr(.openSystemPrivacy, lang: .en) == "Open System Settings")

        // 캘린더 권한 필요 키
        #expect(L10n.tr(.permissionNeeded, lang: .ko) == "macOS 캘린더 접근 권한이 필요합니다.")
        #expect(L10n.tr(.permissionNeeded, lang: .en) == "Calendar access permission is required.")

        // 지난 일정 흐리게 키
        #expect(L10n.tr(.dimPastEventsLabel, lang: .ko) == "지난 일정 흐리게")
        #expect(L10n.tr(.dimPastEventsLabel, lang: .en) == "Dim past events")

        // 설정창 4대 탭 타이틀 검증
        #expect(SettingsTab.timeline.title(lang: .ko) == "타임라인")
        #expect(SettingsTab.timeline.title(lang: .en) == "Timeline")
        #expect(SettingsTab.appearance.title(lang: .ko) == "표시 및 효과")
        #expect(SettingsTab.appearance.title(lang: .en) == "Appearance")
        #expect(SettingsTab.schedule.title(lang: .ko) == "시간 및 캘린더")
        #expect(SettingsTab.schedule.title(lang: .en) == "Time & Calendars")
        #expect(SettingsTab.general.title(lang: .ko) == "일반")
        #expect(SettingsTab.general.title(lang: .en) == "General")

        // 업데이트 확인, 재시작, 새로 고침 및 새 버전 알림 키
        #expect(L10n.tr(.checkForUpdates, lang: .ko) == "업데이트 확인...")
        #expect(L10n.tr(.checkForUpdates, lang: .en) == "Check for Updates...")
        #expect(L10n.tr(.restart, lang: .ko) == "재시작")
        #expect(L10n.tr(.restart, lang: .en) == "Restart")
        #expect(L10n.tr(.refresh, lang: .ko) == "새로 고침")
        #expect(L10n.tr(.refresh, lang: .en) == "Refresh")
        #expect(L10n.tr(.newVersionAvailableMenu("0.4"), lang: .ko) == "새 버전 업데이트 가능 (v0.4) →")
        #expect(L10n.tr(.newVersionAvailableMenu("0.4"), lang: .en) == "Update Available (v0.4) →")
        #expect(L10n.tr(.githubRepo, lang: .ko) == "GitHub 저장소 ↗")
        #expect(L10n.tr(.githubRepo, lang: .en) == "GitHub Repository ↗")

        // 빈 상태 및 범위 외 일정 안내 키
        #expect(L10n.tr(.noEventsShort, lang: .ko) == "일정 없음")
        #expect(L10n.tr(.noEventsShort, lang: .en) == "No events")
        #expect(L10n.tr(.noTimedEventsWithAllDayCard("연차"), lang: .ko) == "시간 일정 없음 · 종일: 연차")
        #expect(L10n.tr(.noTimedEventsWithAllDayCard("Vacation"), lang: .en) == "No timed events · All-Day: Vacation")
        #expect(L10n.tr(.outOfRangeSingleCard("21:00", "회의"), lang: .ko) == "표시 범위 외 1건 (21:00 회의)")
        #expect(L10n.tr(.outOfRangeSingleCard("21:00", "Meeting"), lang: .en) == "1 event outside range (21:00 Meeting)")
        #expect(L10n.tr(.outOfRangeSimple(2, "21:00"), lang: .ko) == "범위 외 2건 (21:00)")
        #expect(L10n.tr(.outOfRangeSimple(2, "21:00"), lang: .en) == "Outside range: 2 (21:00)")

        // 인앱 업데이트 및 지도 서비스 다국어 키
        #expect(L10n.tr(.updateNowInApp, lang: .ko) == "지금 업데이트")
        #expect(L10n.tr(.updateNowInApp, lang: .en) == "Update Now")
        #expect(L10n.tr(.installingAndRestarting, lang: .ko) == "업데이트 설치 및 재시작 중...")
        #expect(L10n.tr(.installingAndRestarting, lang: .en) == "Installing update & restarting...")
        #expect(L10n.tr(.preferredMapServiceLabel, lang: .ko) == "위치 열기:")
        #expect(L10n.tr(.preferredMapServiceLabel, lang: .en) == "Open Location with:")
    }
}

@Suite("AppSettings Tests")
struct AppSettingsTests {
    @Test("앱 환경설정 기본값 정합성 검증")
    func testDefaultSettings() {
        let settings = AppSettings.shared
        #expect(settings.startHour >= 0 && settings.startHour < 24)
        #expect(settings.endHour >= 0 && settings.endHour <= 24)
        #expect(settings.barWidth >= 1.0 && settings.barWidth <= 10.0)
        #expect(settings.hoverWidth >= settings.barWidth)
        #expect(settings.preEventAlertMinutes >= 5 && settings.preEventAlertMinutes <= 20)
    }

    @Test("테마 다크모드 판별 검증")
    func testEventCardTheme() {
        #expect(EventCardTheme.dark.isDark(for: .light) == true)
        #expect(EventCardTheme.dark.isDark(for: .dark) == true)
        #expect(EventCardTheme.light.isDark(for: .light) == false)
        #expect(EventCardTheme.light.isDark(for: .dark) == false)
        #expect(EventCardTheme.adaptive.isDark(for: .dark) == true)
        #expect(EventCardTheme.adaptive.isDark(for: .light) == false)
    }
}

@Suite("CalendarEvent Model Tests")
struct CalendarEventModelTests {
    @Test("이벤트 시간 범위 및 기본값 검증")
    func testEventModelInitialization() {
        let start = Date()
        let end = start.addingTimeInterval(3600)
        let event = CalendarEvent(
            id: "test-event-1",
            rawTitle: "스프린트 리뷰 미팅",
            startDate: start,
            endDate: end,
            isAllDay: false,
            calendarTitle: "업무",
            defaultColor: .blue
        )

        #expect(event.id == "test-event-1")
        #expect(event.title(lang: .ko) == "스프린트 리뷰 미팅")
        #expect(event.startDate == start)
        #expect(event.endDate == end)
        #expect(event.isAllDay == false)
        #expect(event.calendarTitle == "업무")
    }

    @Test("종일 일정 모델 및 시간 범위 포맷 검증")
    func testAllDayEventModel() {
        let today = Date()
        let allDayEvent = CalendarEvent(
            id: "all-day-1",
            rawTitle: "삼일절",
            startDate: today,
            endDate: today,
            isAllDay: true,
            calendarTitle: "대한민국 공휴일",
            defaultColor: .red
        )

        #expect(allDayEvent.isAllDay == true)
        #expect(allDayEvent.formattedTimeRange(lang: .ko) == "하루 종일")
        #expect(allDayEvent.formattedTimeRange(lang: .en) == "All Day")
    }
}

@Suite("Version Comparison Tests")
struct VersionComparisonTests {
    @Test("최신 버전 판별 로직 검증")
    func testIsNewerVersion() {
        // 더 높은 마이너 버전
        #expect(UpdateService.isNewerVersion(latest: "0.4", current: "0.3", currentBuild: "275") == true)
        // 동일 버전 동일 빌드
        #expect(UpdateService.isNewerVersion(latest: "0.3", current: "0.3", currentBuild: "275") == false)
        // 동일 메이저/마이너지만 더 높은 패치/빌드
        #expect(UpdateService.isNewerVersion(latest: "0.3.276", current: "0.3", currentBuild: "275") == true)
        // 이전 버전
        #expect(UpdateService.isNewerVersion(latest: "0.2.9", current: "0.3", currentBuild: "275") == false)
        // 더 높은 메이저 버전
        #expect(UpdateService.isNewerVersion(latest: "1.0.0", current: "0.3", currentBuild: "275") == true)
    }

    @Test("ReleaseInfo ZIP Asset 식별 검증")
    func testReleaseInfoZipAsset() {
        let releaseWithZip = UpdateService.ReleaseInfo(
            version: "0.4.0",
            url: URL(string: "https://github.com/rareram/NudgeLine/releases/tag/v0.4.0")!,
            zipURL: URL(string: "https://github.com/rareram/NudgeLine/releases/download/v0.4.0/NudgeLine.zip")!
        )
        #expect(releaseWithZip.version == "0.4.0")
        #expect(releaseWithZip.zipURL != nil)
        #expect(releaseWithZip.zipURL?.pathExtension == "zip")

        let releaseWithoutZip = UpdateService.ReleaseInfo(
            version: "0.4.0",
            url: URL(string: "https://github.com/rareram/NudgeLine/releases/tag/v0.4.0")!
        )
        #expect(releaseWithoutZip.zipURL == nil)
    }
}

@Suite("Meeting Integration and Inactive Event Tests")
struct MeetingIntegrationAndInactiveEventTests {
    @Test("SafeLinks 및 Google Redirect 언래핑과 피싱 방어 검증")
    func testSafeLinksAndRedirectUnwrapping() {
        // 1. SafeLinks로 감싸진 정상 Microsoft Teams 링크
        let safeTeamsUrl = URL(string: "https://nam01.safelinks.protection.outlook.com/?url=https%3A%2F%2Fteams.microsoft.com%2Fl%2Fmeetup-join%2F19%253ameeting_xyz%40thread.v2%2F0%3Fcontext%3Dabc&data=test")!
        let teamsEvent = CalendarEvent(
            id: "safe-teams-1",
            rawTitle: "팀 주간 회의",
            url: safeTeamsUrl
        )
        #expect(teamsEvent.meetingInfo != nil)
        #expect(teamsEvent.meetingInfo?.platform == .teams)
        #expect(teamsEvent.meetingInfo?.url.host == "teams.microsoft.com")

        // 2. SafeLinks로 감싸진 악성 피싱 도메인 (피싱 방어 화이트리스트 차단 검증)
        let phishingUrl = URL(string: "https://nam01.safelinks.protection.outlook.com/?url=https%3A%2F%2Fevil-phishing-site.com%2Flogin-teams&data=fake")!
        let phishingEvent = CalendarEvent(
            id: "phishing-1",
            rawTitle: "긴급 계정 확인",
            url: phishingUrl
        )
        #expect(phishingEvent.meetingInfo != nil)
        #expect(phishingEvent.meetingInfo?.platform == .unverified) // 클릭 차단 배지

        // 3. Google Redirect로 감싸진 Zoom 회의 링크
        let googleZoomUrl = URL(string: "https://www.google.com/url?q=https%3A%2F%2Fzoom.us%2Fj%2F123456789%3Fpwd%3Dmysecretpwd&source=calendar")!
        let zoomEvent = CalendarEvent(
            id: "google-zoom-1",
            rawTitle: "외부 파트너 미팅",
            url: googleZoomUrl
        )
        #expect(zoomEvent.meetingInfo != nil)
        #expect(zoomEvent.meetingInfo?.platform == .zoom)
        #expect(zoomEvent.meetingInfo?.url.host == "zoom.us")
    }

    @Test("거절 및 취소 일정 모델 플래그 검증")
    func testDeclinedAndCanceledModel() {
        let normalEvent = CalendarEvent(id: "ev-1", rawTitle: "정상 일정", isDeclined: false, isCanceled: false)
        let declinedEvent = CalendarEvent(id: "ev-2", rawTitle: "거절 일정", isDeclined: true, isCanceled: false)
        let canceledEvent = CalendarEvent(id: "ev-3", rawTitle: "취소 일정", isDeclined: false, isCanceled: true)

        #expect(normalEvent.isCanceledOrDeclined == false)
        #expect(declinedEvent.isCanceledOrDeclined == true)
        #expect(canceledEvent.isCanceledOrDeclined == true)
    }

    @Test("타임라인 세그먼트 isInactive 판별 검증")
    func testTimelineSegmentInactive() {
        let cluster = EventCluster(id: "c-1", start: Date(), end: Date().addingTimeInterval(3600), events: [])
        let declinedEv = CalendarEvent(id: "d-1", isDeclined: true)
        let activeEv = CalendarEvent(id: "a-1", isDeclined: false, isCanceled: false)

        let inactiveSegment = TimelineSegment(id: "seg-1", start: Date(), end: Date().addingTimeInterval(1800), events: [declinedEv], cluster: cluster)
        #expect(inactiveSegment.isInactive == true)

        let activeSegment = TimelineSegment(id: "seg-2", start: Date(), end: Date().addingTimeInterval(1800), events: [declinedEv, activeEv], cluster: cluster)
        #expect(activeSegment.isInactive == false)
    }

    @Test("MeetingAppLauncher 네이티브 URL 스킴 변환 검증")
    func testMeetingAppLauncherSchemes() {
        // Teams
        let teamsInfo = MeetingInfo(platform: .teams, url: URL(string: "https://teams.microsoft.com/l/meetup-join/123")!)
        let nativeTeams = MeetingAppLauncher.nativeSchemeUrl(for: teamsInfo)
        #expect(nativeTeams?.scheme == "msteams")

        // Zoom
        let zoomInfo = MeetingInfo(platform: .zoom, url: URL(string: "https://zoom.us/j/987654321?pwd=abc")!)
        let nativeZoom = MeetingAppLauncher.nativeSchemeUrl(for: zoomInfo)
        #expect(nativeZoom?.scheme == "zoommtg")
        #expect(nativeZoom?.absoluteString.contains("join?confno=987654321") == true)

        // Webex
        let webexInfo = MeetingInfo(platform: .webex, url: URL(string: "https://company.webex.com/meet/room")!)
        let nativeWebex = MeetingAppLauncher.nativeSchemeUrl(for: webexInfo)
        #expect(nativeWebex?.scheme == "webex")

        // Discord
        let discordInfo = MeetingInfo(platform: .discord, url: URL(string: "https://discord.gg/invite123")!)
        let nativeDiscord = MeetingAppLauncher.nativeSchemeUrl(for: discordInfo)
        #expect(nativeDiscord?.scheme == "discord")

        // FaceTime
        let faceTimeInfo = MeetingInfo(platform: .faceTime, url: URL(string: "facetime://user@example.com")!)
        let nativeFaceTime = MeetingAppLauncher.nativeSchemeUrl(for: faceTimeInfo)
        #expect(nativeFaceTime?.scheme == "facetime")
    }

    @Test("FaceTime 미팅 링크 및 네이티브 스킴 추출 검증")
    func testFaceTimeLinkDetection() {
        // 1. Apple FaceTime 웹 통화 링크 (iOS 15 / macOS Monterey 이후)
        let webEvent = CalendarEvent(
            id: "ft-web-1",
            rawTitle: "디자인 리뷰 미팅",
            url: URL(string: "https://facetime.apple.com/join#v=1&p=abcdef123456&k=xyz")!
        )
        #expect(webEvent.meetingInfo != nil)
        #expect(webEvent.meetingInfo?.platform == .faceTime)
        #expect(webEvent.meetingInfo?.url.host == "facetime.apple.com")

        // 2. FaceTime 네이티브 URL 스킴 (메모/위치 필드에 포함된 경우)
        let schemeEvent = CalendarEvent(
            id: "ft-scheme-1",
            rawTitle: "팀장님 면담",
            notes: "회의 링크: facetime://test@apple.com"
        )
        #expect(schemeEvent.meetingInfo != nil)
        #expect(schemeEvent.meetingInfo?.platform == .faceTime)
        #expect(schemeEvent.meetingInfo?.url.scheme == "facetime")
    }

    @Test("PreferredMapService 지도 검색 URL 생성 및 순서 검증")
    func testPreferredMapServiceURLs() {
        // 0. 케이스 순서 검증: Apple, Google, 네이버, 카카오
        #expect(PreferredMapService.allCases == [.apple, .google, .naver, .kakao])
        #expect(PreferredMapService.availableCases(for: .ko) == [.apple, .google, .naver, .kakao])
        #expect(PreferredMapService.availableCases(for: .en) == [.apple, .google])

        let location = "서울특별시 강남구 테헤란로 152"

        // 1. Apple 지도 (maps:// 스킴)
        let appleUrl = PreferredMapService.apple.url(for: location)
        #expect(appleUrl != nil)
        #expect(appleUrl?.scheme == "maps")
        #expect(appleUrl?.query?.contains("q=") == true)

        // 2. 네이버 지도
        let naverUrl = PreferredMapService.naver.url(for: location)
        #expect(naverUrl != nil)
        #expect(naverUrl?.host == "map.naver.com")
        #expect(naverUrl?.absoluteString.contains("/v5/search/") == true)

        // 3. 카카오맵
        let kakaoUrl = PreferredMapService.kakao.url(for: location)
        #expect(kakaoUrl != nil)
        #expect(kakaoUrl?.host == "map.kakao.com")
        #expect(kakaoUrl?.absoluteString.contains("/link/search/") == true)

        // 4. Google 지도
        let googleUrl = PreferredMapService.google.url(for: location)
        #expect(googleUrl != nil)
        #expect(googleUrl?.host == "www.google.com")
        #expect(googleUrl?.path == "/maps/search")
        #expect(googleUrl?.query?.contains("api=1") == true)

        // 5. 빈 문자열 처리
        #expect(PreferredMapService.apple.url(for: "") == nil)
        #expect(PreferredMapService.naver.url(for: "   ") == nil)
    }
}

@Suite("WebLink and Seminar URL Extraction Tests")
struct WebLinkExtractionTests {
    @Test("Apple 캘린더 URL 필드 우선 추출 검증")
    func testAppleCalendarExplicitUrl() {
        let event = CalendarEvent(
            id: "apple-url-1",
            rawTitle: "AWS 이노베이션 세미나",
            url: URL(string: "https://aws.amazon.com/ko/events/summit")!
        )
        #expect(event.webLink != nil)
        #expect(event.webLink?.displayHost == "aws.amazon.com")
        #expect(event.webLink?.url.absoluteString == "https://aws.amazon.com/ko/events/summit")
    }

    @Test("구글 캘린더 본문(notes) 내 일반 웹 링크 추출 검증")
    func testGoogleCalendarNotesUrlExtraction() {
        let event = CalendarEvent(
            id: "google-notes-1",
            rawTitle: "기획안 싱크",
            notes: "사전 검토 부탁드립니다:\nhttps://notion.so/my-team-workspace/page-1234\n감사합니다."
        )
        #expect(event.webLink != nil)
        #expect(event.webLink?.displayHost == "notion.so")
        #expect(event.webLink?.url.absoluteString.contains("notion.so/my-team-workspace") == true)
    }

    @Test("본문 내 화상회의 링크와 일반 참고 링크 공존 시 분리 검증")
    func testMeetingAndWebLinkCoexistence() {
        let notesText = """
        팀 주간 회의입니다.
        화상 회의 참가: https://meet.google.com/abc-defg-hij
        참고 피그마: https://www.figma.com/file/abcdef/Design-System?node-id=0%3A1
        """
        let event = CalendarEvent(
            id: "coexist-1",
            rawTitle: "프로덕트 디자인 리뷰",
            notes: notesText
        )
        // 1. 화상회의 버튼은 Google Meet으로 분리
        #expect(event.meetingInfo != nil)
        #expect(event.meetingInfo?.platform == .googleMeet)
        #expect(event.meetingInfo?.url.host == "meet.google.com")

        // 2. 웹 링크는 Figma로 분리 (www. 접두사 제거)
        #expect(event.webLink != nil)
        #expect(event.webLink?.displayHost == "figma.com")
        #expect(event.webLink?.url.absoluteString.contains("figma.com/file/abcdef") == true)
    }

    @Test("엔터프라이즈 SafeLinks 래핑 URL의 실제 타깃 호스트 표시 및 원본 보존 검증")
    func testEnterpriseSafeLinksWebLink() {
        let safeUrl = URL(string: "https://nam01.safelinks.protection.outlook.com/?url=https%3A%2F%2Faws.amazon.com%2Fevents%2Fcloud-day&data=corp-safe-data")!
        let event = CalendarEvent(
            id: "safelinks-web-1",
            rawTitle: "클라우드 데이 기조연설",
            url: safeUrl
        )
        #expect(event.webLink != nil)
        #expect(event.webLink?.displayHost == "aws.amazon.com")
        #expect(event.webLink?.url == safeUrl)
    }

    @Test("구글 캘린더 시스템 자동 링크 필터링 검증")
    func testSystemCalendarUrlExclusion() {
        let event = CalendarEvent(
            id: "system-url-1",
            rawTitle: "사내 티타임",
            notes: "캘린더 상세 정보 보기: https://calendar.google.com/calendar/event?eid=abcdef"
        )
        // calendar.google.com은 시스템 링크이므로 일반 웹 링크로 표출되지 않음
        #expect(event.webLink == nil)
    }

    @Test("화상회의 링크만 URL 필드에 있는 경우 중복 제외 검증")
    func testMeetingUrlDeduplication() {
        let zoomUrl = URL(string: "https://zoom.us/j/987654321")!
        let event = CalendarEvent(
            id: "zoom-only-1",
            rawTitle: "화상 인터뷰",
            url: zoomUrl
        )
        #expect(event.meetingInfo != nil)
        #expect(event.meetingInfo?.platform == .zoom)
        // 하단 줌 버튼이 생기므로 상단 웹 링크로는 중복 노출되지 않음
        #expect(event.webLink == nil)
    }
}

// MARK: - 본문 메모 정제 및 보일러플레이트 필터링 검증
@Suite("Notes Sanitization and Display Tests")
struct NotesSanitizationTests {
    @Test("Google Meet 자동 생성 시스템 보일러플레이트만 있는 경우 메모 숨김(nil) 검증")
    func testGoogleMeetBoilerplateFiltering() {
        let rawNotes = """
        -::~:~::~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:::~-
        Do not edit this section of the description.
        This event has a video call.
        Join: https://meet.google.com/abc-defg-hij
        -::~:~::~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:::~-
        """
        let event = CalendarEvent(
            id: "meet-boilerplate-1",
            rawTitle: "스프린트 기획 회의",
            notes: rawNotes
        )
        // 사용자가 작성한 메모가 없으므로 nil을 반환하여 카드에서 완전 숨김 처리됨
        #expect(event.displayNotes == nil)
    }

    @Test("실제 사용자 메모와 Google Meet 보일러플레이트 공존 시 실제 메모만 보존 검증")
    func testUserNotesPreservedWithBoilerplate() {
        let rawNotes = """
        Q4 로드맵 우선순위 산정 및 신규 피처 논의
        준비물: 기획안 문서

        -::~:~::~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:::~-
        Do not edit this section of the description.
        This event has a video call.
        Join: https://meet.google.com/abc-defg-hij
        -::~:~::~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:::~-
        """
        let event = CalendarEvent(
            id: "user-notes-1",
            rawTitle: "스프린트 기획 회의",
            notes: rawNotes
        )
        #expect(event.displayNotes != nil)
        #expect(event.displayNotes?.contains("Q4 로드맵 우선순위 산정") == true)
        #expect(event.displayNotes?.contains("준비물: 기획안 문서") == true)
        #expect(event.displayNotes?.contains("-::~") == false)
        #expect(event.displayNotes?.contains("Do not edit") == false)
    }

    @Test("MS Teams 시스템 구분선 및 안내 문구 필터링 검증")
    func testTeamsBoilerplateFiltering() {
        let rawNotes = """
        ________________________________________________________________________________
        Microsoft Teams Need help?
        Join the meeting now: https://teams.microsoft.com/l/meetup-join/12345
        Meeting ID: 293 847 192 012
        Passcode: aBcD12
        ________________________________________________________________________________
        """
        let event = CalendarEvent(
            id: "teams-boilerplate-1",
            rawTitle: "팀 주간 싱크",
            notes: rawNotes
        )
        #expect(event.displayNotes == nil)
    }
}





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
        #expect(AppDelegate.isNewerVersion(latest: "0.4", current: "0.3", currentBuild: "275") == true)
        // 동일 버전 동일 빌드
        #expect(UpdateService.isNewerVersion(latest: "0.3", current: "0.3", currentBuild: "275") == false)
        #expect(AppDelegate.isNewerVersion(latest: "0.3", current: "0.3", currentBuild: "275") == false)
        // 동일 메이저/마이너지만 더 높은 패치/빌드
        #expect(UpdateService.isNewerVersion(latest: "0.3.276", current: "0.3", currentBuild: "275") == true)
        #expect(AppDelegate.isNewerVersion(latest: "0.3.276", current: "0.3", currentBuild: "275") == true)
        // 이전 버전
        #expect(UpdateService.isNewerVersion(latest: "0.2.9", current: "0.3", currentBuild: "275") == false)
        #expect(AppDelegate.isNewerVersion(latest: "0.2.9", current: "0.3", currentBuild: "275") == false)
        // 더 높은 메이저 버전
        #expect(UpdateService.isNewerVersion(latest: "1.0.0", current: "0.3", currentBuild: "275") == true)
        #expect(AppDelegate.isNewerVersion(latest: "1.0.0", current: "0.3", currentBuild: "275") == true)
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
    }

    @Test("PreferredMapService 지도 검색 URL 생성 및 순서 검증")
    func testPreferredMapServiceURLs() {
        // 0. 케이스 순서 검증: Apple, Google, 네이버, 카카오
        #expect(PreferredMapService.allCases == [.apple, .google, .naver, .kakao])

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




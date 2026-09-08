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

    @Test("로컬 디스크 번들 교체(빌드/버전 상승) 판별 검증")
    func testIsDiskNewer() {
        // 동일 버전에서 디스크 빌드 번호가 더 높은 경우 (brew upgrade 일반 시나리오)
        #expect(UpdateService.isDiskNewer(diskVersion: "0.3", diskBuild: "285", currentVersion: "0.3", currentBuild: "284") == true)
        // 동일 버전 동일 빌드
        #expect(UpdateService.isDiskNewer(diskVersion: "0.3", diskBuild: "284", currentVersion: "0.3", currentBuild: "284") == false)
        // 디스크가 이전 빌드인 경우
        #expect(UpdateService.isDiskNewer(diskVersion: "0.3", diskBuild: "283", currentVersion: "0.3", currentBuild: "284") == false)
        // 디스크의 마이너 버전이 상승한 경우
        #expect(UpdateService.isDiskNewer(diskVersion: "0.4", diskBuild: "1", currentVersion: "0.3", currentBuild: "284") == true)
        // 디스크의 메이저 버전이 상승한 경우
        #expect(UpdateService.isDiskNewer(diskVersion: "1.0", diskBuild: "1", currentVersion: "0.3", currentBuild: "284") == true)
        // 디스크 버전이 이미 3단 시맨틱 태그(0.3.285)로 들어온 경우
        #expect(UpdateService.isDiskNewer(diskVersion: "0.3.285", diskBuild: "", currentVersion: "0.3", currentBuild: "284") == true)
    }
}


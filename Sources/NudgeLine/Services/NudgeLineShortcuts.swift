// macOS 단축어(Shortcuts) 및 Siri 자동화 연동을 위한 AppIntents 설정
import Foundation
import AppIntents

// MARK: - 1. NudgeLine 일정 새로고침 인텐트 (Refresh Schedule)
public struct RefreshNudgeLineIntent: AppIntent {
    public static var title: LocalizedStringResource = "Refresh NudgeLine Schedule"
    public static var description = IntentDescription("Refreshes today's calendar events on the NudgeLine timeline bar.")
    public static var openAppWhenRun: Bool = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        CalendarService.shared.loadCalendars()
        CalendarService.shared.fetchEvents()
        return .result()
    }
}

// MARK: - 2. 펫 마스코트 표시/숨김 토글 인텐트 (Toggle Pet Visibility)
public struct TogglePetVisibilityIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle NudgeLine Pet Visibility"
    public static var description = IntentDescription("Toggles the visibility of the pet companion on the timeline bar.")
    public static var openAppWhenRun: Bool = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        AppSettings.shared.isPetEnabled.toggle()
        return .result()
    }
}

// MARK: - 3. 단축어 앱 기본 프리셋 프로바이더 (AppShortcutsProvider)
public struct NudgeLineShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RefreshNudgeLineIntent(),
            phrases: [
                "Refresh \(.applicationName)",
                "Reload \(.applicationName) schedule",
                "\(.applicationName) 새로고침",
                "\(.applicationName) 일정 동기화"
            ],
            shortTitle: "Refresh Schedule",
            systemImageName: "arrow.clockwise"
        )
        AppShortcut(
            intent: TogglePetVisibilityIntent(),
            phrases: [
                "Toggle \(.applicationName) pet",
                "\(.applicationName) 펫 토글"
            ],
            shortTitle: "Toggle Pet",
            systemImageName: "pawprint"
        )
    }
}

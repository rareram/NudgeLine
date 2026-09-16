// 환경설정 4대 탭(타임라인, 외형, 일정, 일반) 모달 창 뷰
import SwiftUI
import EventKit
import AppKit

public struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var calendarService: CalendarService
    @ObservedObject var reminderService: ReminderService
    @ObservedObject var tabManager: SettingsWindowController.TabManager

    public init(
        settings: AppSettings = .shared,
        calendarService: CalendarService = .shared,
        reminderService: ReminderService = .shared,
        tabManager: SettingsWindowController.TabManager
    ) {
        self.settings = settings
        self.calendarService = calendarService
        self.reminderService = reminderService
        self.tabManager = tabManager
    }

    public var body: some View {
        Group {
            switch tabManager.selectedTab {
            case .timeline:
                TimelineTab(settings: settings)
            case .appearance:
                AppearanceTab(settings: settings)
            case .schedule:
                ScheduleTab(settings: settings, calendarService: calendarService)
            case .reminders:
                RemindersTab(settings: settings, reminderService: reminderService)
            case .general:
                GeneralTab(settings: settings)
            }
        }
        .frame(width: SettingsWindowController.contentWidth, alignment: .top)
        .padding(.horizontal, SettingsWindowController.contentHorizontalPadding)
        .padding(.vertical, 10)
        .frame(width: SettingsWindowController.windowWidth)
    }
}

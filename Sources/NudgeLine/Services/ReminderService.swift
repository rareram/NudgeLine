// EventKit 기반 시스템 미리알림(Reminders) 연동 및 실시간 동기화 서비스
import Foundation
import EventKit
import SwiftUI
import Combine
import AppKit

public final class ReminderService: ObservableObject {
    public static let shared = ReminderService()

    private let eventStore = EKEventStore()
    private let fetchSerialQueue = DispatchQueue(label: "com.nudgeline.reminderFetchSerialQueue", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()
    private var isSleeping: Bool = false

    @Published public private(set) var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published public private(set) var reminders: [ReminderItem] = []
    @Published public private(set) var reminderLists: [ReminderListInfo] = []

    private init() {
        let initialStatus = EKEventStore.authorizationStatus(for: .reminder)
        self.authorizationStatus = initialStatus
        setupEventStoreObserver()
    }
}

// MARK: - 1. 미리알림 접근 권한(TCC) 관리
extension ReminderService {
    public func checkAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        self.authorizationStatus = status
        if isAuthorized(status: status) {
            refreshSources()
            loadReminderLists()
            fetchReminders()
        }
    }

    public func isAuthorized(status: EKAuthorizationStatus? = nil) -> Bool {
        let currentStatus = EKEventStore.authorizationStatus(for: .reminder)
        if status == nil && self.authorizationStatus != currentStatus {
            DispatchQueue.main.async { [weak self] in
                self?.checkAuthorizationStatus()
            }
        }
        let st = status ?? currentStatus
        return st == .fullAccess || st.rawValue == 3
    }

    public func requestAccess() {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToReminders { [weak self] _, _ in
                DispatchQueue.main.async {
                    self?.checkAuthorizationStatus()
                }
            }
        } else {
            eventStore.requestAccess(to: .reminder) { [weak self] _, _ in
                DispatchQueue.main.async {
                    self?.checkAuthorizationStatus()
                }
            }
        }
    }

    public static func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - 2. 미리알림 목록 및 데이터 비동기 조회 (Data Fetching)
extension ReminderService {
    public func refreshSources() {
        guard isAuthorized() else { return }
        fetchSerialQueue.async { [weak self] in
            guard let self = self else { return }
            self.eventStore.refreshSourcesIfNecessary()
        }
    }

    public func loadReminderLists() {
        guard isAuthorized() else { return }

        fetchSerialQueue.async { [weak self] in
            guard let self = self else { return }
            let calendars = self.eventStore.calendars(for: .reminder)
            let listInfos = calendars.map { cal -> ReminderListInfo in
                let srcTitle = (cal.source?.title.isEmpty == false) ? (cal.source?.title ?? L10n.tr(.otherSource)) : L10n.tr(.otherSource)
                let color: Color
                if let cg = cal.cgColor {
                    color = Color(cgColor: cg)
                } else {
                    color = .orange
                }
                return ReminderListInfo(
                    id: cal.calendarIdentifier,
                    title: cal.title,
                    color: color,
                    sourceTitle: srcTitle
                )
            }.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }

            DispatchQueue.main.async {
                self.reminderLists = listInfos
            }
        }
    }

    public func fetchReminders(for baseDate: Date = Date(), settings: AppSettings = .shared) {
        guard settings.enableReminders, isAuthorized() else {
            DispatchQueue.main.async {
                if !self.reminders.isEmpty {
                    self.reminders = []
                }
            }
            return
        }

        let visibilitySnapshot = settings.reminderVisibility

        fetchSerialQueue.async { [weak self] in
            guard let self = self else { return }
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: baseDate)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }

            let allCalendars = self.eventStore.calendars(for: .reminder)
            let activeCalendars = allCalendars.filter { cal in
                visibilitySnapshot[cal.calendarIdentifier] ?? true
            }

            guard !activeCalendars.isEmpty else {
                DispatchQueue.main.async {
                    self.reminders = []
                }
                return
            }

            let predicate = self.eventStore.predicateForIncompleteReminders(
                withDueDateStarting: startOfDay,
                ending: endOfDay,
                calendars: activeCalendars
            )

            self.eventStore.fetchReminders(matching: predicate) { [weak self] ekReminders in
                guard let self = self else { return }
                var items: [ReminderItem] = []

                for ekReminder in (ekReminders ?? []) {
                    guard let item = ReminderItem(from: ekReminder, calendar: calendar) else {
                        continue
                    }
                    if item.dueDate >= startOfDay && item.dueDate < endOfDay {
                        items.append(item)
                    }
                }

                items.sort { $0.dueDate < $1.dueDate }

                DispatchQueue.main.async {
                    self.reminders = items
                }
            }
        }
    }
}

// MARK: - 3. 시스템 및 환경설정 변경 옵저버 등록
extension ReminderService {
    private func setupEventStoreObserver() {
        // 1. 시스템 미리알림 데이터 변경 옵저버
        NotificationCenter.default.publisher(for: .EKEventStoreChanged, object: eventStore)
            .receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, !self.isSleeping else { return }
                self.loadReminderLists()
                self.fetchReminders()
            }
            .store(in: &cancellables)

        // 2. 미리알림 연동 켜기/끄기 설정 옵저버
        AppSettings.shared.$enableReminders
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                guard let self = self else { return }
                if enabled {
                    self.checkAuthorizationStatus()
                    self.loadReminderLists()
                    self.fetchReminders()
                } else {
                    self.reminders = []
                }
            }
            .store(in: &cancellables)

        // 3. 미리알림 목록 필터 변경 옵저버
        AppSettings.shared.$reminderVisibility
            .map { _ in () }
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, !self.isSleeping else { return }
                self.fetchReminders()
            }
            .store(in: &cancellables)

        // 4. 날짜 변경(자정)
        NotificationCenter.default.publisher(for: .NSCalendarDayChanged, object: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, !self.isSleeping else { return }
                self.refreshSources()
                self.loadReminderLists()
                self.fetchReminders()
            }
            .store(in: &cancellables)

        // 5. 절전 모드 진입 및 복귀
        let wsCenter = NSWorkspace.shared.notificationCenter
        Publishers.Merge(
            wsCenter.publisher(for: NSWorkspace.willSleepNotification),
            wsCenter.publisher(for: NSWorkspace.screensDidSleepNotification)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.isSleeping = true
        }
        .store(in: &cancellables)

        Publishers.Merge(
            wsCenter.publisher(for: NSWorkspace.didWakeNotification),
            wsCenter.publisher(for: NSWorkspace.screensDidWakeNotification)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            guard let self = self else { return }
            self.isSleeping = false
            self.fetchReminders()
        }
        .store(in: &cancellables)

        // 6. 시스템 설정 등 외부에서 앱으로 복귀했을 때 권한 상태 즉시 갱신
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if AppSettings.shared.enableReminders {
                    self.checkAuthorizationStatus()
                }
            }
            .store(in: &cancellables)
    }
}

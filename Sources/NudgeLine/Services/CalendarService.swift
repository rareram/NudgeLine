// EventKit 기반 시스템 캘린더 연동 및 실시간 일정 동기화 서비스
import Foundation
import EventKit
import SwiftUI
import Combine
import AppKit

// MARK: - 1. 캘린더 메타데이터 모델
public struct CalendarInfo: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let defaultColor: Color
    public let sourceTitle: String
}

public struct CalendarSourceGroup: Identifiable, Sendable {
    public let id: String
    public let title: String
    public var calendars: [CalendarInfo]
}

// MARK: - 2. 캘린더 동기화 서비스 본체 (CalendarService)
public final class CalendarService: ObservableObject {
    public static let shared = CalendarService()

    private let eventStore = EKEventStore()
    private let fetchSerialQueue = DispatchQueue(label: "com.nudgeline.fetchSerialQueue", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()
    private var isSleeping: Bool = false

    @Published public private(set) var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published public private(set) var events: [CalendarEvent] = []
    @Published public private(set) var sourceGroups: [CalendarSourceGroup] = []
    @Published public var errorMessage: String? = nil

    private init() {
        let initialStatus = EKEventStore.authorizationStatus(for: .event)
        self.authorizationStatus = initialStatus
        setupEventStoreObserver()
    }
}

// MARK: - 3. 캘린더 접근 권한(TCC) 관리
extension CalendarService {
    // 캘린더 TCC 권한 상태 갱신 (권한 획득 시 데이터 자동 로드)
    public func checkAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        self.authorizationStatus = status
        if isAuthorized(status: status) {
            loadCalendars()
            fetchEvents()
        }
    }

    public func isAuthorized(status: EKAuthorizationStatus? = nil) -> Bool {
        let st = status ?? EKEventStore.authorizationStatus(for: .event)
        return st == .fullAccess
    }

    // macOS 15+ Full Access 권한 요청
    public func requestAccess() {
        eventStore.requestFullAccessToEvents { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = L10n.tr(.permissionRequestFailed(error.localizedDescription))
                }
                self?.checkAuthorizationStatus()
            }
        }
    }

    // macOS 시스템 설정 개인정보 보호 > 캘린더 화면 딥링크 오픈
    public static func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - 4. 캘린더 목록 및 일정 비동기 조회 (Data Fetching)
extension CalendarService {
    // 등록된 모든 캘린더 목록 및 소스 계정별 그룹 로드
    public func loadCalendars() {
        guard isAuthorized() else { return }

        fetchSerialQueue.async { [weak self] in
            guard let self = self else { return }
            let allCalendars = self.eventStore.calendars(for: .event)
            var grouped: [String: (sourceTitle: String, calendars: [CalendarInfo])] = [:]

            for cal in allCalendars {
                let srcId = cal.source?.sourceIdentifier ?? "local"
                let srcTitle = (cal.source?.title.isEmpty == false) ? (cal.source?.title ?? L10n.tr(.otherSource)) : L10n.tr(.otherSource)

                let color: Color
                if let cg = cal.cgColor {
                    color = Color(cgColor: cg)
                } else {
                    color = .blue
                }

                let info = CalendarInfo(
                    id: cal.calendarIdentifier,
                    title: cal.title,
                    defaultColor: color,
                    sourceTitle: srcTitle
                )

                if grouped[srcId] != nil {
                    grouped[srcId]?.calendars.append(info)
                } else {
                    grouped[srcId] = (sourceTitle: srcTitle, calendars: [info])
                }
            }

            let sortedGroups = grouped.map { (key, val) in
                CalendarSourceGroup(
                    id: key,
                    title: val.sourceTitle,
                    calendars: val.calendars.sorted(by: { $0.title.localizedCompare($1.title) == .orderedAscending })
                )
            }.sorted(by: { $0.title.localizedCompare($1.title) == .orderedAscending })

            DispatchQueue.main.async {
                self.sourceGroups = sortedGroups
            }
        }
    }

    // 지정 기준일(당일) 활성 캘린더 이벤트 비동기 조회
    public func fetchEvents(for baseDate: Date = Date(), settings: AppSettings = .shared) {
        guard isAuthorized() else { return }

        // 메인 스레드 가시성 스냅샷으로 데이터 레이스 차단
        let visibilitySnapshot = settings.calendarVisibility

        fetchSerialQueue.async { [weak self] in
            guard let self = self else { return }
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: baseDate)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }

            let activeCalendars = self.eventStore.calendars(for: .event).filter { cal in
                visibilitySnapshot[cal.calendarIdentifier] ?? true
            }

            let predicate = self.eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: activeCalendars)
            let rawEvents = self.eventStore.events(matching: predicate)

            let filtered = rawEvents.compactMap { ekEvent -> CalendarEvent? in
                if ekEvent.status == .canceled {
                    return nil
                }
                return CalendarEvent(from: ekEvent)
            }.sorted { $0.startDate < $1.startDate }

            DispatchQueue.main.async {
                self.events = filtered
            }
        }
    }
}

// MARK: - 5. 시스템 알림 및 백그라운드 동기화 옵저버 (Combine Observers)
extension CalendarService {
    // 시스템 캘린더 변경 알림, 절전/복귀 전원 이벤트 및 주기적 갱신 타이머 등록
    private func setupEventStoreObserver() {
        // 1. 시스템 캘린더 DB 변경 감지
        NotificationCenter.default.publisher(for: .EKEventStoreChanged, object: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, !self.isSleeping else { return }
                self.loadCalendars()
                self.fetchEvents()
            }
            .store(in: &cancellables)

        // 2. 캘린더 가시성 설정 변경 시 디바운스 갱신
        AppSettings.shared.$calendarVisibility
            .map { _ in () }
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, !self.isSleeping else { return }
                self.fetchEvents()
            }
            .store(in: &cancellables)

        // 3. 백그라운드 5분(300초) 주기 보조 갱신 (실시간 변경은 EKEventStoreChangedNotification으로 즉시 0초 반영됨)
        Timer.publish(every: 300, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, !self.isSleeping else { return }
                self.fetchEvents()
            }
            .store(in: &cancellables)

        // 4. 자정(00:00) 경과 시 당일 기준일 리셋 및 최신 일정 갱신
        NotificationCenter.default.publisher(for: .NSCalendarDayChanged, object: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, !self.isSleeping else { return }
                self.loadCalendars()
                self.fetchEvents()
            }
            .store(in: &cancellables)

        // 5. 전원 절전(Sleep/화면보호기) 진입 시 백그라운드 쿼리 일시정지
        let wsCenter = NSWorkspace.shared.notificationCenter
        Publishers.Merge(
            wsCenter.publisher(for: NSWorkspace.willSleepNotification),
            wsCenter.publisher(for: NSWorkspace.screensDidSleepNotification)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.isSleeping = true
            PopoverPanel.shared.hide()
        }
        .store(in: &cancellables)

        // 6. 전원 복귀(Wake/화면 켜짐/잠금 해제) 시 즉시 1회 강제 동기화 (디바운스로 중복 방지)
        Publishers.Merge(
            wsCenter.publisher(for: NSWorkspace.didWakeNotification),
            wsCenter.publisher(for: NSWorkspace.screensDidWakeNotification)
        )
        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            guard let self = self else { return }
            self.isSleeping = false
            self.loadCalendars()
            self.fetchEvents()
        }
        .store(in: &cancellables)
    }
}

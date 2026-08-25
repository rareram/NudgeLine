// EventKit 기반 시스템 캘린더 연동 및 실시간 일정 동기화 서비스
import Foundation
import EventKit
import SwiftUI
import Combine

// 개별 캘린더 메타데이터 모델
public struct CalendarInfo: Identifiable {
    public let id: String
    public let title: String
    public let defaultColor: Color
    public let sourceTitle: String
    public let allowsContentModifications: Bool
}

// 캘린더 계정별 그룹 모델 (iCloud, Google, Exchange 등)
public struct CalendarSourceGroup: Identifiable {
    public let id: String
    public let title: String
    public var calendars: [CalendarInfo]
}

public final class CalendarService: ObservableObject {
    public static let shared = CalendarService()

    private let eventStore = EKEventStore()
    private var cancellables = Set<AnyCancellable>()

    @Published public private(set) var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published public private(set) var events: [CalendarEvent] = []
    @Published public private(set) var sourceGroups: [CalendarSourceGroup] = []
    @Published public private(set) var lastRefreshedAt: Date = Date()
    @Published public var errorMessage: String? = nil

    private init() {
        checkAuthorizationStatus()
        setupEventStoreObserver()
    }

    // 캘린더 TCC 권한 상태 확인 및 자동 데이터 로드
    public func checkAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        DispatchQueue.main.async {
            self.authorizationStatus = status
            if self.isAuthorized(status: status) {
                self.loadCalendars()
                self.fetchEvents()
            }
        }
    }

    public func isAuthorized(status: EKAuthorizationStatus? = nil) -> Bool {
        let st = status ?? authorizationStatus
        if #available(macOS 14.0, *) {
            return st == .fullAccess
        } else {
            return st == .authorized
        }
    }

    // macOS 14+ Full Access 권한 요청
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

    // 등록된 모든 캘린더 목록 및 소스 계정별 그룹 로드
    public func loadCalendars() {
        guard isAuthorized() else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
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
                    sourceTitle: srcTitle,
                    allowsContentModifications: cal.allowsContentModifications
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

    private let fetchSerialQueue = DispatchQueue(label: "com.nudgeline.fetchSerialQueue", qos: .userInitiated)

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
                self.lastRefreshedAt = Date()
            }
        }
    }

    // 시스템 캘린더 변경 알림 및 주기적 갱신 타이머 등록
    private func setupEventStoreObserver() {
        // 1. 시스템 캘린더 DB 변경 감지
        NotificationCenter.default.publisher(for: .EKEventStoreChanged, object: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadCalendars()
                self?.fetchEvents()
            }
            .store(in: &cancellables)

        // 2. 캘린더 가시성 설정 변경 시 디바운스 갱신
        AppSettings.shared.$calendarVisibility
            .map { _ in () }
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.fetchEvents()
            }
            .store(in: &cancellables)

        // 3. 백그라운드 30초 주기 자동 갱신
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchEvents()
            }
            .store(in: &cancellables)
    }
}

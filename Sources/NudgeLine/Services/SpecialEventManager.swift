// 스케줄 기반 특수 이벤트 및 넛지 시리즈 간 공유 상태 관리자
import Foundation

// MARK: - 1. 스케줄 활성 시간 범위 규격 (Schedule Time Window)
// 단일 날짜 종일, 야간 윈도우(19:00~익일 07:00), 연말-연초(Cross-Year) 날짜 범위 등 다채로운 스케줄 윈도우를 정의합니다.
public enum SpecialEventScheduleWindow: Sendable, Equatable {
    /// 특정 월/일 종일 (00:00:00 ~ 23:59:59)
    case allDay(month: Int, day: Int)
    /// 특정 월/일 저녁부터 익일 아침까지 (기본: 19:00 ~ 익일 07:00)
    case overnight(month: Int, day: Int, startHour: Int = 19, endHour: Int = 7)
    /// 특정 월/일 ~ 특정 월/일 기간 범위 (종일)
    case dateRange(startMonth: Int, startDay: Int, endMonth: Int, endDay: Int)
    /// 상시 비활성화 (개발/테스트/유휴용)
    case disabled

    /// 지정된 기준 시각에 해당 스케줄 윈도우가 열려 있는지 판정합니다.
    public func isActive(at date: Date = Date(), calendar: Calendar = Calendar.current) -> Bool {
        switch self {
        case .disabled:
            return false

        case .allDay(let m, let d):
            let comps = calendar.dateComponents([.month, .day], from: date)
            return comps.month == m && comps.day == d

        case .overnight(let m, let d, let startHour, let endHour):
            let comps = calendar.dateComponents([.month, .day, .hour], from: date)
            guard let month = comps.month, let day = comps.day, let hour = comps.hour else { return false }

            // 1) 당일 야간 윈도우 (m월 d일 startHour시 ~ 23시 59분)
            if month == m && day == d && hour >= startHour {
                return true
            }
            // 2) 익일 아침 윈도우 (m월 d+1일 00시 ~ endHour시 이전)
            if let prevDay = calendar.date(byAdding: .day, value: -1, to: date) {
                let prevComps = calendar.dateComponents([.month, .day], from: prevDay)
                if prevComps.month == m && prevComps.day == d && hour < endHour {
                    return true
                }
            }
            return false

        case .dateRange(let sm, let sd, let em, let ed):
            let comps = calendar.dateComponents([.month, .day], from: date)
            guard let month = comps.month, let day = comps.day else { return false }
            let currentMD = month * 100 + day
            let startMD = sm * 100 + sd
            let endMD = em * 100 + ed
            if startMD <= endMD {
                return currentMD >= startMD && currentMD <= endMD
            } else {
                // 연말에서 연초로 이어지는 구간(Cross-Year, 예: 12/25 ~ 01/05) 지원
                return currentMD >= startMD || currentMD <= endMD
            }
        }
    }
}

// MARK: - 2. 모듈형 특수 이벤트 묶음 규격 (Event Bundle Model)
// 하나의 특수 이벤트가 복수의 스케줄 윈도우 목록(schedules)을 소유하여, 이벤트 종류별로 활성 일정을 체계적으로 그룹화합니다.
public struct SpecialEventDefinition: Identifiable, Sendable {
    /// 이벤트 묶음 고유 식별자 (예: "special_event_1")
    public let id: String
    /// 이벤트 활성 시간 윈도우 목록 (다중 일자 묶음)
    public let schedules: [SpecialEventScheduleWindow]
    /// 해당 이벤트 발동 시 히든 로케일 해금 여부
    public let unlocksHiddenLanguage: Bool
    /// 연동 비주얼 효과 키 (옵션)
    public let customEffectKey: String?

    public init(
        id: String,
        schedules: [SpecialEventScheduleWindow],
        unlocksHiddenLanguage: Bool = false,
        customEffectKey: String? = nil
    ) {
        self.id = id
        self.schedules = schedules
        self.unlocksHiddenLanguage = unlocksHiddenLanguage
        self.customEffectKey = customEffectKey
    }

    /// 보유한 스케줄 윈도우 중 하나라도 현재 활성화되어 있는지 검사합니다.
    public func isActive(at date: Date = Date(), calendar: Calendar = Calendar.current) -> Bool {
        return schedules.contains { $0.isActive(at: date, calendar: calendar) }
    }
}

// MARK: - 3. 넛지 시리즈 간 공유 이벤트 상태 규격 (NudgeSeries Shared State)
// NudgeLine(본체)과 NudgeSaver(화면보호기) 등 패밀리 앱 간에 현재 이벤트 및 세션 상태를 동기화하기 위한 표준 스냅샷 규격입니다.
public struct NudgeSeriesSharedEventState: Codable, Sendable, Equatable {
    /// 현재 활성화된 특수 이벤트 ID (비활성 시 nil)
    public let activeEventId: String?
    /// 연동 비주얼 효과 키 (예: "special_badge_glow", "paw_prints")
    public let customEffectKey: String?
    /// 기본 특수 세션(아이콘 7회 클릭 발자국 등) 활성화 여부
    public let isSpecialSessionUnlocked: Bool
    /// 현재 시점의 히든 언어 활성화 가능 여부
    public let isHiddenLanguageAvailable: Bool
    /// 세션 초기화(파괴) 여부
    public let isSessionDismissed: Bool
    /// 상태 스냅샷 생성 시각
    public let timestamp: Date

    public init(
        activeEventId: String?,
        customEffectKey: String?,
        isSpecialSessionUnlocked: Bool,
        isHiddenLanguageAvailable: Bool,
        isSessionDismissed: Bool,
        timestamp: Date = Date()
    ) {
        self.activeEventId = activeEventId
        self.customEffectKey = customEffectKey
        self.isSpecialSessionUnlocked = isSpecialSessionUnlocked
        self.isHiddenLanguageAvailable = isHiddenLanguageAvailable
        self.isSessionDismissed = isSessionDismissed
        self.timestamp = timestamp
    }
}

// MARK: - 4. 특수 이벤트 총괄 레지스트리 (SpecialEventManager)
// 이벤트 묶음 목록을 등록 관리하고, 현재 시점의 활성 상태 판정 및 넛지 시리즈 간 IPC 브로드캐스트를 총괄합니다.
public final class SpecialEventManager: ObservableObject, @unchecked Sendable {
    public static let shared = SpecialEventManager()

    /// 넛지 시리즈 공유 App Group 식별자 및 Darwin Notification 이름
    public static let sharedAppGroupSuite = "group.com.rareram.nudge"
    public static let sharedStorageKey = "nudge_series_shared_event_state"
    public static let sharedNotificationName = "com.rareram.nudge.eventStateChanged"

    /// 등록된 특수 이벤트 묶음 목록
    public var registeredEvents: [SpecialEventDefinition] = [
        // 특수 이벤트 1: 비밀 판타지 언어 및 황금 룬 배지 묶음 (다중 시즌 윈도우 스케줄)
        SpecialEventDefinition(
            id: "special_event_1",
            schedules: [
                .overnight(month: 3, day: 25, startHour: 19, endHour: 7), // 봄 야간 윈도우
                .allDay(month: 9, day: 22),                                // 가을 종일 윈도우
                .allDay(month: 1, day: 3)                                  // 겨울 종일 윈도우
            ],
            unlocksHiddenLanguage: true,
            customEffectKey: "special_badge_glow"
        )
    ]

    private init() {}

    /// 특정 시점에 활성화된 이벤트 묶음 목록을 반환합니다.
    public func activeEvents(at date: Date = Date(), calendar: Calendar = Calendar.current) -> [SpecialEventDefinition] {
        return registeredEvents.filter { $0.isActive(at: date, calendar: calendar) }
    }

    /// 현재 시점에 특정 히든 언어 활성화 가능 여부를 판정합니다.
    public func isHiddenLanguageUnlocked(at date: Date = Date(), calendar: Calendar = Calendar.current) -> Bool {
        return activeEvents(at: date, calendar: calendar).contains { $0.unlocksHiddenLanguage }
    }

    /// NudgeSaver 등 다른 넛지 시리즈 앱과 공유할 최신 상태 스냅샷을 생성합니다.
    public func createSharedSnapshot(
        at date: Date = Date(),
        isSpecialSessionUnlocked: Bool = false,
        isSessionDismissed: Bool = false,
        calendar: Calendar = Calendar.current
    ) -> NudgeSeriesSharedEventState {
        let active = activeEvents(at: date, calendar: calendar).first
        let isLangAvailable = (!isSessionDismissed) && isHiddenLanguageUnlocked(at: date, calendar: calendar)
        let effectKey = active?.customEffectKey ?? (isSpecialSessionUnlocked ? "paw_prints" : nil)

        return NudgeSeriesSharedEventState(
            activeEventId: active?.id,
            customEffectKey: effectKey,
            isSpecialSessionUnlocked: isSpecialSessionUnlocked,
            isHiddenLanguageAvailable: isLangAvailable,
            isSessionDismissed: isSessionDismissed,
            timestamp: date
        )
    }

    /// App Group 공유 컨테이너에 상태를 기록하고, NudgeSaver 화면보호기 등 다른 프로세스에 상태 변경 알림을 전달합니다.
    public func broadcastSharedState(_ snapshot: NudgeSeriesSharedEventState) {
        let defaults = UserDefaults(suiteName: Self.sharedAppGroupSuite) ?? UserDefaults.standard
        if let encoded = try? JSONEncoder().encode(snapshot) {
            defaults.set(encoded, forKey: Self.sharedStorageKey)
        }

        // Darwin Notification Center를 통한 프로세스 간 실시간 알림 발송
        let notificationName = CFNotificationName(Self.sharedNotificationName as CFString)
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, nil, nil, true)
    }
}

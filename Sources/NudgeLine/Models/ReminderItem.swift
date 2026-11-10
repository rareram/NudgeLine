// Apple 미리알림(EKReminder) 기반 당일 시점(Point) 알림 아이템 모델
import Foundation
import SwiftUI
import EventKit

// MARK: - 1. 미리알림 아이템 모델 (ReminderItem)
public struct ReminderItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let dueDate: Date
    public let listIdentifier: String
    public let listTitle: String
    public let color: Color
    public let notes: String?
    public let url: URL?
    public let priority: Int
    public let isCompleted: Bool
    public let isAllDay: Bool
    public let recurrenceRule: String?

    // 당일 마감 할 일 누락 방지: hour/minute 필수 검사 완화 및 isAllDay 분기
    public init?(from ekReminder: EKReminder, calendar: Calendar = .current) {
        let itemID = ekReminder.calendarItemIdentifier
        let rawTitle = (ekReminder.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !itemID.isEmpty,
              !rawTitle.isEmpty,
              !ekReminder.isCompleted,
              var dueComponents = ekReminder.dueDateComponents else {
            return nil
        }

        // 타임존 정보가 없는 날짜 전용 이벤트(종일 미리알림 등)는 로컬 타임존 기준으로 보정
        if dueComponents.timeZone == nil {
            dueComponents.timeZone = calendar.timeZone
        }

        guard let date = calendar.date(from: dueComponents) else {
            return nil
        }

        let hasTime = (dueComponents.hour != nil && dueComponents.minute != nil)
        self.id = itemID
        self.title = rawTitle
        self.dueDate = hasTime ? date : calendar.startOfDay(for: date)
        self.isAllDay = !hasTime
        self.listIdentifier = ekReminder.calendar?.calendarIdentifier ?? "unknown"
        self.listTitle = ekReminder.calendar?.title ?? ""
        if let cgColor = ekReminder.calendar?.cgColor {
            self.color = Color(cgColor: cgColor)
        } else {
            self.color = .orange
        }
        self.notes = ekReminder.notes?.strippingHTMLTags()
        self.url = ekReminder.url
        self.priority = ekReminder.priority
        self.isCompleted = ekReminder.isCompleted

        if ekReminder.hasRecurrenceRules, let rule = ekReminder.recurrenceRules?.first {
            switch rule.frequency {
            case .daily: self.recurrenceRule = "daily"
            case .weekly: self.recurrenceRule = "weekly"
            case .monthly: self.recurrenceRule = "monthly"
            case .yearly: self.recurrenceRule = "yearly"
            @unknown default: self.recurrenceRule = "custom"
            }
        } else {
            self.recurrenceRule = nil
        }
    }

    public init(
        id: String = UUID().uuidString,
        title: String,
        dueDate: Date,
        listIdentifier: String = "default",
        listTitle: String = "Reminders",
        color: Color = .orange,
        notes: String? = nil,
        url: URL? = nil,
        priority: Int = 0,
        isCompleted: Bool = false,
        isAllDay: Bool = false,
        recurrenceRule: String? = nil
    ) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.listIdentifier = listIdentifier
        self.listTitle = listTitle
        self.color = color
        self.notes = notes
        self.url = url
        self.priority = priority
        self.isCompleted = isCompleted
        self.isAllDay = isAllDay
        self.recurrenceRule = recurrenceRule
    }

    public func recurrenceText(isKorean: Bool) -> String? {
        guard let rule = recurrenceRule else { return nil }
        switch rule {
        case "daily": return isKorean ? "매일" : "Daily"
        case "weekly": return isKorean ? "매주" : "Weekly"
        case "monthly": return isKorean ? "매월" : "Monthly"
        case "yearly": return isKorean ? "매년" : "Yearly"
        default: return isKorean ? "반복" : "Recurring"
        }
    }

    // 타임라인 바 간섭 차단: isAllDay 항목 가시 범위 판정에서 제외 (바 위 마커 노출 억제)
    // 다가오는 미래 접근 구간(0 <= diffMinutes <= proximityMinutes)에만 심볼/펫 먹이로 팝업 노출
    public func isWithinVisibilityWindow(
        currentTime: Date,
        proximityMinutes: Int
    ) -> Bool {
        guard !isAllDay else { return false }
        let diffMinutes = dueDate.timeIntervalSince(currentTime) / 60.0
        guard diffMinutes >= 0 else { return false }
        guard proximityMinutes < 1440 else { return true }
        return diffMinutes <= Double(proximityMinutes)
    }
}

// MARK: - 2. 미리알림 목록(List/Calendar) 메타데이터 모델
public struct ReminderListInfo: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let color: Color
    public let sourceTitle: String

    public init(id: String, title: String, color: Color, sourceTitle: String) {
        self.id = id
        self.title = title
        self.color = color
        self.sourceTitle = sourceTitle
    }
}

// MARK: - 3. 마커 미리보기 노티피케이션
// 설정 변경 시 타임라인 마커를 즉시 미리보기하기 위한 알림
extension Notification.Name {
    public static let previewReminderMarker = Notification.Name("NudgeLine.previewReminderMarker")
}

// MARK: - 4. 미리알림 링크 정보 모델 및 3단계 안전 판별 파서
public struct ReminderLinkInfo: Equatable, Sendable {
    public let url: URL
    public let displayText: String
    public let iconName: String
    public let isUnverified: Bool

    public init(url: URL, displayText: String, iconName: String, isUnverified: Bool) {
        self.url = url
        self.displayText = displayText
        self.iconName = iconName
        self.isUnverified = isUnverified
    }
}

public enum ReminderLinkParser {
    public static func parse(reminder: ReminderItem, language: AppLanguage) -> ReminderLinkInfo? {
        let candidate: URL? = reminder.url ?? {
            guard let notes = reminder.notes, !notes.isEmpty,
                  let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
                  let match = detector.firstMatch(in: notes, options: [], range: NSRange(location: 0, length: (notes as NSString).length)) else {
                return nil
            }
            return match.url
        }()

        guard let rawUrl = candidate,
              let scheme = rawUrl.scheme?.lowercased(),
              !scheme.isEmpty else {
            return nil
        }

        // 1단계: 보안상 유해한 위험 스킴 원천 배제 (로컬 파일 임의 실행 및 스크립트 인젝션 차단)
        let blockedSchemes: Set<String> = ["file", "javascript", "applescript", "data", "blob", "help", "disk"]
        if blockedSchemes.contains(scheme) {
            return nil
        }

        // 2단계: 표준 웹 링크 (http, https) -> 도메인 호스트명 추출
        if scheme == "http" || scheme == "https" {
            let host = CalendarEvent.extractDisplayHost(from: rawUrl)
            return ReminderLinkInfo(url: rawUrl, displayText: host, iconName: "link", isUnverified: false)
        }

        // 3단계: 잘 알려진 macOS 시스템 및 생산성 앱 딥링크
        let isKo = language.isKorean
        switch scheme {
        case "message":
            return ReminderLinkInfo(url: rawUrl, displayText: isKo ? "메일" : "Mail", iconName: "envelope", isUnverified: false)
        case "notes":
            return ReminderLinkInfo(url: rawUrl, displayText: isKo ? "메모" : "Notes", iconName: "note.text", isUnverified: false)
        case "notion":
            return ReminderLinkInfo(url: rawUrl, displayText: "Notion", iconName: "doc.text", isUnverified: false)
        case "slack":
            return ReminderLinkInfo(url: rawUrl, displayText: "Slack", iconName: "bubble.left.and.bubble.right", isUnverified: false)
        case "things":
            return ReminderLinkInfo(url: rawUrl, displayText: "Things", iconName: "checkmark.square", isUnverified: false)
        case "obsidian":
            return ReminderLinkInfo(url: rawUrl, displayText: "Obsidian", iconName: "doc.plaintext", isUnverified: false)
        case "bear":
            return ReminderLinkInfo(url: rawUrl, displayText: "Bear", iconName: "doc.text", isUnverified: false)
        case "linear":
            return ReminderLinkInfo(url: rawUrl, displayText: "Linear", iconName: "arrow.up.right.square", isUnverified: false)
        case "figma":
            return ReminderLinkInfo(url: rawUrl, displayText: "Figma", iconName: "pencil.and.outline", isUnverified: false)
        case "x-apple-reminderkit":
            return ReminderLinkInfo(url: rawUrl, displayText: isKo ? "미리알림" : "Reminders", iconName: "list.bullet", isUnverified: false)
        default:
            // 4단계: 관리 리스트에 없는 기타 외부 딥링크 -> '외부 앱 (스킴명)'으로 투명하게 표시
            let label = isKo ? "외부 앱 (\(scheme))" : "App Link (\(scheme))"
            return ReminderLinkInfo(url: rawUrl, displayText: label, iconName: "arrow.up.forward.app", isUnverified: true)
        }
    }
}

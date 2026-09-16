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

    public init?(from ekReminder: EKReminder, calendar: Calendar = .current) {
        let itemID = ekReminder.calendarItemIdentifier
        guard !itemID.isEmpty,
              !ekReminder.isCompleted,
              let dueComponents = ekReminder.dueDateComponents,
              dueComponents.hour != nil,
              dueComponents.minute != nil,
              let date = calendar.date(from: dueComponents) else {
            return nil
        }

        self.id = itemID
        self.title = (ekReminder.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        self.dueDate = date
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
        isCompleted: Bool = false
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

// MARK: - 3. 미리알림 마커 미리보기 노티피케이션
// [배경: 설정창에서 마커 스타일 변경 시 타임라인 즉각 피드백 제공 -> 해결: 노티피케이션 이벤트 디스패치 -> 기대효과: 무간섭 비동기 프리뷰 트리거]
extension Notification.Name {
    public static let previewReminderMarker = Notification.Name("NudgeLine.previewReminderMarker")
}

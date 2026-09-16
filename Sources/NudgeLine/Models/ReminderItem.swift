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
        let rawTitle = (ekReminder.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !itemID.isEmpty,
              !rawTitle.isEmpty,
              !ekReminder.isCompleted,
              let dueComponents = ekReminder.dueDateComponents,
              dueComponents.hour != nil,
              dueComponents.minute != nil,
              let date = calendar.date(from: dueComponents) else {
            return nil
        }

        self.id = itemID
        self.title = rawTitle
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

    // MARK: - 가시 범위 판정
    // 렌더링과 호버 감지에 동일한 표시 기준을 유지하기 위한 범위 확인
    public func isWithinVisibilityWindow(
        currentTime: Date,
        proximityMinutes: Int
    ) -> Bool {
        guard proximityMinutes < 1440 else { return true }
        let diffMinutes = dueDate.timeIntervalSince(currentTime) / 60.0
        return diffMinutes <= Double(proximityMinutes) && diffMinutes >= -10.0
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

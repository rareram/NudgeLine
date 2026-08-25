// 팝오버 렌더링 스킨 프로토콜 및 구현체 (상세 카드 / 초경량 툴팁)
import SwiftUI
import AppKit

// 팝오버 호버 스타일 렌더러 인터페이스
public protocol EventHoverStyleRenderer {
    // 팝오버 내부 SwiftUI 뷰 생성
    func makeView(
        events: [CalendarEvent],
        settings: AppSettings
    ) -> AnyView

    // 카드 및 툴팁 크기(너비, 높이) 계산
    func targetSize(
        events: [CalendarEvent],
        isHorizontal: Bool
    ) -> (width: CGFloat, height: CGFloat)

    // 마우스 이동 브릿지 지원 여부 (상세 카드 true, 심플 툴팁 false)
    var allowsTransitBridge: Bool { get }
}

// MARK: - 1. 상세 액션 카드 렌더러
public struct DetailCardHoverRenderer: EventHoverStyleRenderer {
    public init() {}

    public func makeView(
        events: [CalendarEvent],
        settings: AppSettings
    ) -> AnyView {
        AnyView(EventPopoverView(events: events, settings: settings))
    }

    public func targetSize(
        events: [CalendarEvent],
        isHorizontal: Bool
    ) -> (width: CGFloat, height: CGFloat) {
        let isMulti = events.count > 1
        let maxTitleLength = events.map { $0.title.count }.max() ?? 8
        let estimatedWidth = CGFloat(110 + maxTitleLength * 8)
        let width: CGFloat = max(220.0, min(280.0, estimatedWidth)) + (isHorizontal ? 0 : 8.0)
        let height: CGFloat = (isMulti ? (CGFloat(events.count) * 75.0 + 40.0) : 135.0) + (isHorizontal ? 8.0 : 0)
        return (width, height)
    }

    public var allowsTransitBridge: Bool { true }
}

// MARK: - 2. 초경량 요약 툴팁 렌더러
public struct SimpleInfoHoverRenderer: EventHoverStyleRenderer {
    public init() {}

    public func makeView(
        events: [CalendarEvent],
        settings: AppSettings
    ) -> AnyView {
        AnyView(SimpleInfoPopoverView(events: events, settings: settings))
    }

    public func targetSize(
        events: [CalendarEvent],
        isHorizontal: Bool
    ) -> (width: CGFloat, height: CGFloat) {
        let maxTitleLength = events.map { $0.title.count }.max() ?? 6
        let estimatedWidth = CGFloat(65 + maxTitleLength * 9)
        let clampedWidth = max(135.0, min(260.0, estimatedWidth)) + (isHorizontal ? 0 : 8.0)

        let isMulti = events.count > 1
        let rowHeight: CGFloat = 34.0
        let height: CGFloat = CGFloat(events.count) * rowHeight + (isMulti ? 14.0 : 8.0) + (isHorizontal ? 8.0 : 0)
        return (clampedWidth, height)
    }

    public var allowsTransitBridge: Bool { false }
}

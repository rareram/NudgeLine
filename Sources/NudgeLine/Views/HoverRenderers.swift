// 팝오버 렌더링 스킨 프로토콜, 공통 블러/말풍선 Shape 및 구현체
import SwiftUI
import AppKit

// MARK: - 1. macOS 네이티브 블러 래퍼 뷰 (VisualEffectBlur)
public struct VisualEffectBlur: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var state: NSVisualEffectView.State

    public init(
        material: NSVisualEffectView.Material = .popover,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.autoresizingMask = [.width, .height]
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - 2. 팝오버 말풍선 꼬리 방향 및 기하 Shape (SpeechBubbleShape)
public enum BubbleArrowDirection: Sendable {
    case left
    case right
    case bottom
    case none
}

public struct SpeechBubbleShape: Shape {
    public var direction: BubbleArrowDirection
    public var arrowWidth: CGFloat = 8
    public var arrowHeight: CGFloat = 14
    public var cornerRadius: CGFloat = 8
    public var arrowOffsetPercent: CGFloat = 0.5

    public init(
        direction: BubbleArrowDirection,
        arrowWidth: CGFloat = 8,
        arrowHeight: CGFloat = 14,
        cornerRadius: CGFloat = 8,
        arrowOffsetPercent: CGFloat = 0.5
    ) {
        self.direction = direction
        self.arrowWidth = arrowWidth
        self.arrowHeight = arrowHeight
        self.cornerRadius = cornerRadius
        self.arrowOffsetPercent = arrowOffsetPercent
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = cornerRadius

        switch direction {
        case .left:
            let bodyRect = CGRect(x: rect.minX + arrowWidth, y: rect.minY, width: rect.width - arrowWidth, height: rect.height)
            let arrowMidY = bodyRect.minY + (bodyRect.height * arrowOffsetPercent)
            let arrowHalfH = arrowHeight / 2

            path.move(to: CGPoint(x: bodyRect.minX + r, y: bodyRect.minY))
            path.addLine(to: CGPoint(x: bodyRect.maxX - r, y: bodyRect.minY))
            path.addArc(center: CGPoint(x: bodyRect.maxX - r, y: bodyRect.minY + r), radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: bodyRect.maxX, y: bodyRect.maxY - r))
            path.addArc(center: CGPoint(x: bodyRect.maxX - r, y: bodyRect.maxY - r), radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: bodyRect.minX + r, y: bodyRect.maxY))
            path.addArc(center: CGPoint(x: bodyRect.minX + r, y: bodyRect.maxY - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)

            // 타임라인 바를 향하는 좌측 화살표 꼬리
            path.addLine(to: CGPoint(x: bodyRect.minX, y: min(bodyRect.maxY - r, arrowMidY + arrowHalfH)))
            path.addLine(to: CGPoint(x: rect.minX, y: arrowMidY))
            path.addLine(to: CGPoint(x: bodyRect.minX, y: max(bodyRect.minY + r, arrowMidY - arrowHalfH)))

            path.addLine(to: CGPoint(x: bodyRect.minX, y: bodyRect.minY + r))
            path.addArc(center: CGPoint(x: bodyRect.minX + r, y: bodyRect.minY + r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            path.closeSubpath()

        case .right:
            let bodyRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width - arrowWidth, height: rect.height)
            let arrowMidY = bodyRect.minY + (bodyRect.height * arrowOffsetPercent)
            let arrowHalfH = arrowHeight / 2

            path.move(to: CGPoint(x: bodyRect.minX + r, y: bodyRect.minY))
            path.addLine(to: CGPoint(x: bodyRect.maxX - r, y: bodyRect.minY))
            path.addArc(center: CGPoint(x: bodyRect.maxX - r, y: bodyRect.minY + r), radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)

            // 우측 화살표 꼬리
            path.addLine(to: CGPoint(x: bodyRect.maxX, y: max(bodyRect.minY + r, arrowMidY - arrowHalfH)))
            path.addLine(to: CGPoint(x: rect.maxX, y: arrowMidY))
            path.addLine(to: CGPoint(x: bodyRect.maxX, y: min(bodyRect.maxY - r, arrowMidY + arrowHalfH)))

            path.addLine(to: CGPoint(x: bodyRect.maxX, y: bodyRect.maxY - r))
            path.addArc(center: CGPoint(x: bodyRect.maxX - r, y: bodyRect.maxY - r), radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: bodyRect.minX + r, y: bodyRect.maxY))
            path.addArc(center: CGPoint(x: bodyRect.minX + r, y: bodyRect.maxY - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: bodyRect.minX, y: bodyRect.minY + r))
            path.addArc(center: CGPoint(x: bodyRect.minX + r, y: bodyRect.minY + r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            path.closeSubpath()

        case .bottom:
            let bodyRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - arrowWidth)
            let arrowMidX = bodyRect.minX + (bodyRect.width * arrowOffsetPercent)
            let arrowHalfW = arrowHeight / 2

            path.move(to: CGPoint(x: bodyRect.minX + r, y: bodyRect.minY))
            path.addLine(to: CGPoint(x: bodyRect.maxX - r, y: bodyRect.minY))
            path.addArc(center: CGPoint(x: bodyRect.maxX - r, y: bodyRect.minY + r), radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: bodyRect.maxX, y: bodyRect.maxY - r))
            path.addArc(center: CGPoint(x: bodyRect.maxX - r, y: bodyRect.maxY - r), radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)

            // 하단 화살표 꼬리
            path.addLine(to: CGPoint(x: min(bodyRect.maxX - r, arrowMidX + arrowHalfW), y: bodyRect.maxY))
            path.addLine(to: CGPoint(x: arrowMidX, y: rect.maxY))
            path.addLine(to: CGPoint(x: max(bodyRect.minX + r, arrowMidX - arrowHalfW), y: bodyRect.maxY))

            path.addLine(to: CGPoint(x: bodyRect.minX + r, y: bodyRect.maxY))
            path.addArc(center: CGPoint(x: bodyRect.minX + r, y: bodyRect.maxY - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: bodyRect.minX, y: bodyRect.minY + r))
            path.addArc(center: CGPoint(x: bodyRect.minX + r, y: bodyRect.minY + r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            path.closeSubpath()

        case .none:
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: r, height: r))
        }

        return path
    }
}

// MARK: - 3. 팝오버 호버 스타일 렌더러 인터페이스 (EventHoverStyleRenderer)
public protocol EventHoverStyleRenderer {
    func makeView(
        events: [CalendarEvent],
        settings: AppSettings
    ) -> AnyView

    func targetSize(
        events: [CalendarEvent],
        isHorizontal: Bool
    ) -> (width: CGFloat, height: CGFloat)

    var allowsTransitBridge: Bool { get }
}

// MARK: - 4. 상세 액션 카드 렌더러 구현체
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
        let maxTitleLength = events.map { $0.rawTitle.count }.max() ?? 8
        let estimatedWidth = CGFloat(110 + maxTitleLength * 8)
        let width: CGFloat = max(220.0, min(280.0, estimatedWidth)) + (isHorizontal ? 0 : 8.0)
        let height: CGFloat = (isMulti ? (CGFloat(events.count) * 75.0 + 40.0) : 135.0) + (isHorizontal ? 8.0 : 0)
        return (width, height)
    }

    public var allowsTransitBridge: Bool { true }
}

// MARK: - 5. 초경량 요약 툴팁 렌더러 구현체
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
        let maxTitleLength = events.map { $0.rawTitle.count }.max() ?? 6
        let estimatedWidth = CGFloat(65 + maxTitleLength * 9)
        let clampedWidth = max(135.0, min(260.0, estimatedWidth)) + (isHorizontal ? 0 : 8.0)

        let isMulti = events.count > 1
        let rowHeight: CGFloat = 34.0
        let height: CGFloat = CGFloat(events.count) * rowHeight + (isMulti ? 14.0 : 8.0) + (isHorizontal ? 8.0 : 0)
        return (clampedWidth, height)
    }

    public var allowsTransitBridge: Bool { false }
}

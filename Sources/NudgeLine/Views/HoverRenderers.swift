// 팝오버 렌더링 스킨 프로토콜, 공통 말풍선 Shape 및 구현체
import SwiftUI
import AppKit

// MARK: - 1. 팝오버 말풍선 꼬리 방향 및 기하 Shape (SpeechBubbleShape)
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

// MARK: - 2. 팝오버 호버 스타일 렌더러 인터페이스 (EventHoverStyleRenderer)
public protocol EventHoverStyleRenderer {
    func makeView(
        events: [CalendarEvent],
        allDayEvents: [CalendarEvent],
        settings: AppSettings
    ) -> AnyView

    func targetSize(
        events: [CalendarEvent],
        allDayEvents: [CalendarEvent],
        isHorizontal: Bool
    ) -> (width: CGFloat, height: CGFloat)

    var allowsTransitBridge: Bool { get }
}

extension EventHoverStyleRenderer {
    public func makeView(
        events: [CalendarEvent],
        settings: AppSettings
    ) -> AnyView {
        makeView(events: events, allDayEvents: [], settings: settings)
    }

    public func targetSize(
        events: [CalendarEvent],
        isHorizontal: Bool
    ) -> (width: CGFloat, height: CGFloat) {
        targetSize(events: events, allDayEvents: [], isHorizontal: isHorizontal)
    }
}

// MARK: - 3. 상세 액션 카드 렌더러 구현체
public struct DetailCardHoverRenderer: EventHoverStyleRenderer {
    public init() {}

    public func makeView(
        events: [CalendarEvent],
        allDayEvents: [CalendarEvent] = [],
        settings: AppSettings
    ) -> AnyView {
        AnyView(EventPopoverView(events: events, allDayEvents: allDayEvents, settings: settings))
    }

    public func targetSize(
        events: [CalendarEvent],
        allDayEvents: [CalendarEvent] = [],
        isHorizontal: Bool
    ) -> (width: CGFloat, height: CGFloat) {
        let isMulti = events.count > 1
        let maxTitleLength = (events + allDayEvents).map { $0.rawTitle.count }.max() ?? 8
        let estimatedWidth = CGFloat(110 + maxTitleLength * 8)
        let width: CGFloat = max(220.0, min(280.0, estimatedWidth)) + (isHorizontal ? 0 : 8.0)

        // 최대 3개까지만 풀 카드로 렌더링하고 나머지는 축약 칩(28px)으로 처리
        let displayCount = min(3, events.count)
        let hasOverflow = events.count > 3
        let overflowOffset: CGFloat = hasOverflow ? 28.0 : 0.0

        // 종일 일정 1줄 미니 인라인 배지 존재 시 24px 가산
        let allDayBadgeOffset: CGFloat = allDayEvents.isEmpty ? 0.0 : 24.0
        let height: CGFloat = (isMulti ? (CGFloat(displayCount) * 110.0 + 35.0) : 135.0) + allDayBadgeOffset + overflowOffset + (isHorizontal ? 8.0 : 0)
        return (width, height)
    }

    public var allowsTransitBridge: Bool { true }
}

// MARK: - 4. 초경량 요약 툴팁 렌더러 구현체
public struct SimpleInfoHoverRenderer: EventHoverStyleRenderer {
    public init() {}

    public func makeView(
        events: [CalendarEvent],
        allDayEvents: [CalendarEvent] = [],
        settings: AppSettings
    ) -> AnyView {
        AnyView(SimpleInfoPopoverView(events: events, settings: settings))
    }

    public func targetSize(
        events: [CalendarEvent],
        allDayEvents: [CalendarEvent] = [],
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

// MARK: - 5.1 클래식 프로스티드 머티리얼 서피스 (ClassicFrostedSurface)
// 가우시안 블러 머티리얼과 테마 틴트를 결합한 말풍선 형태의 카드 배경
public struct ClassicFrostedSurface: ViewModifier {
    public let shape: SpeechBubbleShape
    public let isDarkTheme: Bool
    public let cardOpacity: Double

    public init(
        shape: SpeechBubbleShape,
        isDarkTheme: Bool,
        cardOpacity: Double
    ) {
        self.shape = shape
        self.isDarkTheme = isDarkTheme
        self.cardOpacity = cardOpacity
    }

    private var tintColor: Color {
        if isDarkTheme {
            return Color.black.opacity(cardOpacity * 0.40)
        } else {
            return Color.white.opacity(cardOpacity * 0.35)
        }
    }

    public func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(cardOpacity), in: shape)
            .background(
                shape
                    .fill(tintColor)
                    .allowsHitTesting(false)
            )
            .clipShape(shape)
            .overlay(
                shape
                    .stroke(isDarkTheme ? Color.white.opacity(0.18) : Color.black.opacity(0.12), lineWidth: 0.5)
                    .allowsHitTesting(false)
            )
            .shadow(color: Color.black.opacity(isDarkTheme ? 0.32 : 0.16), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 5.2 리퀴드 글래스 서피스 (LiquidGlassSurface)
// macOS 26 이상에서 NativeGlassSurface를 적용하고, 이전 버전에서는 시스템 머티리얼로 대체하는 카드 배경 수정자
public struct LiquidGlassSurface: ViewModifier {
    public let cornerRadius: CGFloat
    public let isDarkTheme: Bool

    public init(
        cornerRadius: CGFloat = 14.0,
        isDarkTheme: Bool = false
    ) {
        self.cornerRadius = cornerRadius
        self.isDarkTheme = isDarkTheme
    }

    private var surfaceShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    public func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            NativeGlassSurface(cornerRadius: cornerRadius, isDarkTheme: isDarkTheme) {
                content
            }
        } else {
            content.background(.ultraThinMaterial, in: surfaceShape)
        }
    }
}

// MARK: - 5.2.1 AppKit 글래스 서피스 브릿지 (NativeGlassSurface)
// NSGlassEffectContainerView와 NSGlassEffectView를 SwiftUI 뷰 계층에 연결하는 래퍼
@available(macOS 26.0, *)
public struct NativeGlassSurface<Content: View>: NSViewRepresentable {
    public let cornerRadius: CGFloat
    public let isDarkTheme: Bool
    private let content: Content

    public init(cornerRadius: CGFloat, isDarkTheme: Bool, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.isDarkTheme = isDarkTheme
        self.content = content()
    }

    public func makeNSView(context: Context) -> NSGlassEffectContainerView {
        let container = NSGlassEffectContainerView()
        container.spacing = 16

        let host = NSView()
        host.translatesAutoresizingMaskIntoConstraints = false

        let glass = NSGlassEffectView()
        glass.translatesAutoresizingMaskIntoConstraints = false
        glass.style = .regular
        glass.cornerRadius = cornerRadius
        // 테마별 텍스트 가독성을 보정하기 위한 미세 틴트 색상
        glass.tintColor = isDarkTheme
            ? NSColor.black.withAlphaComponent(0.18)
            : NSColor.white.withAlphaComponent(0.12)

        // 글래스 효과 내부에 카드 본문 뷰 배치
        let hosting = NSHostingView(rootView: content)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        glass.contentView = hosting

        host.addSubview(glass)
        NSLayoutConstraint.activate([
            glass.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            glass.topAnchor.constraint(equalTo: host.topAnchor),
            glass.bottomAnchor.constraint(equalTo: host.bottomAnchor),
        ])

        container.contentView = host
        return container
    }

    public func updateNSView(_ nsView: NSGlassEffectContainerView, context: Context) {
        // 테마 및 코너 반경 변경 사항을 하위 글래스 뷰에 반영
        for sub in nsView.contentView?.subviews ?? [] {
            (sub as? NSGlassEffectView)?.cornerRadius = cornerRadius
            (sub as? NSGlassEffectView)?.tintColor = isDarkTheme
                ? NSColor.black.withAlphaComponent(0.18)
                : NSColor.white.withAlphaComponent(0.12)
        }
    }
}

// MARK: - 5.3 이벤트 카드 배경 디스패처 (EventCardBackgroundModifier)
// 설정된 호버 스타일에 따라 클래식 머티리얼 또는 리퀴드 글래스 서피스를 적용하는 수정자
public struct EventCardBackgroundModifier: ViewModifier {
    public let shape: SpeechBubbleShape
    public let cornerRadius: CGFloat
    public let isDarkTheme: Bool
    public let cardOpacity: Double
    public let isLiquidGlass: Bool

    public init(
        shape: SpeechBubbleShape,
        cornerRadius: CGFloat = 14.0,
        isDarkTheme: Bool,
        cardOpacity: Double,
        isLiquidGlass: Bool = false
    ) {
        self.shape = shape
        self.cornerRadius = cornerRadius
        self.isDarkTheme = isDarkTheme
        self.cardOpacity = cardOpacity
        self.isLiquidGlass = isLiquidGlass
    }

    @ViewBuilder
    public func body(content: Content) -> some View {
        if #available(macOS 26.0, *), isLiquidGlass {
            content.modifier(LiquidGlassSurface(
                cornerRadius: cornerRadius,
                isDarkTheme: isDarkTheme
            ))
        } else {
            content.modifier(ClassicFrostedSurface(
                shape: shape,
                isDarkTheme: isDarkTheme,
                cardOpacity: cardOpacity
            ))
        }
    }
}

extension View {
    public func eventCardBackground(
        shape: SpeechBubbleShape,
        cornerRadius: CGFloat = 14.0,
        isDarkTheme: Bool,
        cardOpacity: Double,
        isLiquidGlass: Bool = false
    ) -> some View {
        self.modifier(EventCardBackgroundModifier(
            shape: shape,
            cornerRadius: cornerRadius,
            isDarkTheme: isDarkTheme,
            cardOpacity: cardOpacity,
            isLiquidGlass: isLiquidGlass
        ))
    }
}

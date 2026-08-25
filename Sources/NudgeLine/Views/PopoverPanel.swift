// 팝오버 플로팅 패널 관리자 및 FirstMouse 호버 브릿지 제어
import AppKit
import SwiftUI

// 마우스 활성화 없이 즉각 클릭을 수신하는 NSHostingView
public final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    public override var acceptsFirstResponder: Bool { true }
    private var trackingArea: NSTrackingArea?

    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        let newArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(newArea)
        self.trackingArea = newArea
    }

    public override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        PopoverPanel.shared.setMouseInside(true)
    }

    public override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        PopoverPanel.shared.setMouseInside(false)
    }
}

// 팝오버 단일 패널 윈도우 인스턴스
public final class PopoverPanel: NSPanel {
    public static let shared = PopoverPanel()

    private var hostingView: FirstMouseHostingView<AnyView>?
    private var hideTimer: Timer?
    private var currentClusterId: String? = nil
    private var isMouseInside: Bool = false
    private var isDetailMode: Bool = false
    private var showGeneration: Int = 0

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 250, height: 160),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .floating + 1
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
    }

    public func setMouseInside(_ inside: Bool) {
        self.isMouseInside = inside
        if inside {
            hideTimer?.invalidate()
            hideTimer = nil
        } else {
            hide(delayed: true)
        }
    }

    // 일정 호버 팝오버 표시 및 좌표 애니메이션
    public func show(
        events: [CalendarEvent],
        clusterId: String,
        blockOffset: CGFloat,
        blockLength: CGFloat,
        isHorizontal: Bool,
        barPosition: BarPosition,
        settings: AppSettings = .shared
    ) {
        showGeneration += 1
        hideTimer?.invalidate()
        hideTimer = nil

        guard let screen = NSScreen.main, !events.isEmpty else { return }

        let renderer = settings.eventHoverStyle.renderer()
        self.isDetailMode = renderer.allowsTransitBridge
        let visibleFrame = screen.visibleFrame
        let fullFrame = screen.frame
        let thickness = max(settings.barWidth, settings.hoverWidth)

        let targetDimensions = renderer.targetSize(
            events: events,
            isHorizontal: isHorizontal
        )
        let targetWidth = targetDimensions.width
        let targetHeight = targetDimensions.height

        let anyView = renderer.makeView(
            events: events,
            settings: settings
        )

        if let hosting = hostingView {
            hosting.rootView = anyView
        } else {
            let hosting = FirstMouseHostingView(rootView: anyView)
            self.contentView = hosting
            self.hostingView = hosting
        }

        var finalX: CGFloat
        var finalY: CGFloat
        var startX: CGFloat
        var startY: CGFloat

        if isHorizontal {
            let idealFinalX = visibleFrame.minX + blockOffset + (blockLength / 2) - (targetWidth / 2)
            finalX = max(visibleFrame.minX + 8, min(visibleFrame.maxX - targetWidth - 8, idealFinalX))
            finalY = visibleFrame.minY + thickness + 6
            startX = finalX
            startY = visibleFrame.minY + thickness - 16
        } else {
            let centerOffset = blockOffset + (blockLength / 2)
            let idealFinalY = visibleFrame.maxY - centerOffset - (targetHeight / 2)
            finalY = max(visibleFrame.minY + 8, min(visibleFrame.maxY - targetHeight - 8, idealFinalY))

            switch barPosition {
            case .left:
                finalX = fullFrame.minX + thickness
                startX = finalX - 20
                startY = finalY
            case .right:
                finalX = fullFrame.maxX - thickness - targetWidth
                startX = finalX + 20
                startY = finalY
            case .bottom:
                finalX = visibleFrame.minX + blockOffset
                startX = finalX
                startY = visibleFrame.minY + thickness - 16
            }
        }

        let finalFrame = NSRect(
            x: finalX,
            y: finalY,
            width: targetWidth,
            height: targetHeight
        )

        let startFrame = NSRect(
            x: startX,
            y: startY,
            width: finalFrame.width,
            height: finalFrame.height
        )

        let isNewAppearance = !self.isVisible || currentClusterId != clusterId
        currentClusterId = clusterId

        if !self.isVisible {
            self.setFrame(startFrame, display: true, animate: false)
            self.alphaValue = 0.0
            self.orderFrontRegardless()

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.14
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                self.animator().setFrame(finalFrame, display: true)
                self.animator().alphaValue = 1.0
            }
        } else if isNewAppearance {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                self.animator().setFrame(finalFrame, display: true)
                self.animator().alphaValue = 1.0
            }
        }
    }

    // 현재 시각 인디케이터 호버 툴팁 표시
    public func showTimeTooltip(
        currentTime: Date,
        settings: AppSettings,
        timeOffset: CGFloat,
        isHorizontal: Bool,
        barPosition: BarPosition
    ) {
        showGeneration += 1
        hideTimer?.invalidate()
        hideTimer = nil
        self.isDetailMode = false

        guard let screen = NSScreen.main else { return }

        let visibleFrame = screen.visibleFrame
        let fullFrame = screen.frame
        let thickness = max(settings.barWidth, settings.hoverWidth)

        let tooltipView = AnyView(
            CurrentTimeTooltipView(
                currentTime: currentTime,
                settings: settings
            )
        )

        if let hosting = hostingView {
            hosting.rootView = tooltipView
        } else {
            let hosting = FirstMouseHostingView(rootView: tooltipView)
            self.contentView = hosting
            self.hostingView = hosting
        }

        let targetWidth: CGFloat = 110
        let targetHeight: CGFloat = 22

        var finalX: CGFloat
        var finalY: CGFloat

        if isHorizontal {
            finalX = visibleFrame.minX + timeOffset - (targetWidth / 2)
            finalY = visibleFrame.minY + thickness + 4
            finalX = max(visibleFrame.minX + 4, min(visibleFrame.maxX - targetWidth - 4, finalX))
        } else {
            finalY = visibleFrame.maxY - timeOffset - (targetHeight / 2)
            finalY = max(visibleFrame.minY + 4, min(visibleFrame.maxY - targetHeight - 4, finalY))

            switch barPosition {
            case .left:
                finalX = fullFrame.minX + thickness + 4
            case .right:
                finalX = fullFrame.maxX - thickness - targetWidth - 4
            case .bottom:
                finalX = visibleFrame.minX + timeOffset - (targetWidth / 2)
            }
        }

        let finalFrame = NSRect(x: finalX, y: finalY, width: targetWidth, height: targetHeight)
        let clusterId = "__CURRENT_TIME_TOOLTIP__"
        let isNew = !self.isVisible || currentClusterId != clusterId
        currentClusterId = clusterId

        if !self.isVisible {
            self.setFrame(finalFrame, display: true, animate: false)
            self.alphaValue = 0.0
            self.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.12
                self.animator().alphaValue = 1.0
            }
        } else if isNew {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.1
                self.animator().setFrame(finalFrame, display: true)
                self.animator().alphaValue = 1.0
            }
        }
    }

    // 팝오버 숨김 타이머 (상세 카드 브릿지 0.22초 딜레이)
    public func hide(delayed: Bool = false) {
        hideTimer?.invalidate()
        if delayed {
            let delayTime: TimeInterval = isDetailMode ? 0.22 : 0.04
            let timer = Timer(timeInterval: delayTime, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                if self.isMouseInside {
                    return
                }
                self.performHide()
            }
            RunLoop.main.add(timer, forMode: .common)
            hideTimer = timer
        } else {
            performHide()
        }
    }

    // 팝오버 페이드아웃 및 닫기 수행
    private func performHide() {
        guard self.isVisible else { return }
        let hideGen = showGeneration
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.10
            self.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            guard let self = self else { return }
            if self.showGeneration == hideGen {
                self.orderOut(nil)
                self.currentClusterId = nil
                self.isMouseInside = false
            }
        })
    }
}

// MARK: - 현재 시각 미니 툴팁 뷰
private struct CurrentTimeTooltipView: View {
    let currentTime: Date
    let settings: AppSettings

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M.d (E) HH:mm"
        return f
    }()

    @Environment(\.colorScheme) private var colorScheme
    private var isDarkTheme: Bool {
        settings.eventCardTheme.isDark(for: colorScheme)
    }

    var body: some View {
        HStack(spacing: 3.5) {
            Circle()
                .fill(settings.effectiveCurrentTimeColor())
                .frame(width: 5, height: 5)
                .shadow(color: settings.effectiveCurrentTimeColor().opacity(0.6), radius: 2)

            Text(Self.timeFormatter.string(from: currentTime))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(isDarkTheme ? Color.white : Color.black.opacity(0.9))
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            VisualEffectBlur(
                material: isDarkTheme ? .hudWindow : .popover,
                blendingMode: .behindWindow,
                state: .active
            )
            .clipShape(Capsule())
        )
        .background(
            Capsule()
                .fill(isDarkTheme ? Color.black.opacity(0.85) : Color.white.opacity(0.2))
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isDarkTheme ? 0.35 : 0.6),
                            Color.white.opacity(isDarkTheme ? 0.10 : 0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
        .preferredColorScheme(isDarkTheme ? .dark : .light)
    }
}

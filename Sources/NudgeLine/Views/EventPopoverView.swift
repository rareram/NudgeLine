// 일정 호버 상세 액션 카드 팝오버 뷰 및 블러/말풍선 렌더러
import SwiftUI
import AppKit

// macOS 네이티브 NSVisualEffectView 래퍼 블러 뷰
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

// 프로스티드 글래스 일정 상세 카드 팝오버 뷰
public struct EventPopoverView: View {
    public let events: [CalendarEvent]
    @ObservedObject public var settings: AppSettings

    public init(events: [CalendarEvent], settings: AppSettings = .shared) {
        self.events = events
        self.settings = settings
    }

    private var bubbleDirection: BubbleArrowDirection {
        switch settings.barPosition {
        case .left: return .left
        case .right: return .right
        case .bottom: return .bottom
        }
    }

    @Environment(\.colorScheme) private var colorScheme
    private var isDarkTheme: Bool {
        settings.eventCardTheme.isDark(for: colorScheme)
    }

    public var body: some View {
        let isMulti = events.count > 1
        let direction = bubbleDirection
        let bubbleShape = SpeechBubbleShape(direction: direction, arrowWidth: 8, arrowHeight: 14, cornerRadius: 10)

        VStack(alignment: .leading, spacing: 10) {
            if isMulti {
                // Header badge for overlapping events
                HStack(spacing: 5) {
                    Image(systemName: "square.2.layers.3d.top.filled")
                        .font(.caption2)
                        .foregroundStyle(isDarkTheme ? Color.white.opacity(0.8) : Color.black.opacity(0.7))
                    Text(L10n.tr(.overlappingEvents(events.count), lang: settings.language))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(isDarkTheme ? Color.white.opacity(0.8) : Color.black.opacity(0.7))
                    Spacer()
                }
                .padding(.bottom, 2)
            }

            ForEach(events) { event in
                singleEventCard(event: event)

                if event.id != events.last?.id {
                    Divider()
                        .overlay(isDarkTheme ? Color.white.opacity(0.12) : Color.black.opacity(0.1))
                        .padding(.vertical, 2)
                }
            }
        }
        .padding(.leading, direction == .left ? 18 : 12)
        .padding(.trailing, direction == .right ? 18 : 12)
        .padding(.top, 12)
        .padding(.bottom, direction == .bottom ? 18 : 12)
        .frame(minWidth: isMulti ? 220 : 200, maxWidth: 280, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
        .background(
            // Layer 1: Genuine Hardware-Accelerated Frosted Glass Backdrop Blur
            VisualEffectBlur(
                material: isDarkTheme ? .hudWindow : .popover,
                blendingMode: .behindWindow,
                state: .active
            )
            .clipShape(bubbleShape)
            .allowsHitTesting(false)
        )
        .background(
            // Layer 2: Theme-matched Translucent Tint Layer
            bubbleShape
                .fill(tintColor)
                .allowsHitTesting(false)
        )
        .overlay(
            // Layer 3: Ambient Light Shimmer Reflection Gradient
            LinearGradient(
                colors: [
                    Color.white.opacity(isDarkTheme ? 0.12 : 0.35),
                    Color.white.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(bubbleShape)
            .allowsHitTesting(false)
        )
        .overlay(
            // Layer 4: 1px Crystal Edge Rim Highlight
            bubbleShape
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isDarkTheme ? 0.38 : 0.65),
                            Color.white.opacity(isDarkTheme ? 0.10 : 0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
                .allowsHitTesting(false)
        )
        .shadow(color: .black.opacity(0.32), radius: 12, x: 0, y: 5)
        .preferredColorScheme(isDarkTheme ? .dark : .light)
    }

    private var tintColor: Color {
        isDarkTheme ? Color.black.opacity(settings.cardOpacity) : Color.white.opacity(max(0.1, settings.cardOpacity * 0.25))
    }

    @ViewBuilder
    private func singleEventCard(event: CalendarEvent) -> some View {
        let textPrimary = isDarkTheme ? Color.white : Color.black.opacity(0.9)
        let textSecondary = isDarkTheme ? Color.white.opacity(0.72) : Color.black.opacity(0.65)
        let textMuted = isDarkTheme ? Color.white.opacity(0.55) : Color.black.opacity(0.48)

        VStack(alignment: .leading, spacing: 6) {
            // Source & Calendar Header
            HStack(spacing: 6) {
                Circle()
                    .fill(event.effectiveColor(settings: settings))
                    .frame(width: 8, height: 8)
                    .shadow(color: event.effectiveColor(settings: settings).opacity(0.6), radius: 2)

                Text("\(event.sourceTitle(lang: settings.language)) · \(event.calendarTitle)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(textSecondary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                if event.isAllDay {
                    Text(L10n.tr(.allDayBadge, lang: settings.language))
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(isDarkTheme ? Color.white.opacity(0.18) : Color.black.opacity(0.08))
                        .foregroundStyle(textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            // Title
            Text(event.title(lang: settings.language))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // Time & Duration
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundStyle(textSecondary)

                Text(event.formattedTimeRange(lang: settings.language))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(textPrimary)

                if !event.isAllDay {
                    Text(L10n.tr(.durationMinutes(event.durationMinutes), lang: settings.language))
                        .font(.caption2)
                        .foregroundStyle(textMuted)
                }
            }

            // Location if present
            if let loc = event.location, !loc.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption2)
                        .foregroundStyle(textSecondary)

                    Text(loc)
                        .font(.caption2)
                        .foregroundStyle(textSecondary)
                        .lineLimit(1)
                }
            }

            // Notes preview if present
            if let notes = event.notes, !notes.isEmpty {
                let cleanNotes = notes.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanNotes.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "note.text")
                            .font(.caption2)
                            .foregroundStyle(textMuted)
                            .padding(.top, 1)

                        Text(cleanNotes)
                            .font(.caption2)
                            .foregroundStyle(textSecondary)
                            .lineLimit(2)
                    }
                }
            }

            // Meeting Quick Join Button if detected
            if let meeting = event.meetingInfo {
                if meeting.platform == .unverified {
                    // 미검증 외부 링크: 피싱 방어를 위해 클릭을 차단하고 캘린더 앱 직접 확인 안내 배지로 표출
                    HStack(spacing: 5) {
                        Image(systemName: meeting.platform.iconName)
                            .font(.system(size: 11, weight: .semibold))
                        Text(L10n.tr(.unverifiedMeetingLink, lang: settings.language))
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(meeting.platform.brandColor.opacity(isDarkTheme ? 0.22 : 0.15))
                    .foregroundStyle(meeting.platform.brandColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(meeting.platform.brandColor.opacity(0.3), lineWidth: 0.5)
                    )
                    .padding(.top, 3)
                } else {
                    // 공식 화상회의 플랫폼: 1클릭 즉시 입장 버튼
                    Button(action: {
                        NSWorkspace.shared.open(meeting.url)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                            PopoverPanel.shared.hide(delayed: false)
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: meeting.platform.iconName)
                                .font(.system(size: 11, weight: .semibold))
                            Text(L10n.tr(.joinMeeting(meeting.platform.rawValue), lang: settings.language))
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(meeting.platform.brandColor.opacity(isDarkTheme ? 0.22 : 0.15))
                        .foregroundStyle(meeting.platform.brandColor)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(meeting.platform.brandColor.opacity(0.3), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 3)
                }
            }

            // Open in Calendar Button
            Button(action: {
                CalendarAppLauncher.open(event: event)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    PopoverPanel.shared.hide(delayed: false)
                }
            }) {
                Label(L10n.tr(.openInCalendarApp, lang: settings.language), systemImage: "calendar")
                    .font(.system(size: 10))
                    .foregroundStyle(isDarkTheme ? Color.white.opacity(0.7) : Color.blue)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 팝오버 말풍선 꼬리 방향 및 기하 Shape
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

            // Left edge with Arrow pointing to the timeline bar
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

            // Right edge with Arrow
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

            // Bottom edge with Arrow
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

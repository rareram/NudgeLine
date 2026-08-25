// 초경량 무간섭 일정 요약 툴팁 팝오버 뷰
import SwiftUI
import AppKit

public struct SimpleInfoPopoverView: View {
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
        let direction = bubbleDirection
        let bubbleShape = SpeechBubbleShape(direction: direction, arrowWidth: 7, arrowHeight: 12, cornerRadius: 8)

        VStack(alignment: .leading, spacing: 6) {
            ForEach(events) { event in
                singleEventRow(event: event)

                if event.id != events.last?.id {
                    Divider()
                        .overlay(isDarkTheme ? Color.white.opacity(0.12) : Color.black.opacity(0.1))
                }
            }
        }
        .padding(.leading, direction == .left ? 14 : 10)
        .padding(.trailing, direction == .right ? 14 : 10)
        .padding(.top, 8)
        .padding(.bottom, direction == .bottom ? 14 : 8)
        .frame(minWidth: 130, maxWidth: 280, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
        .background(
            VisualEffectBlur(
                material: isDarkTheme ? .hudWindow : .popover,
                blendingMode: .behindWindow,
                state: .active
            )
            .clipShape(bubbleShape)
            .allowsHitTesting(false)
        )
        .background(
            bubbleShape
                .fill(isDarkTheme ? Color.black.opacity(settings.cardOpacity) : Color.white.opacity(max(0.1, settings.cardOpacity * 0.25)))
                .allowsHitTesting(false)
        )
        .overlay(
            bubbleShape
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
                .allowsHitTesting(false)
        )
        .shadow(color: .black.opacity(0.28), radius: 8, x: 0, y: 4)
        .preferredColorScheme(isDarkTheme ? .dark : .light)
    }

    @ViewBuilder
    private func singleEventRow(event: CalendarEvent) -> some View {
        let textPrimary = isDarkTheme ? Color.white : Color.black.opacity(0.9)
        let textSecondary = isDarkTheme ? Color.white.opacity(0.72) : Color.black.opacity(0.65)
        let calColor = settings.customColor(for: event.calendarIdentifier) ?? event.defaultColor

        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Circle()
                    .fill(calColor)
                    .frame(width: 7, height: 7)

                Text(event.title(lang: settings.language))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                Text(event.formattedTimeRange(lang: settings.language))
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(textSecondary)

                if let loc = event.location, !loc.isEmpty {
                    Text("•")
                        .font(.system(size: 9))
                        .foregroundStyle(textSecondary)

                    Text(loc)
                        .font(.system(size: 9))
                        .foregroundStyle(textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

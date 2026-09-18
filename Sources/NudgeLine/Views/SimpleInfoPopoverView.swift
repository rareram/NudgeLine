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
        // 1단계: 순정 머티리얼 글래스 블러 (사용자 cardOpacity 투명도 반영)
        .background(.ultraThinMaterial.opacity(settings.cardOpacity), in: bubbleShape)
        .background(
            // 2단계: 테마 투명 틴트 레이어 (다크/라이트 모드 대비 보강)
            bubbleShape
                .fill(isDarkTheme ? Color.black.opacity(settings.cardOpacity * 0.40) : Color.white.opacity(settings.cardOpacity * 0.35))
                .allowsHitTesting(false)
        )
        .clipShape(bubbleShape)
        .overlay(
            // 3단계: 외곽선 스트로크 (라이트 모드 듀얼 톤 경계선 가시성 확보)
            bubbleShape
                .stroke(
                    LinearGradient(
                        colors: isDarkTheme ? [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.10)
                        ] : [
                            Color.black.opacity(0.20),
                            Color.black.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
                .allowsHitTesting(false)
        )
        // 4단계: 순정 부드러운 그림자 (밝은 배경 플로팅 입체감 보강)
        .shadow(color: Color.black.opacity(isDarkTheme ? 0.30 : 0.16), radius: 6, x: 0, y: 3)
    }

    @ViewBuilder
    private func singleEventRow(event: CalendarEvent) -> some View {
        let textPrimary = isDarkTheme ? Color.white : Color.black.opacity(0.9)
        let textSecondary = isDarkTheme ? Color.white.opacity(0.72) : Color.black.opacity(0.65)
        let rawCalColor = settings.customColor(for: event.calendarIdentifier) ?? event.defaultColor

        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Circle()
                    .fill(rawCalColor)
                    .frame(width: 7, height: 7)
                    .overlay(
                        Circle().stroke(Color.black.opacity(isDarkTheme ? 0.25 : 0.15), lineWidth: 0.5)
                    )

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

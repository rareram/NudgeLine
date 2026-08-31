// 일정 호버 상세 액션 카드 팝오버 뷰 (프로스티드 글래스, 화상회의 링크 바로가기)
import SwiftUI
import AppKit

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

    private var tintColor: Color {
        let opacity = settings.cardOpacity
        if isDarkTheme {
            return Color.black.opacity(opacity)
        } else {
            return Color.white.opacity(max(0.1, opacity * 0.25))
        }
    }

    public var body: some View {
        let isMulti = events.count > 1
        let direction = bubbleDirection
        let bubbleShape = SpeechBubbleShape(direction: direction, arrowWidth: 8, arrowHeight: 14, cornerRadius: 10)

        VStack(alignment: .leading, spacing: 10) {
            if isMulti {
                // 다중 일정 중첩 헤더 배지
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
            // 1단계: 하드웨어 가속 프로스티드 글래스 블러
            VisualEffectBlur(
                material: isDarkTheme ? .hudWindow : .popover,
                blendingMode: .behindWindow,
                state: .active
            )
            .clipShape(bubbleShape)
            .allowsHitTesting(false)
        )
        .background(
            // 2단계: 테마 투명 틴트 레이어
            bubbleShape
                .fill(tintColor)
                .allowsHitTesting(false)
        )
        .overlay(
            // 3단계: 상단 림 라이트 반사 그래디언트
            LinearGradient(
                colors: [
                    Color.white.opacity(isDarkTheme ? 0.12 : 0.35),
                    Color.white.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .center
            )
            .clipShape(bubbleShape)
            .allowsHitTesting(false)
        )
        .overlay(
            // 4단계: 외곽선 스트로크
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
        .shadow(color: .black.opacity(0.28), radius: 10, x: 0, y: 5)
        .preferredColorScheme(isDarkTheme ? .dark : .light)
    }

    // MARK: - 개별 일정 카드 뷰
    @ViewBuilder
    private func singleEventCard(event: CalendarEvent) -> some View {
        let textPrimary = isDarkTheme ? Color.white : Color.black.opacity(0.9)
        let textSecondary = isDarkTheme ? Color.white.opacity(0.72) : Color.black.opacity(0.65)
        let textMuted = isDarkTheme ? Color.white.opacity(0.55) : Color.black.opacity(0.45)
        let calColor = settings.customColor(for: event.calendarIdentifier) ?? event.defaultColor

        VStack(alignment: .leading, spacing: 6) {
            // 헤더: 캘린더 색상 인디케이터 + 계정/캘린더 이름
            HStack(spacing: 5) {
                Circle()
                    .fill(calColor)
                    .frame(width: 8, height: 8)

                Text("\(event.sourceTitle(lang: settings.language)) • \(event.calendarTitle)")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(textMuted)
                    .lineLimit(1)
            }

            // 일정 제목
            Text(event.title(lang: settings.language))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(textPrimary)
                .lineLimit(2)

            // 시간 범위 및 소요 시간
            HStack(spacing: 6) {
                Text(event.formattedTimeRange(lang: settings.language))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(textSecondary)

                if !event.isAllDay {
                    Text(L10n.tr(.durationMinutes(event.durationMinutes), lang: settings.language))
                        .font(.caption2)
                        .foregroundStyle(textMuted)
                }
            }

            // 위치 정보
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

            // 본문 메모 미리보기
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

            // 화상회의 원클릭 바로가기 버튼 또는 미검증 안내 배지
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

            // Apple 캘린더 앱에서 보기 버튼
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

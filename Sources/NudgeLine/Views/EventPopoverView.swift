// 일정 호버 상세 액션 카드 팝오버 뷰 (프로스티드 글래스, 화상회의 링크 바로가기)
import SwiftUI
import AppKit

public struct EventPopoverView: View {
    public let events: [CalendarEvent]
    public let allDayEvents: [CalendarEvent]
    @ObservedObject public var settings: AppSettings

    public init(
        events: [CalendarEvent],
        allDayEvents: [CalendarEvent] = [],
        settings: AppSettings = .shared
    ) {
        self.events = events
        self.allDayEvents = allDayEvents
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

    private var textMuted: Color {
        isDarkTheme ? Color.white.opacity(0.60) : Color.black.opacity(0.55)
    }

    public var body: some View {
        let isMulti = events.count > 1
        let direction = bubbleDirection
        let bubbleShape = SpeechBubbleShape(direction: direction, arrowWidth: 8, arrowHeight: 14, cornerRadius: 10)

        let isLiquidGlass = settings.eventHoverStyle == .liquidGlassCard

        return VStack(alignment: .leading, spacing: 8) {
            // 당일 종일 일정이 있을 때 상단에 표시하는 인라인 요약 배지
            if !allDayEvents.isEmpty {
                allDayInlineBadgeView()
            }

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

            let visibleEvents = Array(events.prefix(3))
            let overflowCount = events.count - visibleEvents.count

            ForEach(visibleEvents) { event in
                singleEventCard(event: event)

                if event.id != visibleEvents.last?.id || overflowCount > 0 {
                    Divider()
                        .overlay(isDarkTheme ? Color.white.opacity(0.12) : Color.black.opacity(0.1))
                        .padding(.vertical, 2)
                }
            }

            if overflowCount > 0 {
                overflowEventsFooterView(count: overflowCount)
            }
        }
        .padding(.leading, (!isLiquidGlass && direction == .left) ? 18 : 12)
        .padding(.trailing, (!isLiquidGlass && direction == .right) ? 18 : 12)
        .padding(.top, 12)
        .padding(.bottom, (!isLiquidGlass && direction == .bottom) ? 18 : 12)
        .frame(minWidth: isMulti ? 220 : 200, maxWidth: 280, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
        .eventCardBackground(
            shape: bubbleShape,
            cornerRadius: 14.0,
            isDarkTheme: isDarkTheme,
            cardOpacity: settings.cardOpacity,
            isLiquidGlass: isLiquidGlass
        )
    }

    // MARK: - 개별 일정 카드 뷰
    @ViewBuilder
    private func singleEventCard(event: CalendarEvent) -> some View {
        let textPrimary = isDarkTheme ? Color.white : Color.black.opacity(0.95)
        let textSecondary = isDarkTheme ? Color.white.opacity(0.72) : Color.black.opacity(0.70)
        let rawCalColor = settings.customColor(for: event.calendarIdentifier) ?? event.defaultColor

        VStack(alignment: .leading, spacing: 6) {
            // 헤더: 캘린더 색상 인디케이터 + 계정/캘린더 이름
            HStack(spacing: 5) {
                Circle()
                    .fill(rawCalColor)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle().stroke(Color.black.opacity(isDarkTheme ? 0.25 : 0.15), lineWidth: 0.5)
                    )

                Text("\(event.sourceTitle(lang: settings.language)) • \(event.calendarTitle)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(textMuted)
                    .lineLimit(1)
            }

            // 일정 제목
            Text(event.title(lang: settings.language))
                .font(.system(size: 13, weight: .bold))
                .strikethrough(event.isCanceledOrDeclined, color: textSecondary)
                .foregroundStyle(event.isCanceledOrDeclined ? textSecondary : textPrimary)
                .lineLimit(2)

            // 시간 범위 및 소요 시간 + 취소/거절 상태 배지
            HStack(spacing: 6) {
                Text(event.formattedTimeRange(lang: settings.language))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(textSecondary)

                if !event.isAllDay {
                    Text(L10n.tr(.durationMinutes(event.durationMinutes), lang: settings.language))
                        .font(.caption2)
                        .foregroundStyle(textMuted)
                }

                if event.isCanceled {
                    Text(L10n.tr(.eventStatusCanceled, lang: settings.language))
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1.5)
                        .background(Color.red.opacity(0.18))
                        .foregroundStyle(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                } else if event.isDeclined {
                    Text(L10n.tr(.eventStatusDeclined, lang: settings.language))
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1.5)
                        .background(Color.gray.opacity(0.20))
                        .foregroundStyle(textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }

            // 본문 메모 미리보기 (시간 직후 배치 & 시스템 보일러플레이트 제외된 사용자 순수 메모 존재 시에만 표출)
            if let cleanNotes = event.displayNotes {
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

            // 위치 정보
            if let loc = event.location, !loc.isEmpty {
                if loc.contains("://") {
                    // URL 형태의 위치는 일반 텍스트로 표출 (피싱 방어 및 직관성 유지)
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption2)
                            .foregroundStyle(textSecondary)

                        Text(loc)
                            .font(.caption2)
                            .foregroundStyle(textSecondary)
                            .lineLimit(1)
                    }
                } else if let mapUrl = settings.effectivePreferredMapService.url(for: loc) {
                    // 물리적 주소/위치: 설정된 지도 서비스로 검색 연동
                    actionLinkButton(icon: "mappin.and.ellipse", text: loc, url: mapUrl)
                }
            }

            // 관련 웹 링크 (웨비나, 세미나, 문서 등)
            if let webLink = event.webLink {
                actionLinkButton(icon: "link", text: webLink.displayHost, url: webLink.url, isExternal: true)
            }

            // 화상회의 원클릭 바로가기 버튼 또는 미검증 안내 배지 / 취소·거절 상태 표시
            if let meeting = event.meetingInfo {
                let buttonColor = meeting.platform.brandColor.adjustedForContrast(isDark: isDarkTheme)
                if event.isCanceledOrDeclined {
                    // 취소 또는 거절된 일정: 회의 참여 비활성화 배지
                    HStack(spacing: 5) {
                        Image(systemName: meeting.platform.iconName)
                            .font(.system(size: 11, weight: .semibold))
                        Text(event.isCanceled ? L10n.tr(.canceledMeeting, lang: settings.language) : L10n.tr(.declinedMeeting, lang: settings.language))
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(isDarkTheme ? 0.20 : 0.12))
                    .foregroundStyle(textSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(isDarkTheme ? 0.35 : 0.25), lineWidth: 0.5)
                    )
                    .padding(.top, 3)
                } else if meeting.platform == .unverified {
                    // 미검증 외부 링크: 참여 버튼 진입 차단 및 웹링크 미중복 시 정적 안내 배지 노출
                    if event.webLink == nil || event.webLink?.url.absoluteString != meeting.url.absoluteString {
                        HStack(spacing: 5) {
                            Image(systemName: meeting.platform.iconName)
                                .font(.system(size: 11, weight: .semibold))
                            Text(L10n.tr(.unverifiedMeetingLink, lang: settings.language))
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(buttonColor.opacity(isDarkTheme ? 0.24 : 0.14))
                        .foregroundStyle(buttonColor)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(buttonColor.opacity(isDarkTheme ? 0.45 : 0.30), lineWidth: 0.5)
                        )
                        .padding(.top, 3)
                    }
                } else {
                    // 공식 화상회의 플랫폼: 네이티브 데스크톱 앱 우선 실행 및 웹 폴백
                    Button(action: {
                        MeetingAppLauncher.open(meeting: meeting)
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
                        .background(buttonColor.opacity(isDarkTheme ? 0.24 : 0.14))
                        .foregroundStyle(buttonColor)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(buttonColor.opacity(isDarkTheme ? 0.45 : 0.30), lineWidth: 0.5)
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
                    .foregroundStyle(isDarkTheme ? Color.white.opacity(0.7) : Color.blue.adjustedForContrast(isDark: false, factor: 0.78))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // ponytail: 위치 및 웹 링크 공통 액션 버튼 렌더러 (중복 제거 및 일관성 유지)
    @ViewBuilder
    private func actionLinkButton(icon: String, text: String, url: URL, isExternal: Bool = false) -> some View {
        Button(action: {
            NSWorkspace.shared.open(url)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                PopoverPanel.shared.hide(delayed: false)
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(isDarkTheme ? Color.accentColor : Color.blue.adjustedForContrast(isDark: false, factor: 0.78))

                Text(text)
                    .font(.caption2)
                    .foregroundStyle(isDarkTheme ? Color.white.opacity(0.88) : Color.blue.adjustedForContrast(isDark: false, factor: 0.78))
                    .lineLimit(1)
                    .underline(true, color: (isDarkTheme ? Color.white.opacity(0.35) : Color.blue.opacity(0.35)))

                if isExternal {
                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(textMuted)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 종일 일정 인라인 배지
    // 시간제 일정 카드 상단에 당일 종일 일정 건수를 요약 표시
    @ViewBuilder
    private func allDayInlineBadgeView() -> some View {
        let allDayCount = allDayEvents.count
        let firstTitle = allDayEvents[0].title(lang: settings.language)
        let badgeText = allDayCount == 1 ? firstTitle : "\(firstTitle) +\(allDayCount - 1)"

        HStack(spacing: 5) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(isDarkTheme ? Color.white.opacity(0.8) : Color.black.opacity(0.7))

            Text(L10n.tr(.allDayNotice(badgeText), lang: settings.language))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isDarkTheme ? Color.white.opacity(0.85) : Color.black.opacity(0.75))
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3.5)
        .background(isDarkTheme ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(isDarkTheme ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 0.6)
        )
    }

    // MARK: - 다중 일정 초과 표시 푸터
    // 표시 한도를 초과한 일정이 있을 때 캘린더 앱 열기를 안내하는 바로가기 버튼
    @ViewBuilder
    private func overflowEventsFooterView(count: Int) -> some View {
        Button(action: {
            if let url = URL(string: "calshow:") {
                NSWorkspace.shared.open(url)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                PopoverPanel.shared.hide(delayed: false)
            }
        }) {
            HStack(spacing: 5) {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(isDarkTheme ? Color.white.opacity(0.6) : Color.black.opacity(0.5))

                Text(L10n.tr(.moreEventsNotice(count), lang: settings.language))
                    .font(.caption2)
                    .foregroundStyle(isDarkTheme ? Color.white.opacity(0.75) : Color.black.opacity(0.65))

                Spacer()

                Image(systemName: "arrow.up.forward.app")
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundStyle(isDarkTheme ? Color.white.opacity(0.5) : Color.black.opacity(0.4))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(isDarkTheme ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

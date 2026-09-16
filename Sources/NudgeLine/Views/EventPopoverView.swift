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

    private var tintColor: Color {
        let opacity = settings.cardOpacity
        if isDarkTheme {
            return Color.black.opacity(opacity)
        } else {
            return Color.white.opacity(max(0.60, opacity))
        }
    }

    private var textMuted: Color {
        isDarkTheme ? Color.white.opacity(0.55) : Color.black.opacity(0.45)
    }

    public var body: some View {
        let isMulti = events.count > 1
        let direction = bubbleDirection
        let bubbleShape = SpeechBubbleShape(direction: direction, arrowWidth: 8, arrowHeight: 14, cornerRadius: 10)

        VStack(alignment: .leading, spacing: 8) {
            // 당일 종일 일정이 존재하는 경우 1줄 미니 인라인 칩 표출 (카드 비대화 방지)
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
        .padding(.leading, direction == .left ? 18 : 12)
        .padding(.trailing, direction == .right ? 18 : 12)
        .padding(.top, 12)
        .padding(.bottom, direction == .bottom ? 18 : 12)
        .frame(minWidth: isMulti ? 220 : 200, maxWidth: 280, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
        .background(
            // 1단계: 하드웨어 가속 프로스티드 글래스 블러
            VisualEffectBlur(
                material: .popover,
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
                        colors: isDarkTheme ? [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.10)
                        ] : [
                            Color.black.opacity(0.16),
                            Color.black.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
                .allowsHitTesting(false)
        )
        .shadow(color: .black.opacity(isDarkTheme ? 0.28 : 0.18), radius: 10, x: 0, y: 5)
    }

    // MARK: - 개별 일정 카드 뷰
    @ViewBuilder
    private func singleEventCard(event: CalendarEvent) -> some View {
        let textPrimary = isDarkTheme ? Color.white : Color.black.opacity(0.9)
        let textSecondary = isDarkTheme ? Color.white.opacity(0.72) : Color.black.opacity(0.65)
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
                    .font(.system(size: 9.5, weight: .semibold))
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
                        .font(.system(size: 9, weight: .semibold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1.5)
                        .background(Color.red.opacity(0.18))
                        .foregroundStyle(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                } else if event.isDeclined {
                    Text(L10n.tr(.eventStatusDeclined, lang: settings.language))
                        .font(.system(size: 9, weight: .semibold))
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

    // MARK: - 종일 일정 1줄 미니 인라인 배지
    // [원인/배경: 시간 일정 카드에 종일 일정을 풀 카드로 병합 시 카드 높이 폭증 및 화면 이탈 발생 -> 해결 방법: 상단에 18pt 높이의 1줄 칩으로 가볍게 표시하여 존재 사실만 인지 -> 기대 효과: 카드 높이 슬림화 및 화살표 조준 정밀도 보존]
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

    // MARK: - 4개 이상 일정 스택 시 축약 배지
    // [원인/배경: 종일 일정이 4개 이상일 때 무한 스택 시 화면 과점유 및 상단 메뉴바 침범 발생 -> 해결 방법: 최대 3개까지만 풀 카드로 노출하고 4개 이상은 Apple 캘린더 열기 바로가기 칩으로 축약 -> 기대 효과: 카드 최대 높이를 약 320px로 엄격히 제한하여 화면 안정성 확보]
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

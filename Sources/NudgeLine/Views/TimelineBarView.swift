// 화면 가장자리 타임라인 바 메인 뷰 (단일 마우스 호버 센서, 일정 렌더링, 현재 시각 표시자)
import SwiftUI
import Combine
import AppKit

public struct TimelineBarView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var calendarService: CalendarService
    @ObservedObject var reminderService: ReminderService
    @ObservedObject var panelState: OverlayPanelState

    @State private var currentTime = Date()
    @State private var cachedSegments: [TimelineSegment] = []
    @State private var hoveredFocusId: String? = nil
    @State private var hoveredActiveId: String? = nil
    @State private var isBarHovered = false
    @State private var activeEffectType: EventTriggerEffectType? = nil
    @State private var activeEffectId: UUID = UUID()
    @State private var lastTriggeredEventKey: String? = nil
    @State private var lastTriggeredHourlyHour: Int = -1
    @State private var lastTriggeredEventDate: Date? = nil
    @State private var lastTriggeredHourlyDate: Date? = nil
    @State private var pulsingSegmentId: String? = nil
    @State private var lastTriggeredPreAlertEventKey: String? = nil
    @State private var isPreviewingMarker: Bool = false
    @State private var previewMarkerPos: CGFloat = 0

    @Environment(\.colorScheme) private var colorScheme
    private var isDark: Bool {
        colorScheme == .dark
    }

    private static let clockPublisher = Timer.publish(every: 1, on: .main, in: .default).autoconnect()

    public init(
        settings: AppSettings = .shared,
        calendarService: CalendarService = .shared,
        reminderService: ReminderService = .shared,
        panelState: OverlayPanelState = OverlayPanelState()
    ) {
        self.settings = settings
        self.calendarService = calendarService
        self.reminderService = reminderService
        self.panelState = panelState
    }

    public var body: some View {
        GeometryReader { geometry in
            let isHorizontal = settings.barPosition.isHorizontal
            let totalLength = isHorizontal ? geometry.size.width : geometry.size.height
            let currentThickness = isBarHovered && settings.expandOnHover ? settings.hoverWidth : settings.barWidth

            let dayStart = settings.startDate(for: currentTime)
            let dayEnd = settings.endDate(for: currentTime)
            let totalSec = max(60, dayEnd.timeIntervalSince(dayStart))

            let segments = cachedSegments
            let timeOffset = calculateCurrentTimeOffset(
                dayStart: dayStart,
                totalSec: totalSec,
                totalLength: totalLength
            )

            ZStack(alignment: alignmentForPosition) {
                // 1. 타임라인 배경 트랙
                backgroundTrack(
                    thickness: settings.barWidth,
                    length: totalLength,
                    isHorizontal: isHorizontal,
                    isDark: isDark
                )

                // 2. 일정 세그먼트 렌더링
                ForEach(segments) { segment in
                    renderSegment(
                        segment: segment,
                        dayStart: dayStart,
                        totalSec: totalSec,
                        totalLength: totalLength,
                        isHorizontal: isHorizontal
                    )
                }

                // 2-1. 미리알림 시점 마커 렌더링
                if settings.enableReminders {
                    ForEach(reminderService.reminders) { reminder in
                        renderReminder(
                            reminder: reminder,
                            dayStart: dayStart,
                            totalSec: totalSec,
                            totalLength: totalLength,
                            isHorizontal: isHorizontal
                        )
                    }

                    // 마커 미리보기 활성화 시 팝업 마커 렌더링
                    if isPreviewingMarker {
                        renderPreviewMarker(
                            totalLength: totalLength,
                            isHorizontal: isHorizontal
                        )
                    }
                }

                // 3. 현재 시각 인디케이터
                if let pos = timeOffset {
                    CurrentTimeIndicatorView(
                        settings: settings,
                        thickness: currentThickness,
                        isHorizontal: isHorizontal,
                        isBarHovered: isBarHovered,
                        isPetProximityHovered: panelState.isPetProximityHovered,
                        accentColor: settings.effectiveCurrentTimeColor(),
                        activeEffectType: activeEffectType,
                        activeEffectId: activeEffectId,
                        onEffectComplete: {
                            activeEffectType = nil
                        },
                        isDark: isDark
                    )
                    .offset(
                        x: isHorizontal ? pos : 0,
                        y: isHorizontal ? 0 : pos
                    )
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: alignmentForPosition
            )
            .contentShape(Rectangle())
            .onReceive(NotificationCenter.default.publisher(for: .previewReminderMarker)) { _ in
                triggerMarkerPreview(
                    timeOffset: timeOffset,
                    totalLength: totalLength,
                    isHorizontal: isHorizontal,
                    dayStart: dayStart,
                    totalSec: totalSec
                )
            }
            // 4. 단일 마우스 좌표 센서
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    // 물리 바 두께 범위 검사
                    let effectiveThickness = isBarHovered && settings.expandOnHover ? settings.hoverWidth : settings.barWidth
                    let isWithinPhysicalBar: Bool
                    switch settings.barPosition {
                    case .left:
                        isWithinPhysicalBar = location.x >= 0 && location.x <= effectiveThickness
                    case .right:
                        isWithinPhysicalBar = location.x >= (geometry.size.width - effectiveThickness) && location.x <= geometry.size.width
                    case .bottom:
                        isWithinPhysicalBar = location.y >= (geometry.size.height - effectiveThickness) && location.y <= geometry.size.height
                    }

                    guard isWithinPhysicalBar else {
                        if isBarHovered {
                            isBarHovered = false
                            hoveredActiveId = nil
                            hoveredFocusId = nil
                            PopoverPanel.shared.hide(delayed: true)
                        }
                        return
                    }

                    isBarHovered = true
                    let cursorCoord = isHorizontal ? location.x : location.y

                    let isRemindersActive = settings.enableReminders && reminderService.isAuthorized()

                    // 현재 시각 인디케이터 인접 감지 (12px 이내)
                    if let timePos = timeOffset, abs(cursorCoord - timePos) <= 12 {
                        if hoveredActiveId != "__TIME_TOOLTIP__" {
                            hoveredActiveId = "__TIME_TOOLTIP__"
                            hoveredFocusId = nil
                            PopoverPanel.shared.showTimeTooltip(
                                currentTime: currentTime,
                                timeOffset: timePos,
                                isHorizontal: isHorizontal,
                                barPosition: settings.barPosition,
                                settings: settings
                            )
                        }
                    } else if settings.enableReminders, let reminderMatch = resolveHoveredReminder(
                        at: cursorCoord,
                        dayStart: dayStart,
                        totalSec: totalSec,
                        totalLength: totalLength
                    ) {
                        let markerId = "__REMINDER_\(reminderMatch.reminder.id)__"
                        if hoveredActiveId != markerId {
                            hoveredActiveId = markerId
                            hoveredFocusId = nil
                            PopoverPanel.shared.showReminderTooltip(
                                reminder: reminderMatch.reminder,
                                offset: reminderMatch.pos,
                                isHorizontal: isHorizontal,
                                barPosition: settings.barPosition,
                                settings: settings
                            )
                        }
                    } else if !calendarService.isAuthorized() && !isRemindersActive {
                        // 캘린더 접근 권한이 없고, 활성 미리알림도 없는 경우 설정 안내 팝오버를 띄웁니다.
                        if hoveredActiveId != "__PERMISSION_NOTICE__" {
                            hoveredActiveId = "__PERMISSION_NOTICE__"
                            hoveredFocusId = nil
                            PopoverPanel.shared.showPermissionNotice(
                                cursorOffset: cursorCoord,
                                isHorizontal: isHorizontal,
                                barPosition: settings.barPosition,
                                settings: settings
                            )
                        }
                    } else if calendarService.events.isEmpty {
                        // 오늘 등록된 일정이 없을 때(또는 캘린더 권한은 없지만 미리알림이 활성화된 경우): 빈 상태 툴팁을 띄웁니다.
                        let hasCalendars = calendarService.isAuthorized() && !calendarService.allCalendars.isEmpty
                        let clusterId = hasCalendars ? "__EMPTY_SCHEDULE_TOOLTIP__" : "__NO_CALENDARS_TOOLTIP__"
                        if hoveredActiveId != clusterId {
                            hoveredActiveId = clusterId
                            hoveredFocusId = nil
                            PopoverPanel.shared.showEmptyScheduleTooltip(
                                cursorOffset: cursorCoord,
                                allDayEvents: [],
                                outOfRangeEvents: [],
                                hasTimedEventsInRange: false,
                                hasConnectedCalendars: hasCalendars,
                                isHorizontal: isHorizontal,
                                barPosition: settings.barPosition,
                                settings: settings
                            )
                        }
                    } else if let resolved = resolveHoveredEvents(
                        at: cursorCoord,
                        allEvents: calendarService.events,
                        dayStart: dayStart,
                        totalSec: totalSec,
                        totalLength: totalLength
                    ) {
                        if hoveredActiveId != resolved.activeId {
                            hoveredActiveId = resolved.activeId
                            hoveredFocusId = resolved.focusId
                            PopoverPanel.shared.show(
                                events: resolved.events,
                                allDayEvents: resolved.allDayEvents,
                                clusterId: resolved.activeId,
                                blockOffset: resolved.startOffset,
                                blockLength: resolved.length,
                                isHorizontal: isHorizontal,
                                barPosition: settings.barPosition,
                                settings: settings
                            )
                        }
                    } else {
                        // 마우스가 일정 블록 바깥에 있을 때는 종일 일정 또는 범위 외 일정을 표시합니다.
                        let allDayEvents = calendarService.events.filter { $0.isAllDay }
                        let timedEvents = calendarService.events.filter { !$0.isAllDay }
                        let hasTimedEventsInRange = timedEvents.contains { $0.endDate > dayStart && $0.startDate < dayEnd }
                        let outOfRangeEvents = timedEvents.filter { $0.endDate <= dayStart || $0.startDate >= dayEnd }

                        if !allDayEvents.isEmpty || (!hasTimedEventsInRange && !outOfRangeEvents.isEmpty) {
                            let clusterId = "__SCHEDULE_STATUS_TOOLTIP__" +
                                allDayEvents.map(\.id).sorted().joined(separator: "_") +
                                outOfRangeEvents.map(\.id).sorted().joined(separator: "_") +
                                "_\(hasTimedEventsInRange)_\(settings.eventHoverStyle.rawValue)"

                            if hoveredActiveId != clusterId {
                                hoveredActiveId = clusterId
                                hoveredFocusId = nil
                                PopoverPanel.shared.showEmptyScheduleTooltip(
                                    cursorOffset: cursorCoord,
                                    allDayEvents: allDayEvents,
                                    outOfRangeEvents: outOfRangeEvents,
                                    hasTimedEventsInRange: hasTimedEventsInRange,
                                    isHorizontal: isHorizontal,
                                    barPosition: settings.barPosition,
                                    settings: settings
                                )
                            }
                        } else if hoveredActiveId != nil {
                            hoveredActiveId = nil
                            hoveredFocusId = nil
                            PopoverPanel.shared.hide(delayed: true)
                        }
                    }

                case .ended:
                    isBarHovered = false
                    hoveredActiveId = nil
                    hoveredFocusId = nil
                    PopoverPanel.shared.hide(delayed: true)
                }
            }
            .animation(.spring(response: 0.18, dampingFraction: 0.85), value: isBarHovered)
            .onTapGesture(count: 2) {
                openSettingsWindow()
            }
            .contextMenu {
                Button(L10n.tr(.settings, lang: settings.language)) {
                    openSettingsWindow()
                }

                Button(L10n.tr(.refresh, lang: settings.language)) {
                    calendarService.refreshSources()
                    calendarService.loadCalendars()
                    calendarService.fetchEvents(settings: settings)
                }

                Divider()

                Button(L10n.tr(.quit, lang: settings.language)) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .onAppear {
            updateSegments()
            checkFirstLaunchWelcomeEffect()
        }
        .onReceive(calendarService.$events) { _ in
            updateSegments()
        }
        .onReceive(settings.$startHour) { _ in updateSegments() }
        .onReceive(settings.$startMinute) { _ in updateSegments() }
        .onReceive(settings.$endHour) { _ in updateSegments() }
        .onReceive(settings.$endMinute) { _ in updateSegments() }
        .onReceive(settings.$is24HourMode) { _ in updateSegments() }
        .onReceive(Self.clockPublisher) { input in
            let wasSameDay = Calendar.current.isDate(currentTime, inSameDayAs: input)
            if !wasSameDay {
                calendarService.fetchEvents(settings: settings)
                updateSegments()
            }

            // 마우스 호버 중이 아닐 때는 15초마다 시간을 갱신해 유휴 상태의 렌더링 부하를 줄입니다.
            let isHovered = isBarHovered || panelState.isPetProximityHovered
            let currentSec = Int(currentTime.timeIntervalSince1970)
            let inputSec = Int(input.timeIntervalSince1970)
            if isHovered || (inputSec / 15 != currentSec / 15) || !wasSameDay {
                currentTime = input
            }

            // 정각 알림과 일정 시작 알림은 1초 단위로 정확히 확인합니다.
            checkEventContactEffect(at: input)
            checkPreEventAlert(at: input)
        }
        .onReceive(NotificationCenter.default.publisher(for: .previewEventContactEffect)) { _ in
            activeEffectType = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                activeEffectId = UUID()
                activeEffectType = settings.eventTriggerEffectType
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .previewPreEventAlert)) { _ in
            previewPreEventAlertPulse()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)) { _ in
            // 스페이스 전환 / 미션컨트롤 발생 시 재생 중이던 이펙트 즉시 소멸
            activeEffectType = nil
        }
    }

    // 00초 정각 일정 시작 접점 및 매시간 정각 알림 감지 (1.0초 마이크로 이펙트 트리거)
    private func checkEventContactEffect(at time: Date) {
        guard settings.enableEventTriggerEffect, activeEffectType == nil else { return }

        // 현재 시각이 타임라인 표시 범위 내에 있을 때만 이펙트를 트리거합니다 (인디케이터 미렌더 시 고착 방지).
        let dayStart = settings.startDate(for: time)
        let dayEnd = settings.endDate(for: time)
        guard time >= dayStart && time <= dayEnd else { return }

        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        let second = calendar.component(.second, from: time)

        // 1. 캘린더 일정 시작 접점 알림 (최우선 순위)
        for event in calendarService.events where !event.isAllDay {
            let diff = abs(time.timeIntervalSince(event.startDate))
            if diff <= 2.5 {
                let eventKey = "\(event.id)_\(Int(event.startDate.timeIntervalSince1970))"
                if lastTriggeredEventKey != eventKey {
                    let isCoolingDown = lastTriggeredEventDate.map { time.timeIntervalSince($0) < 180 } ?? false
                    guard !isCoolingDown else { continue }

                    lastTriggeredEventKey = eventKey
                    lastTriggeredEventDate = time
                    lastTriggeredHourlyHour = currentHour // 정각 접점 알림 발동 시 해당 시간 정각 차임 중복 억제
                    triggerActiveEffect(settings.eventTriggerEffectType)
                    return
                }
            }
        }

        // 2. 매시간 정각 알림 (00분 00초 ~ 04초 윈도우 보장)
        if settings.enableHourlyAlertEffect && minute == 0 && second <= 4 {
            if lastTriggeredHourlyHour != currentHour {
                let isCoolingDown = lastTriggeredHourlyDate.map { time.timeIntervalSince($0) < 180 } ?? false
                if !isCoolingDown {
                    lastTriggeredHourlyHour = currentHour
                    lastTriggeredHourlyDate = time
                    triggerActiveEffect(settings.eventTriggerEffectType)
                    return
                }
            }
        }
    }

    private func triggerActiveEffect(_ type: EventTriggerEffectType) {
        guard settings.enableEventTriggerEffect else { return }
        let effectId = UUID()
        activeEffectId = effectId
        activeEffectType = type

        // 안전 타이머: 1.5초 후 동일 효과에 한해 상태 자동 초기화
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if self.activeEffectId == effectId {
                self.activeEffectType = nil
            }
        }
    }

    // 앱 최초 실행 온보딩 환영 앰비언트 이펙트 (1회성 1.0초 방전)
    private func checkFirstLaunchWelcomeEffect() {
        guard settings.enableEventTriggerEffect else { return }
        let key = "hasShownFirstLaunchWelcomeEffect"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            triggerActiveEffect(settings.eventTriggerEffectType)
        }
    }

    // 일정 시작 전 알림 감지 (설정된 5/10/15/20분 전 1회 은은한 바 펄스 트리거)
    private func checkPreEventAlert(at time: Date) {
        guard settings.enablePreEventAlert else { return }
        let targetLeadSec = Double(settings.preEventAlertMinutes * 60)

        for event in calendarService.events where !event.isAllDay {
            let remainingSec = event.startDate.timeIntervalSince(time)
            if abs(remainingSec - targetLeadSec) <= 2.5 {
                let eventKey = "pre_\(event.id)_\(Int(event.startDate.timeIntervalSince1970))"
                if lastTriggeredPreAlertEventKey != eventKey {
                    lastTriggeredPreAlertEventKey = eventKey

                    if let matchedSegment = cachedSegments.first(where: { $0.events.contains(where: { $0.id == event.id }) }) {
                        triggerSegmentPulse(segmentId: matchedSegment.id)
                    }
                    return
                }
            }
        }
    }

    private func triggerSegmentPulse(segmentId: String) {
        withAnimation(.easeInOut(duration: 0.75).repeatCount(2, autoreverses: true)) {
            pulsingSegmentId = segmentId
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
            withAnimation(.easeOut(duration: 0.3)) {
                if pulsingSegmentId == segmentId {
                    pulsingSegmentId = nil
                }
            }
        }
    }

    private func previewPreEventAlertPulse() {
        if let target = cachedSegments.first(where: { $0.end >= currentTime }) ?? cachedSegments.last {
            triggerSegmentPulse(segmentId: target.id)
        } else {
            let sampleEvent = CalendarEvent(
                id: "preview_event",
                rawTitle: "NudgeLine",
                startDate: currentTime,
                endDate: currentTime.addingTimeInterval(1800),
                isAllDay: false,
                calendarTitle: "Preview",
                defaultColor: .blue
            )
            let cluster = EventCluster(
                id: "preview_cluster",
                start: currentTime,
                end: currentTime.addingTimeInterval(1800),
                events: [sampleEvent]
            )
            let sampleSegment = TimelineSegment(
                id: "preview_segment",
                start: currentTime,
                end: currentTime.addingTimeInterval(1800),
                events: [sampleEvent],
                cluster: cluster
            )
            cachedSegments = [sampleSegment]
            triggerSegmentPulse(segmentId: sampleSegment.id)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                updateSegments()
            }
        }
    }

    private func updateSegments() {
        let dayStart = settings.startDate(for: currentTime)
        let dayEnd = settings.endDate(for: currentTime)
        cachedSegments = CalendarEvent.buildSegments(from: calendarService.events, dayStart: dayStart, dayEnd: dayEnd)
    }

    private var alignmentForPosition: Alignment {
        switch settings.barPosition {
        case .left: return .topLeading
        case .right: return .topTrailing
        case .bottom: return .bottomLeading
        }
    }

    private func calculateTimeOffset(time: Date, dayStart: Date, totalSec: TimeInterval, totalLength: CGFloat) -> CGFloat {
        let sec = max(0, min(totalSec, time.timeIntervalSince(dayStart)))
        let ratio = CGFloat(sec / totalSec)
        return round(ratio * totalLength)
    }

    // 호버 커서 좌표 기반 일정 탐색 (최단 시간 일정 우선 포커스)
    private func resolveHoveredEvents(
        at coord: CGFloat,
        allEvents: [CalendarEvent],
        dayStart: Date,
        totalSec: TimeInterval,
        totalLength: CGFloat
    ) -> (events: [CalendarEvent], allDayEvents: [CalendarEvent], activeId: String, startOffset: CGFloat, length: CGFloat, focusId: String)? {
        guard totalLength > 0, totalSec > 0 else { return nil }
        let progress = max(0.0, min(1.0, coord / totalLength))
        let cursorTime = dayStart.addingTimeInterval(progress * totalSec)

        // 1. 커서 시각 포함 일정 탐색
        let matchedEvents = allEvents.filter { event in
            if event.isAllDay { return false }
            return event.startDate <= cursorTime.addingTimeInterval(30) && event.endDate >= cursorTime.addingTimeInterval(-30)
        }

        let allDayEvents = allEvents.filter { $0.isAllDay }

        if !matchedEvents.isEmpty {
            // 중첩 일정 중 소요 시간이 가장 짧은 일정을 포커스 타깃으로 선정
            let focused = matchedEvents.min(by: {
                $0.endDate.timeIntervalSince($0.startDate) < $1.endDate.timeIntervalSince($1.startDate)
            }) ?? matchedEvents[0]

            let startOffset = calculateTimeOffset(time: max(dayStart, focused.startDate), dayStart: dayStart, totalSec: totalSec, totalLength: totalLength)
            let endOffset = calculateTimeOffset(time: min(dayStart.addingTimeInterval(totalSec), focused.endDate), dayStart: dayStart, totalSec: totalSec, totalLength: totalLength)
            let length = max(4.0, round(endOffset - startOffset))

            // [안 D 적용: 시간 일정과 종일 일정 분리 전달]
            // - 원인/배경: 시간 일정 카드에 종일 일정을 풀 카드로 합치면 카드 높이가 폭증하고 말풍선 꼬리가 바 아래로 이탈함
            // - 해결 방법: 메인 카드 events에는 순수 시간 일정(matchedEvents)만 전달하고, 종일 일정은 allDayEvents로 분리 전달하여 1줄 미니 인라인 칩으로만 표출
            // - 기대 효과: 카드가 슬림하게 유지되어 화면 이탈 0% 및 말풍선 꼬리가 시간 블록 중앙을 100% 정밀 조준
            let activeId = matchedEvents.map(\.id).sorted().joined(separator: "+")

            return (matchedEvents, allDayEvents, activeId, startOffset, length, focused.id)
        }

        // 2. 얇은 일정 인접 호버 허용 오차 보정 (±4px)
        for event in allEvents where !event.isAllDay {
            let start = calculateTimeOffset(time: max(dayStart, event.startDate), dayStart: dayStart, totalSec: totalSec, totalLength: totalLength)
            let end = calculateTimeOffset(time: min(dayStart.addingTimeInterval(totalSec), event.endDate), dayStart: dayStart, totalSec: totalSec, totalLength: totalLength)
            if coord >= (start - 4) && coord <= (end + 4) {
                let length = max(4.0, round(end - start))
                return ([event], allDayEvents, event.id, start, length, event.id)
            }
        }

        return nil
    }

    @ViewBuilder
    private func renderSegment(
        segment: TimelineSegment,
        dayStart: Date,
        totalSec: TimeInterval,
        totalLength: CGFloat,
        isHorizontal: Bool
    ) -> some View {
        let segOffset = calculateTimeOffset(time: segment.start, dayStart: dayStart, totalSec: totalSec, totalLength: totalLength)
        let segEndOffset = calculateTimeOffset(time: segment.end, dayStart: dayStart, totalSec: totalSec, totalLength: totalLength)
        let segLength = max(1.0, round(segEndOffset - segOffset))

        SegmentBlockView(
            segment: segment,
            settings: settings,
            hoveredFocusId: hoveredFocusId,
            length: segLength,
            isHorizontal: isHorizontal,
            currentTime: currentTime,
            isPulsing: pulsingSegmentId == segment.id,
            isDark: isDark
        )
        .offset(
            x: isHorizontal ? segOffset : 0,
            y: isHorizontal ? 0 : segOffset
        )
    }

    @ViewBuilder
    private func backgroundTrack(thickness: CGFloat, length: CGFloat, isHorizontal: Bool, isDark: Bool) -> some View {
        let lightTrackColor = Color(red: 0.14, green: 0.15, blue: 0.18).opacity(max(0.16, settings.trackOpacity))
        let darkTrackColor = Color.black.opacity(settings.trackOpacity)
        let borderStrokeColor = isDark ? Color.white.opacity(0.15) : Color.black.opacity(0.20)

        Group {
            switch settings.barStyleMode {
            case .adaptive:
                Rectangle()
                    .fill(isDark ? darkTrackColor : lightTrackColor)
                    .overlay(
                        Rectangle().stroke(borderStrokeColor, lineWidth: 0.5)
                    )

            case .dark:
                Rectangle()
                    .fill(darkTrackColor)
                    .overlay(
                        Rectangle().stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )

            case .light:
                Rectangle()
                    .fill(lightTrackColor)
                    .overlay(
                        Rectangle().stroke(Color.black.opacity(0.20), lineWidth: 0.5)
                    )

            case .custom:
                Rectangle()
                    .fill(settings.effectiveTrackColor().opacity(settings.trackOpacity))
                    .overlay(
                        Rectangle().stroke(borderStrokeColor, lineWidth: 0.5)
                    )
            }
        }
        .frame(
            width: isHorizontal ? length : thickness,
            height: isHorizontal ? thickness : length
        )
    }

    private func calculateCurrentTimeOffset(dayStart: Date, totalSec: TimeInterval, totalLength: CGFloat) -> CGFloat? {
        let currentSec = currentTime.timeIntervalSince(dayStart)
        guard currentSec >= 0 && currentSec <= totalSec else { return nil }

        let ratio = CGFloat(currentSec / totalSec)
        return round(ratio * totalLength)
    }

    // MARK: - 미리알림 마커 렌더링 및 호버 감지 헬퍼
    @ViewBuilder
    private func renderReminder(
        reminder: ReminderItem,
        dayStart: Date,
        totalSec: TimeInterval,
        totalLength: CGFloat,
        isHorizontal: Bool
    ) -> some View {
        let secFromStart = reminder.dueDate.timeIntervalSince(dayStart)
        if secFromStart >= 0 && secFromStart <= totalSec {
            let diffMinutes = reminder.dueDate.timeIntervalSince(currentTime) / 60.0
            let isWithinRange = settings.reminderProximityMinutes >= 1440 ||
                (diffMinutes <= Double(settings.reminderProximityMinutes) && diffMinutes >= -10.0)
            if isWithinRange {
                let ratio = CGFloat(secFromStart / totalSec)
                let pos = round(ratio * totalLength)
                let isHovered = hoveredActiveId == "__REMINDER_\(reminder.id)__"
                let offsets = markerOffsets(pos: pos, isApproaching: true)

                ReminderMarkerView(
                    reminder: reminder,
                    isApproaching: true,
                    isHovered: isHovered,
                    symbol: settings.reminderMarkerStyle.symbolName,
                    barPosition: settings.barPosition,
                    isHorizontal: isHorizontal,
                    isDark: isDark
                )
                .offset(x: offsets.x, y: offsets.y)
            }
        }
    }

    // MARK: - 미리알림 마커 미리보기 헬퍼
    // [원인/배경: 설정창에서 마커 스타일 변경 시 타임라인 상의 시각적 외형 확인 필요 -> 해결 방법: 설정된 근접 타이밍에 맞춰 미래 시점 타임라인 좌표를 계산하고, 0.4초 시차 팝업 및 3.2초 페이드아웃 적용 -> 기대 효과: 이동 글리치 없이 직관적인 시각 피드백 제공]
    @ViewBuilder
    private func renderPreviewMarker(
        totalLength: CGFloat,
        isHorizontal: Bool
    ) -> some View {
        let offsets = markerOffsets(pos: previewMarkerPos, isApproaching: true)
        let sampleReminder = ReminderItem(
            id: "__PREVIEW_REMINDER__",
            title: settings.language.isKorean ? "주요 마일스톤 점검" : "Milestone Review",
            dueDate: Date().addingTimeInterval(1800),
            listIdentifier: "preview",
            listTitle: settings.language.isKorean ? "미리알림" : "Reminders",
            color: .orange,
            notes: nil,
            url: nil,
            priority: 1,
            isCompleted: false
        )

        ReminderMarkerView(
            reminder: sampleReminder,
            isApproaching: true,
            isHovered: true,
            symbol: settings.reminderMarkerStyle.symbolName,
            barPosition: settings.barPosition,
            isHorizontal: isHorizontal,
            isDark: isDark
        )
        .offset(x: offsets.x, y: offsets.y)
        .transition(.scale.combined(with: .opacity))
    }

    private func triggerMarkerPreview(
        timeOffset: CGFloat?,
        totalLength: CGFloat,
        isHorizontal: Bool,
        dayStart: Date,
        totalSec: TimeInterval
    ) {
        let proximity = settings.reminderProximityMinutes
        let previewMinutes: Double = (proximity > 0 && proximity < 1440) ? Double(proximity) : 60.0
        let previewDueDate = currentTime.addingTimeInterval(previewMinutes * 60)

        let secFromStart = previewDueDate.timeIntervalSince(dayStart)
        let targetPos: CGFloat
        if totalSec > 0 && secFromStart >= 0 && secFromStart <= totalSec {
            targetPos = round(CGFloat(secFromStart / totalSec) * totalLength)
        } else {
            targetPos = min(totalLength - 30, (timeOffset ?? (totalLength * 0.45)) + 45)
        }

        // 1. 위치 선할당 (이동 글리치 차단)
        previewMarkerPos = targetPos

        // 2. 마커 팝업 출현 (0.0초)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            isPreviewingMarker = true
        }

        let sampleReminder = ReminderItem(
            id: "__PREVIEW_REMINDER__",
            title: settings.language.isKorean ? "주요 마일스톤 점검" : "Milestone Review",
            dueDate: previewDueDate,
            listIdentifier: "preview",
            listTitle: settings.language.isKorean ? "미리알림" : "Reminders",
            color: .orange,
            notes: nil,
            url: nil,
            priority: 1,
            isCompleted: false
        )

        // 3. 0.4초 시차 후 풍선도움말 출현
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [self] in
            guard self.isPreviewingMarker else { return }
            PopoverPanel.shared.showReminderTooltip(
                reminder: sampleReminder,
                offset: targetPos,
                isHorizontal: isHorizontal,
                barPosition: settings.barPosition,
                settings: settings
            )
        }

        // 4. 3.2초 후 마커와 팝오버 동시 페이드아웃 및 정리
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation(.easeOut(duration: 0.25)) {
                self.isPreviewingMarker = false
            }
            PopoverPanel.shared.hide(delayed: false)
        }
    }

    // MARK: - 미리알림 마커 위치 오프셋 계산
    // [원인/배경: 깃발 마커 50% 축소 요구(12px -> 6px) 반영 -> 해결 방법: 마커 규격을 6px로 축소하고, 바 경계선 1px 바 걸침 및 5px 안쪽 돌출 정밀 오프셋 수식 재조정 -> 기대 효과: 타임라인 바의 초슬림 앰비언트 규격과 완벽한 비례감 확보]
    private func markerOffsets(pos: CGFloat, isApproaching: Bool) -> (x: CGFloat, y: CGFloat) {
        let size: CGFloat = isApproaching ? 6.0 : 3.0
        let half = size / 2.0
        if isApproaching {
            switch settings.barPosition {
            case .bottom:
                // 하단 바: 깃봉 하단 1px가 바 상단에 꽂히고 화면 위쪽으로 5px 돌출
                let x = pos - half
                let y = -settings.barWidth + 1.0
                return (x, y)
            case .left:
                // 좌측 바: 깃봉 좌측 1px가 바 우측에 꽂히고 화면 오른쪽(안쪽)으로 5px 돌출 (90도 회전)
                let x = settings.barWidth - 1.0
                let y = pos - half
                return (x, y)
            case .right:
                // 우측 바: 깃봉 우측 1px가 바 좌측에 꽂히고 화면 왼쪽(안쪽)으로 5px 돌출 (-90도 회전)
                let x = -settings.barWidth + 1.0
                let y = pos - half
                return (x, y)
            }
        } else {
            // 평상시(잠복기 3px 다이아몬드 노치): 바 중심축 정렬
            switch settings.barPosition {
            case .bottom:
                let x = pos - half
                let y = -(settings.barWidth - size) / 2.0
                return (x, y)
            case .left:
                let x = (settings.barWidth - size) / 2.0
                let y = pos - half
                return (x, y)
            case .right:
                let x = -(settings.barWidth - size) / 2.0
                let y = pos - half
                return (x, y)
            }
        }
    }

    private func resolveHoveredReminder(
        at cursorCoord: CGFloat,
        dayStart: Date,
        totalSec: TimeInterval,
        totalLength: CGFloat
    ) -> (reminder: ReminderItem, pos: CGFloat)? {
        for reminder in reminderService.reminders {
            let sec = reminder.dueDate.timeIntervalSince(dayStart)
            guard sec >= 0 && sec <= totalSec else { continue }
            let diffMinutes = reminder.dueDate.timeIntervalSince(currentTime) / 60.0
            let isWithinRange = settings.reminderProximityMinutes >= 1440 ||
                (diffMinutes <= Double(settings.reminderProximityMinutes) && diffMinutes >= -10.0)
            guard isWithinRange else { continue }

            let pos = round(CGFloat(sec / totalSec) * totalLength)
            if abs(cursorCoord - pos) <= 12 {
                return (reminder, pos)
            }
        }
        return nil
    }

    private func openSettingsWindow() {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.openSettings()
        }
    }
}

// MARK: - 일정 세그먼트 블록 뷰
private struct SegmentBlockView: View {
    let segment: TimelineSegment
    @ObservedObject var settings: AppSettings
    let hoveredFocusId: String?
    let length: CGFloat
    let isHorizontal: Bool
    let currentTime: Date
    let isPulsing: Bool
    let isDark: Bool

    var body: some View {
        let isHovered = hoveredFocusId != nil && segment.events.contains(where: { $0.id == hoveredFocusId })
        let isPast = settings.dimPastEvents && segment.end <= currentTime && !isPulsing
        let thickness = isPulsing ? max(settings.barWidth, 8) : (isHovered && settings.expandOnHover ? settings.hoverWidth : settings.barWidth)
        let isUltraThin = thickness <= 2
        let isInactive = segment.isInactive
        let activeEvents = segment.events.filter { !$0.isCanceledOrDeclined }
        let colors: [Color] = {
            if isInactive {
                return [Color.gray.opacity(isDark ? 0.35 : 0.45)]
            } else if !activeEvents.isEmpty {
                return activeEvents.map { $0.effectiveColor(settings: settings) }
            } else {
                return segment.events.map { $0.effectiveColor(settings: settings) }
            }
        }()
        let primaryColor = colors.first ?? .blue
        let segmentOpacity: Double = isInactive
            ? (isHovered ? 0.70 : (isDark ? 0.35 : 0.45))
            : ((isPast && !isHovered) ? (isDark ? 0.35 : 0.55) : 1.0)
        let segmentSaturation: Double = isInactive ? 0.2 : ((isPast && !isHovered) ? (isDark ? 0.35 : 0.60) : 1.0)

        Group {
            if segment.isOverlap {
                // 겹침 일정 호흡 크로스페이드 색상 전환
                if colors.count >= 2 {
                    CrossFadeOverlapView(colors: colors)
                } else {
                    primaryColor
                }
            } else {
                Rectangle()
                    .fill(primaryColor)
            }
        }
        .overlay(
            ZStack {
                if isHovered && settings.enableSegmentRim {
                    Rectangle()
                        .stroke(Color.white.opacity(0.95), lineWidth: 0.8)
                } else if !isUltraThin {
                    Rectangle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                }

                // 일정 시작 전 알림 브리딩 펄스 글로우 오버레이
                if isPulsing {
                    Rectangle()
                        .fill(Color.white.opacity(0.35))
                }

                // 세그먼트 구분선
                if isHorizontal {
                    HStack {
                        Rectangle().fill(Color.white.opacity(0.40)).frame(width: 1)
                        Spacer()
                        Rectangle().fill(Color.white.opacity(0.40)).frame(width: 1)
                    }
                } else {
                    VStack {
                        Rectangle().fill(Color.white.opacity(0.40)).frame(height: 1)
                        Spacer()
                        Rectangle().fill(Color.white.opacity(0.40)).frame(height: 1)
                    }
                }
            }
        )
        .shadow(
            color: isPulsing ? primaryColor.opacity(1.0) : ((isHovered && settings.enableSegmentGlow) ? primaryColor.opacity(0.9) : .clear),
            radius: isPulsing ? 14 : ((isHovered && settings.enableSegmentGlow) ? 4 : 0)
        )
        .opacity(segmentOpacity)
        .saturation(segmentSaturation)
        .frame(
            width: isHorizontal ? max(1, length) : thickness,
            height: isHorizontal ? thickness : max(1, length)
        )
        .animation(.easeInOut(duration: 0.18), value: isHovered)
        .animation(.easeInOut(duration: 0.25), value: isPast)
        .animation(.easeInOut(duration: 0.35), value: isPulsing)
        .allowsHitTesting(false)
    }
}

// MARK: - 겹침 일정 크로스페이드 색상 전환 뷰 (GPU 하드웨어 가속 보간, 0 CPU Timer)
private struct CrossFadeOverlapView: View {
    let colors: [Color]
    @State private var isFaded: Bool = false

    var body: some View {
        let first = colors.first ?? .blue
        let second = colors.count > 1 ? colors[1] : first

        ZStack {
            Rectangle().fill(first)
            if colors.count > 1 {
                Rectangle()
                    .fill(second)
                    .opacity(isFaded ? 1.0 : 0.0)
            }
        }
        .onAppear {
            if colors.count > 1 {
                withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                    isFaded = true
                }
            }
        }
    }
}

// MARK: - 현재 시각 표시자 뷰 (4종 기하 형태, 펫 마스코트 및 이벤트 접점 마이크로 이펙트)
private struct CurrentTimeIndicatorView: View {
    @ObservedObject var settings: AppSettings
    let thickness: CGFloat
    let isHorizontal: Bool
    let isBarHovered: Bool
    let isPetProximityHovered: Bool
    let accentColor: Color
    let activeEffectType: EventTriggerEffectType?
    let activeEffectId: UUID
    let onEffectComplete: @MainActor () -> Void
    let isDark: Bool

    var body: some View {
        ZStack(alignment: alignmentForPosition) {
            // 1. 일정 알림 마이크로 이펙트 (1.0초 점멸, 펫/인디케이터 뒤쪽 레이어)
            if let effect = activeEffectType {
                EventTriggerEffectView(
                    effectType: effect,
                    isHorizontal: isHorizontal,
                    barPosition: settings.barPosition,
                    onComplete: onEffectComplete
                )
                .id(activeEffectId)
                .offset(
                    x: effectOffsetX,
                    y: effectOffsetY
                )
            }

            // 2. 기하 인디케이터 형태
            indicatorShapeView()

            // 3. 대롱대롱 펫 마스코트
            if settings.isPetEnabled {
                petCompanionView()
            }
        }
        .allowsHitTesting(false)
    }

    private var effectOffsetX: CGFloat {
        let size = EventTriggerEffectView.canvasSize
        switch settings.barPosition {
        case .left, .right:
            return 0
        case .bottom:
            return -size / 2.0
        }
    }

    private var effectOffsetY: CGFloat {
        let size = EventTriggerEffectView.canvasSize
        switch settings.barPosition {
        case .left, .right:
            return -size / 2.0
        case .bottom:
            return 0
        }
    }

    private var alignmentForPosition: Alignment {
        switch settings.barPosition {
        case .left: return .topLeading
        case .right: return .topTrailing
        case .bottom: return .bottomLeading
        }
    }

    @ViewBuilder
    private func indicatorShapeView() -> some View {
        let isLeft = settings.barPosition == .left
        let isRight = settings.barPosition == .right
        let hasRim = settings.enableIndicatorRim
        let hasGlow = settings.enableIndicatorGlow
        let rimColor = Color.white.opacity(0.95)
        let ringRimColor = Color.white.opacity(0.9)

        Group {
            switch settings.currentTimeIndicatorStyle {
            case .triangleTick:
                // 타입 3: 삼각 틱
                TriangleTickShape(position: settings.barPosition, thickness: thickness)
                    .fill(accentColor)
                    .overlay(
                        hasRim ? TriangleTickShape(position: settings.barPosition, thickness: thickness).stroke(rimColor, lineWidth: 0.8) : nil
                    )
                    .shadow(color: hasGlow ? accentColor.opacity(0.9) : .clear, radius: 4)
                    .frame(
                        width: isHorizontal ? 7 : thickness + 5,
                        height: isHorizontal ? thickness + 5 : 7
                    )
                    .offset(
                        x: isHorizontal ? -3.5 : 0,
                        y: isHorizontal ? 0 : -3.5
                    )

            case .roundDome:
                // 타입 2: 라운드 돔
                RoundDomeShape(position: settings.barPosition, thickness: thickness)
                    .fill(accentColor)
                    .overlay(
                        hasRim ? RoundDomeShape(position: settings.barPosition, thickness: thickness).stroke(rimColor, lineWidth: 0.8) : nil
                    )
                    .shadow(color: hasGlow ? accentColor.opacity(0.9) : .clear, radius: 4)
                    .frame(
                        width: isHorizontal ? 10 : thickness + 6,
                        height: isHorizontal ? thickness + 6 : 10
                    )
                    .offset(
                        x: isHorizontal ? -5.0 : 0,
                        y: isHorizontal ? 0 : -5.0
                    )

            case .block:
                // 타입 1: 돌출 블록
                Rectangle()
                    .fill(accentColor)
                    .overlay(
                        hasRim ? Rectangle().stroke(rimColor, lineWidth: 0.8) : nil
                    )
                    .shadow(color: hasGlow ? accentColor.opacity(0.9) : .clear, radius: 4)
                    .frame(
                        width: isHorizontal ? 4 : thickness + 5,
                        height: isHorizontal ? thickness + 5 : 4
                    )
                    .offset(
                        x: isHorizontal ? -2.0 : 0,
                        y: isHorizontal ? 0 : -2.0
                    )

            case .pointRing:
                // 타입 4: 포인트 링
                Circle()
                    .stroke(accentColor, lineWidth: 2.0)
                    .overlay(
                        hasRim ? Circle().stroke(ringRimColor, lineWidth: 0.6) : nil
                    )
                    .frame(width: 9, height: 9)
                    .shadow(color: hasGlow ? accentColor.opacity(0.95) : .clear, radius: 4)
                    .offset(
                        x: isHorizontal ? -4.5 : (isLeft ? (thickness / 2 - 4.5) : (isRight ? (-thickness / 2 - 4.5) : 0)),
                        y: isHorizontal ? (-thickness / 2 - 4.5) : -4.5
                    )
            }
        }
    }

    @ViewBuilder
    private func petCompanionView() -> some View {
        let isProximityNear = isPetProximityHovered
        switch settings.selectedPetType {
        case .calicoCat:
            InteractivePetView(
                petType: .calicoCat,
                isHorizontal: isHorizontal,
                isBarHovered: isBarHovered,
                isPetProximityHovered: isProximityNear,
                settings: settings,
                thickness: thickness,
                accentColor: accentColor
            )
        case .jindoDog:
            InteractivePetView(
                petType: .jindoDog,
                isHorizontal: isHorizontal,
                isBarHovered: isBarHovered,
                isPetProximityHovered: isProximityNear,
                settings: settings,
                thickness: thickness,
                accentColor: accentColor
            )
        case .whiteTiger:
            InteractivePetView(
                petType: .whiteTiger,
                isHorizontal: isHorizontal,
                isBarHovered: isBarHovered,
                isPetProximityHovered: isProximityNear,
                settings: settings,
                thickness: thickness,
                accentColor: accentColor
            )
        case .custom:
            if let petId = settings.selectedCustomPetId {
                InteractiveCustomPetView(
                    petId: petId,
                    isHorizontal: isHorizontal,
                    isBarHovered: isBarHovered,
                    isPetProximityHovered: isProximityNear,
                    settings: settings,
                    thickness: thickness,
                    accentColor: accentColor
                )
            } else {
                InteractivePetView(
                    petType: .whiteTiger,
                    isHorizontal: isHorizontal,
                    isBarHovered: isBarHovered,
                    isPetProximityHovered: isProximityNear,
                    settings: settings,
                    thickness: thickness,
                    accentColor: accentColor
                )
            }
        }
    }
}

// MARK: - 삼각 틱 Shape
private struct TriangleTickShape: Shape {
    let position: BarPosition
    let thickness: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch position {
        case .left:
            // Base at x=0..thickness, Tip points right to rect.maxX
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: thickness, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: thickness, y: rect.maxY))
            path.addLine(to: CGPoint(x: 0, y: rect.maxY))
            path.closeSubpath()
        case .right:
            // Base at x=(rect.maxX - thickness)..rect.maxX, Tip points left to rect.minX
            path.move(to: CGPoint(x: rect.maxX, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX - thickness, y: 0))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX - thickness, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        case .bottom:
            // Base at y=(rect.maxY - thickness)..rect.maxY, Tip points up to rect.minY
            path.move(to: CGPoint(x: 0, y: rect.maxY))
            path.addLine(to: CGPoint(x: 0, y: rect.maxY - thickness))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - thickness))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}

// MARK: - 라운드 돔 Shape
private struct RoundDomeShape: Shape {
    let position: BarPosition
    let thickness: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch position {
        case .left:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: thickness, y: 0))
            path.addQuadCurve(to: CGPoint(x: thickness, y: rect.maxY), control: CGPoint(x: rect.maxX + 2, y: rect.midY))
            path.addLine(to: CGPoint(x: 0, y: rect.maxY))
            path.closeSubpath()
        case .right:
            path.move(to: CGPoint(x: rect.maxX, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX - thickness, y: 0))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - thickness, y: rect.maxY), control: CGPoint(x: rect.minX - 2, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        case .bottom:
            path.move(to: CGPoint(x: 0, y: rect.maxY))
            path.addLine(to: CGPoint(x: 0, y: rect.maxY - thickness))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY - thickness), control: CGPoint(x: rect.midX, y: rect.minY - 2))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}

// MARK: - 미리알림 시점 마커 뷰 (ReminderMarkerView)
// [원인/배경: 원형 배경 배지로 인한 시각적 답답함 및 방향성 부재 -> 해결 방법: 원형 배경을 제거하고 순수 심볼에 카테고리 색상/외곽 글로우 및 3대 바 포지션별 정밀 회전(하단 0도, 좌측 90도, 우측 -90도) 적용 -> 기대 효과: 바에 꽂힌 깃발 형태의 명확한 시각적 메타포 및 미려한 룩앤필 완성]
private struct ReminderMarkerView: View {
    let reminder: ReminderItem
    let isApproaching: Bool
    let isHovered: Bool
    let symbol: String
    let barPosition: BarPosition
    let isHorizontal: Bool
    let isDark: Bool

    private var rotationAngle: Double {
        switch barPosition {
        case .bottom: return 0.0
        case .left: return 90.0
        case .right: return -90.0
        }
    }

    var body: some View {
        if isApproaching {
            // 접근 시: 6x6px 순수 깃발 심볼 (바에 꽂혀 안쪽으로 펄럭이는 형태, 50% 축소 규격)
            Image(systemName: symbol)
                .font(.system(size: 6.0, weight: .bold))
                .foregroundStyle(reminder.color)
                .shadow(color: Color.black.opacity(isDark ? 0.6 : 0.3), radius: 0.6, x: 0, y: 0.5)
                .shadow(color: reminder.color.opacity(0.85), radius: 1.2)
                .rotationEffect(.degrees(rotationAngle))
                .frame(width: 6, height: 6)
                .scaleEffect(isHovered ? 1.25 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isApproaching)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
                .allowsHitTesting(false)
        } else {
            // 평상시(잠복기): 보물처럼 은은하게 빛나는 2.5px 다이아몬드 노치
            ZStack {
                Circle()
                    .fill(reminder.color.opacity(0.45))
                    .frame(width: 5, height: 5)
                    .blur(radius: 1.0)

                RoundedRectangle(cornerRadius: 0.8)
                    .fill(reminder.color)
                    .frame(width: 2.5, height: 2.5)
                    .rotationEffect(.degrees(45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 0.8)
                            .stroke(Color.white.opacity(0.7), lineWidth: 0.4)
                            .rotationEffect(.degrees(45))
                    )
            }
            .scaleEffect(isHovered ? 1.25 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isApproaching)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .allowsHitTesting(false)
        }
    }
}



// 화면 가장자리 타임라인 바 메인 뷰 (단일 마우스 호버 센서, 일정 렌더링, 현재 시각 표시자)
import SwiftUI
import Combine
import AppKit

public struct TimelineBarView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var calendarService: CalendarService
    @ObservedObject var panelState: OverlayPanelState

    @State private var currentTime = Date()
    @State private var cachedSegments: [TimelineSegment] = []
    @State private var hoveredFocusId: String? = nil
    @State private var hoveredActiveId: String? = nil
    @State private var isBarHovered = false

    private static let clockPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public init(
        settings: AppSettings = .shared,
        calendarService: CalendarService = .shared,
        panelState: OverlayPanelState = OverlayPanelState()
    ) {
        self.settings = settings
        self.calendarService = calendarService
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
                backgroundTrack(thickness: settings.barWidth, length: totalLength, isHorizontal: isHorizontal)

                // 2. 일정 세그먼트 렌더링
                ForEach(segments) { segment in
                    let segOffset = calculateTimeOffset(time: segment.start, dayStart: dayStart, totalSec: totalSec, totalLength: totalLength)
                    let segEndOffset = calculateTimeOffset(time: segment.end, dayStart: dayStart, totalSec: totalSec, totalLength: totalLength)
                    let segLength = max(1.0, round(segEndOffset - segOffset))

                    SegmentBlockView(
                        segment: segment,
                        settings: settings,
                        hoveredFocusId: hoveredFocusId,
                        length: segLength,
                        isHorizontal: isHorizontal
                    )
                    .offset(
                        x: isHorizontal ? segOffset : 0,
                        y: isHorizontal ? 0 : segOffset
                    )
                }

                // 3. 현재 시각 인디케이터
                if let pos = timeOffset {
                    CurrentTimeIndicatorView(
                        settings: settings,
                        thickness: currentThickness,
                        isHorizontal: isHorizontal,
                        isBarHovered: isBarHovered,
                        isPetProximityHovered: panelState.isPetProximityHovered,
                        accentColor: settings.effectiveCurrentTimeColor()
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

                    // 현재 시각 인디케이터 인접 감지 (12px 이내)
                    if let timePos = timeOffset, abs(cursorCoord - timePos) <= 12 {
                        if hoveredActiveId != "__TIME_TOOLTIP__" {
                            hoveredActiveId = "__TIME_TOOLTIP__"
                            hoveredFocusId = nil
                            PopoverPanel.shared.showTimeTooltip(
                                currentTime: currentTime,
                                settings: settings,
                                timeOffset: timePos,
                                isHorizontal: isHorizontal,
                                barPosition: settings.barPosition
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
                                clusterId: resolved.activeId,
                                blockOffset: resolved.startOffset,
                                blockLength: resolved.length,
                                isHorizontal: isHorizontal,
                                barPosition: settings.barPosition,
                                settings: settings
                            )
                        }
                    } else {
                        // 빈 배경 영역
                        if hoveredActiveId != nil {
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
            currentTime = input
            if !wasSameDay {
                calendarService.fetchEvents(settings: settings)
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
    ) -> (events: [CalendarEvent], activeId: String, startOffset: CGFloat, length: CGFloat, focusId: String)? {
        guard totalLength > 0, totalSec > 0 else { return nil }
        let progress = max(0.0, min(1.0, coord / totalLength))
        let cursorTime = dayStart.addingTimeInterval(progress * totalSec)

        // 1. 커서 시각 포함 일정 탐색
        let matchedEvents = allEvents.filter { event in
            if event.isAllDay { return false }
            return event.startDate <= cursorTime.addingTimeInterval(30) && event.endDate >= cursorTime.addingTimeInterval(-30)
        }

        if !matchedEvents.isEmpty {
            // 중첩 일정 중 소요 시간이 가장 짧은 일정을 포커스 타깃으로 선정
            let focused = matchedEvents.min(by: {
                $0.endDate.timeIntervalSince($0.startDate) < $1.endDate.timeIntervalSince($1.startDate)
            }) ?? matchedEvents[0]

            let startOffset = calculateTimeOffset(time: max(dayStart, focused.startDate), dayStart: dayStart, totalSec: totalSec, totalLength: totalLength)
            let endOffset = calculateTimeOffset(time: min(dayStart.addingTimeInterval(totalSec), focused.endDate), dayStart: dayStart, totalSec: totalSec, totalLength: totalLength)
            let length = max(4.0, round(endOffset - startOffset))
            let activeId = matchedEvents.map(\.id).sorted().joined(separator: "+")

            return (matchedEvents, activeId, startOffset, length, focused.id)
        }

        // 2. 얇은 일정 인접 호버 허용 오차 보정 (±4px)
        for event in allEvents where !event.isAllDay {
            let start = calculateTimeOffset(time: max(dayStart, event.startDate), dayStart: dayStart, totalSec: totalSec, totalLength: totalLength)
            let end = calculateTimeOffset(time: min(dayStart.addingTimeInterval(totalSec), event.endDate), dayStart: dayStart, totalSec: totalSec, totalLength: totalLength)
            if coord >= (start - 4) && coord <= (end + 4) {
                let length = max(4.0, round(end - start))
                return ([event], event.id, start, length, event.id)
            }
        }

        return nil
    }

    @ViewBuilder
    private func backgroundTrack(thickness: CGFloat, length: CGFloat, isHorizontal: Bool) -> some View {
        let hasBorder = thickness > 2
        Group {
            switch settings.barStyleMode {
            case .adaptive:
                Rectangle()
                    .fill(Color(NSColor.windowBackgroundColor).opacity(settings.trackOpacity))
                    .overlay(
                        hasBorder ? Rectangle().stroke(Color.primary.opacity(0.15), lineWidth: 0.5) : nil
                    )

            case .dark:
                Rectangle()
                    .fill(Color.black.opacity(settings.trackOpacity))
                    .overlay(
                        hasBorder ? Rectangle().stroke(Color.white.opacity(0.15), lineWidth: 0.5) : nil
                    )

            case .light:
                Rectangle()
                    .fill(Color.white.opacity(settings.trackOpacity))
                    .overlay(
                        hasBorder ? Rectangle().stroke(Color.black.opacity(0.15), lineWidth: 0.5) : nil
                    )

            case .custom:
                Rectangle()
                    .fill(settings.effectiveTrackColor().opacity(settings.trackOpacity))
                    .overlay(
                        hasBorder ? Rectangle().stroke(Color.white.opacity(0.15), lineWidth: 0.5) : nil
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

    private func openSettingsWindow() {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.openSettings()
        }
    }
}

// MARK: - 일정 세그먼트 블록 뷰
private struct SegmentBlockView: View {
    let segment: TimelineSegment
    let settings: AppSettings
    let hoveredFocusId: String?
    let length: CGFloat
    let isHorizontal: Bool

    var body: some View {
        let isHovered = hoveredFocusId != nil && segment.events.contains(where: { $0.id == hoveredFocusId })
        let thickness = isHovered && settings.expandOnHover ? settings.hoverWidth : settings.barWidth
        let isUltraThin = thickness <= 2
        let colors = segment.events.map { $0.effectiveColor(settings: settings) }
        let primaryColor = colors.first ?? .blue

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

                // 세그먼트 구분선
                if isHorizontal {
                    HStack {
                        Rectangle().fill(Color.black.opacity(0.75)).frame(width: 1)
                        Spacer()
                        Rectangle().fill(Color.black.opacity(0.75)).frame(width: 1)
                    }
                } else {
                    VStack {
                        Rectangle().fill(Color.black.opacity(0.75)).frame(height: 1)
                        Spacer()
                        Rectangle().fill(Color.black.opacity(0.75)).frame(height: 1)
                    }
                }
            }
        )
        .shadow(color: (isHovered && settings.enableSegmentGlow) ? primaryColor.opacity(0.9) : .clear, radius: 4)
        .frame(
            width: isHorizontal ? max(1, length) : thickness,
            height: isHorizontal ? thickness : max(1, length)
        )
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .allowsHitTesting(false)
    }
}

// MARK: - 겹침 일정 크로스페이드 색상 전환 뷰
private struct CrossFadeOverlapView: View {
    let colors: [Color]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 15.0)) { timeline in
            let count = max(1, colors.count)
            let cycleSeconds = 2.8
            let elapsed = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: cycleSeconds * Double(count))
            let currentIndex = Int(elapsed / cycleSeconds) % count
            let nextIndex = (currentIndex + 1) % count
            let subElapsed = elapsed.truncatingRemainder(dividingBy: cycleSeconds)
            let progress = CGFloat(subElapsed / cycleSeconds)

            let currColor = colors[safe: currentIndex] ?? .blue
            let nextColor = colors[safe: nextIndex] ?? .blue

            ZStack {
                Rectangle().fill(currColor)
                Rectangle().fill(nextColor).opacity(progress)
            }
        }
    }
}

// MARK: - 현재 시각 표시자 뷰 (4종 기하 형태 및 펫 마스코트)
private struct CurrentTimeIndicatorView: View {
    @ObservedObject var settings: AppSettings
    let thickness: CGFloat
    let isHorizontal: Bool
    let isBarHovered: Bool
    let isPetProximityHovered: Bool
    let accentColor: Color

    var body: some View {
        ZStack(alignment: alignmentForPosition) {
            // 1. 기하 인디케이터 형태
            indicatorShapeView()

            // 2. 대롱대롱 펫 마스코트
            if settings.isPetEnabled {
                petCompanionView()
            }
        }
        .allowsHitTesting(false)
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

        Group {
            switch settings.currentTimeIndicatorStyle {
            case .triangleTick:
                // 타입 3: 삼각 틱
                TriangleTickShape(position: settings.barPosition, thickness: thickness)
                    .fill(accentColor)
                    .overlay(
                        hasRim ? TriangleTickShape(position: settings.barPosition, thickness: thickness).stroke(Color.white.opacity(0.95), lineWidth: 0.8) : nil
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
                        hasRim ? RoundDomeShape(position: settings.barPosition, thickness: thickness).stroke(Color.white.opacity(0.95), lineWidth: 0.8) : nil
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
                        hasRim ? Rectangle().stroke(Color.white.opacity(0.95), lineWidth: 0.8) : nil
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
                        hasRim ? Circle().stroke(Color.white.opacity(0.9), lineWidth: 0.6) : nil
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
        case .cat:
            InteractivePetView(
                petType: .cat,
                isHorizontal: isHorizontal,
                isBarHovered: isBarHovered,
                isPetProximityHovered: isProximityNear,
                settings: settings,
                thickness: thickness,
                accentColor: accentColor
            )
        case .dog:
            InteractivePetView(
                petType: .dog,
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
                    petType: .cat,
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

// MARK: - 펫 마스코트 피벗 회전 물리 뷰
private struct InteractivePetView: View {
    let petType: PetType
    let isHorizontal: Bool
    let isBarHovered: Bool
    let isPetProximityHovered: Bool
    @ObservedObject var settings: AppSettings
    let thickness: CGFloat
    let accentColor: Color

    var body: some View {
        let isHovered = isBarHovered || isPetProximityHovered
        let hideStyle = settings.petHideStyle

        HangingPetIndicatorView(
            petType: petType,
            isHorizontal: isHorizontal,
            isRightEdge: settings.barPosition == .right,
            accentColor: accentColor
        )
        // 1. 소멸 투명도
        .opacity(calculateOpacity(isHovered: isHovered, hideStyle: hideStyle))
        // 2. 블러 효과 (연기 모션)
        .blur(radius: calculateBlur(isHovered: isHovered, hideStyle: hideStyle))
        // 3. 스케일 및 왜곡 (팝, 회오리, 슬라임, 연기)
        .scaleEffect(
            x: calculateScaleX(isHovered: isHovered, hideStyle: hideStyle),
            y: calculateScaleY(isHovered: isHovered, hideStyle: hideStyle),
            anchor: gripPivotAnchor
        )
        // 4. 단일 힌지 피벗 회전 (꼬리/머리 빼꼼 및 회오리 720°)
        .rotationEffect(
            .degrees(calculateRotationAngle(isHovered: isHovered, hideStyle: hideStyle)),
            anchor: gripPivotAnchor
        )
        // 5. 화면 공간 수평 이동 오프셋
        .offset(
            x: calculateOffsetX(isHovered: isHovered, hideStyle: hideStyle),
            y: calculateOffsetY(isHovered: isHovered, hideStyle: hideStyle)
        )
        .animation(
            isHorizontal ? .spring(response: 0.36, dampingFraction: 0.82) : .spring(response: 0.28, dampingFraction: 0.72),
            value: isHovered
        )
    }

    // 단일 힌지 피벗 (PET_SPEC_RULES §1.2, §2.1): 손 접촉 핀 고정 불변
    private var gripPivotAnchor: UnitPoint {
        let centerY: CGFloat = 0.267

        if isHorizontal {
            return UnitPoint(x: 0.50, y: 0.50)
        } else if settings.barPosition == .right {
            return UnitPoint(x: 1.0, y: centerY)
        } else {
            return UnitPoint(x: 0.0, y: centerY)
        }
    }

    private func calculateOpacity(isHovered: Bool, hideStyle: PetHideStyle) -> Double {
        guard isHovered else { return 1.0 }
        switch hideStyle {
        case .tailPeek, .headPeek:
            return 1.0
        case .pop, .vortex, .squish, .smoke:
            return 0.0
        }
    }

    private func calculateBlur(isHovered: Bool, hideStyle: PetHideStyle) -> CGFloat {
        guard isHovered else { return 0.0 }
        return hideStyle == .smoke ? 8.0 : 0.0
    }

    private func calculateScaleX(isHovered: Bool, hideStyle: PetHideStyle) -> CGFloat {
        guard isHovered else { return 1.0 }
        switch hideStyle {
        case .pop, .vortex:
            return 0.05
        case .squish:
            return 1.6
        case .smoke:
            return 1.3
        case .tailPeek, .headPeek:
            return 1.0
        }
    }

    private func calculateScaleY(isHovered: Bool, hideStyle: PetHideStyle) -> CGFloat {
        if isHorizontal && hideStyle == .tailPeek {
            return -1.0 // 하단 바 꼬리살랑: 꼬리가 위로 오도록 상하 반전
        }
        guard isHovered else { return 1.0 }
        switch hideStyle {
        case .pop, .vortex, .squish:
            return 0.05
        case .smoke:
            return 1.3
        case .tailPeek, .headPeek:
            return 1.0
        }
    }

    // PET_SPEC_RULES §3: 노출량은 지정 오프셋(baseX - 8)과 회전 궤적으로만 제어
    private func calculateOffsetX(isHovered: Bool, hideStyle: PetHideStyle) -> CGFloat {
        let baseX: CGFloat = isHorizontal ? -4 : (settings.barPosition == .left ? max(0, thickness - 2) : 0)
        guard isHovered else { return baseX }

        if isHorizontal {
            return baseX
        }

        let isLeft = (settings.barPosition == .left)
        switch hideStyle {
        case .tailPeek:
            return baseX + (isLeft ? -23.0 : 23.0)
        case .headPeek:
            return baseX + (isLeft ? 6.0 : -6.0)
        case .pop, .vortex, .squish, .smoke:
            return baseX
        }
    }

    // 하단 바(두더지 모션: 평상시 머리/꼬리 15px 빼꼼, 호버 시 바닥 아래로 스르륵 쏙 하강 은폐) vs 세로 바 고정 Y 오프셋
    private func calculateOffsetY(isHovered: Bool, hideStyle: PetHideStyle) -> CGFloat {
        if isHorizontal {
            let baseY: CGFloat = 27.0 // 바닥 베젤 뒤에서 머리 또는 꼬리 15px 빼꼼 노출 (+5px 보정)
            if !isHovered {
                return baseY
            }
            switch hideStyle {
            case .headPeek, .tailPeek:
                return 65.0 // 바닥(베젤) 아래로 스르륵 쏙 완전 하강 은폐
            case .pop, .vortex, .squish, .smoke:
                return baseY
            }
        } else {
            return -15.5
        }
    }

    // PET_SPEC_RULES §3 (Left Bar 기준): tailPeek -80° 위로 회전, headPeek +90° 아래로 회전, vortex 720°
    private func calculateRotationAngle(isHovered: Bool, hideStyle: PetHideStyle) -> Double {
        guard isHovered else { return 0.0 }

        if isHorizontal {
            switch hideStyle {
            case .vortex: return 720.0
            case .tailPeek, .headPeek, .pop, .squish, .smoke: return 0.0
            }
        }

        let isLeft = (settings.barPosition == .left)
        switch hideStyle {
        case .tailPeek:
            return isLeft ? -85.0 : 85.0
        case .headPeek:
            return isLeft ? 85.0 : -85.0
        case .vortex:
            return 720.0
        case .pop, .squish, .smoke:
            return 0.0
        }
    }
}

// MARK: - 커스텀 펫 피벗 회전 물리 뷰
private struct InteractiveCustomPetView: View {
    let petId: String
    let isHorizontal: Bool
    let isBarHovered: Bool
    let isPetProximityHovered: Bool
    @ObservedObject var settings: AppSettings
    let thickness: CGFloat
    let accentColor: Color

    @ObservedObject private var petService = CustomPetService.shared

    var body: some View {
        let pet = petService.customPets.first { $0.id == petId }
        let frames = petService.getFrames(for: petId)
        let fps = pet?.fps ?? 8.0
        let isHovered = isBarHovered || isPetProximityHovered
        let hideStyle = settings.petHideStyle

        if !frames.isEmpty {
            TimelineView(.periodic(from: .now, by: 1.0 / max(1.0, fps))) { context in
                let count = max(1, frames.count)
                let index = Int(context.date.timeIntervalSince1970 * fps) % count
                if let image = frames[safe: index] {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: isHorizontal ? 35 : 40, height: isHorizontal ? 50 : 58)
                        .scaleEffect(x: (!isHorizontal && settings.barPosition == .right) ? -1.0 : 1.0, y: 1.0)
                }
            }
            // 1. 소멸 투명도
            .opacity(calculateOpacity(isHovered: isHovered, hideStyle: hideStyle))
            // 2. 블러 효과 (연기 모션)
            .blur(radius: calculateBlur(isHovered: isHovered, hideStyle: hideStyle))
            // 3. 스케일 및 왜곡 (팝, 회오리, 슬라임, 연기)
            .scaleEffect(
                x: calculateScaleX(isHovered: isHovered, hideStyle: hideStyle),
                y: calculateScaleY(isHovered: isHovered, hideStyle: hideStyle),
                anchor: gripPivotAnchor
            )
            // 4. 단일 힌지 피벗 회전 (꼬리/머리 빼꼼 및 회오리 720°)
            .rotationEffect(
                .degrees(calculateRotationAngle(isHovered: isHovered, hideStyle: hideStyle)),
                anchor: gripPivotAnchor
            )
            // 5. 화면 공간 수평 이동 오프셋
            .offset(
                x: calculateOffsetX(isHovered: isHovered, hideStyle: hideStyle, pet: pet),
                y: calculateOffsetY(isHovered: isHovered, hideStyle: hideStyle)
            )
            .animation(
                isHorizontal ? .spring(response: 0.36, dampingFraction: 0.82) : .spring(response: 0.28, dampingFraction: 0.72),
                value: isHovered
            )
        }
    }

    // 단일 힌지 피벗 (PET_SPEC_RULES §1.2, §2.1): 손 접촉 핀 고정 불변
    private var gripPivotAnchor: UnitPoint {
        let centerY: CGFloat = 0.267

        if isHorizontal {
            return UnitPoint(x: 0.50, y: 0.50)
        } else if settings.barPosition == .right {
            return UnitPoint(x: 1.0, y: centerY)
        } else {
            return UnitPoint(x: 0.0, y: centerY)
        }
    }

    private func calculateOpacity(isHovered: Bool, hideStyle: PetHideStyle) -> Double {
        guard isHovered else { return 1.0 }
        switch hideStyle {
        case .tailPeek, .headPeek:
            return 1.0
        case .pop, .vortex, .squish, .smoke:
            return 0.0
        }
    }

    private func calculateBlur(isHovered: Bool, hideStyle: PetHideStyle) -> CGFloat {
        guard isHovered else { return 0.0 }
        return hideStyle == .smoke ? 8.0 : 0.0
    }

    private func calculateScaleX(isHovered: Bool, hideStyle: PetHideStyle) -> CGFloat {
        guard isHovered else { return 1.0 }
        switch hideStyle {
        case .pop, .vortex:
            return 0.05
        case .squish:
            return 1.6
        case .smoke:
            return 1.3
        case .tailPeek, .headPeek:
            return 1.0
        }
    }

    private func calculateScaleY(isHovered: Bool, hideStyle: PetHideStyle) -> CGFloat {
        if isHorizontal && hideStyle == .tailPeek {
            return -1.0 // 하단 바 꼬리살랑: 꼬리가 위로 오도록 상하 반전
        }
        guard isHovered else { return 1.0 }
        switch hideStyle {
        case .pop, .vortex, .squish:
            return 0.05
        case .smoke:
            return 1.3
        case .tailPeek, .headPeek:
            return 1.0
        }
    }

    private func calculateOffsetX(isHovered: Bool, hideStyle: PetHideStyle, pet: CustomPet?) -> CGFloat {
        let baseX: CGFloat = isHorizontal ? -4 : (settings.barPosition == .left ? max(0, thickness - 2) : 0)
        guard isHovered else { return baseX }

        if isHorizontal {
            return baseX
        }

        let isLeft = (settings.barPosition == .left)
        let leftOffset = pet?.leftHideOffset ?? -23.0
        let rightOffset = pet?.rightHideOffset ?? 6.0

        switch hideStyle {
        case .tailPeek:
            return baseX + (isLeft ? leftOffset : -leftOffset)
        case .headPeek:
            return baseX + (isLeft ? rightOffset : -rightOffset)
        case .pop, .vortex, .squish, .smoke:
            return baseX
        }
    }

    // 하단 바(두더지 모션: 평상시 머리/꼬리 빼꼼, 호버 시 바닥 아래로 스르륵 하강 은폐) vs 세로 바 고정 Y 오프셋
    private func calculateOffsetY(isHovered: Bool, hideStyle: PetHideStyle) -> CGFloat {
        if isHorizontal {
            let baseY: CGFloat = 27.0 // 위로 5px 보정
            if !isHovered {
                return baseY
            }
            switch hideStyle {
            case .headPeek, .tailPeek:
                return 65.0 // 바닥(베젤) 아래로 스르륵 쏙 하강 은폐
            case .pop, .vortex, .squish, .smoke:
                return baseY
            }
        } else {
            return -6.0
        }
    }

    private func calculateRotationAngle(isHovered: Bool, hideStyle: PetHideStyle) -> Double {
        guard isHovered else { return 0.0 }

        if isHorizontal {
            switch hideStyle {
            case .vortex: return 720.0
            case .tailPeek, .headPeek, .pop, .squish, .smoke: return 0.0
            }
        }

        let isLeft = (settings.barPosition == .left)

        switch hideStyle {
        case .tailPeek:
            return isLeft ? -85.0 : 85.0
        case .headPeek:
            return isLeft ? 85.0 : -85.0
        case .vortex:
            return 720.0
        case .pop, .squish, .smoke:
            return 0.0
        }
    }
}


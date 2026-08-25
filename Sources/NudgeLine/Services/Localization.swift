// 한국어/영어 1:1 매핑 다국어 지역화 사전
import Foundation
import SwiftUI

// 지원 언어
public enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case system = "system"
    case en = "en"
    case ko = "ko"

    public var title: String {
        switch self {
        case .system:
            let isKo = (Locale.preferredLanguages.first?.prefix(2).lowercased() == "ko")
            return isKo ? "시스템 기본값" : "System Default"
        case .en: return "English"
        case .ko: return "한국어"
        }
    }

    public var resolvedCode: String {
        switch self {
        case .system:
            let preferred = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
            return preferred == "ko" ? "ko" : "en"
        case .en: return "en"
        case .ko: return "ko"
        }
    }

    public var isKorean: Bool {
        return resolvedCode == "ko"
    }
}

// 다국어 번역 키
public struct L10n {
    public static func tr(_ key: Key, lang: AppLanguage = AppSettings.shared.language) -> String {
        let isKo = lang.isKorean
        return isKo ? key.ko : key.en
    }

    public enum Key {
        // Menu Bar & Context Menu
        case toggleBar
        case refresh
        case settings
        case quit

        // Settings 4 Core Tabs (Clean & Professional HIG)
        case tabTimeline
        case tabAppearance
        case tabSchedule
        case tabGeneral

        // Tab 1: Timeline
        case barPositionAndThicknessSection
        case barHoverEffectsSection
        case barBackgroundSection

        // Tab 2: Appearance
        case hoverCardStyleSection
        case timeIndicatorSection

        // Tab 3: Schedule
        case workHoursSection
        case visibleCalendarsSection

        // Tab 4: General & About
        case systemPreferencesSection
        case enableSegmentRimLabel
        case enableSegmentGlowLabel
        case creditsOriginal

        // Calendars Tab
        case permissionNeeded
        case requestPermission
        case permissionRequestFailed(String)
        case openSystemPrivacy
        case noCalendars
        case manageAccountsButton
        case openCalendarApp
        case resetDefault
        case allDayBadge

        // Timeline Tab
        case mode24Hours
        case workStartTime
        case workEndTime

        // Appearance Tab
        case barPositionLabel
        case showOnAllScreens
        case positionLeft
        case positionRight
        case positionBottom
        case defaultThickness
        case expandOnHover
        case hoverThickness
        case backgroundStyle
        case styleAdaptive
        case styleDark
        case styleLight
        case styleCustom
        case backgroundColor
        case backgroundOpacity
        case cardStyleLabel
        case cardThemeLabel
        case cardOpacityLabel
        case styleActionCard
        case styleSummaryBubble
        case indicatorStyleLabel
        case styleTriangleTick
        case styleRoundDome
        case styleBlock
        case stylePointRing
        case indicatorColorLabel
        case indicatorRimLabel
        case indicatorGlowLabel
        case petCompanionSection
        case showPetCompanionLabel
        case petCharacterLabel
        case styleHangingCat
        case styleHangingDog
        case styleHangingWhiteTiger
        case styleCustomPet
        case languageLabel

        // Pet Hide Motion Styles
        case petHideMotionLabel
        case petNotSupportedOnBottom
        case hideStyleTailPeek
        case hideStyleHeadPeek
        case hideStylePop
        case hideStyleVortex
        case hideStyleSquish
        case hideStyleSmoke
        case hideStyleFadeOut

        // Custom Pet Editor
        case customPetSection
        case addCustomPet
        case customPetEditorTitle
        case petNameLabel
        case petNamePlaceholder
        case framesLabel
        case framesGuide
        case dragDropGuide
        case previewLabel
        case speedLabel
        case speedSlow
        case speedFast
        case leftHideOffsetLabel
        case rightHideOffsetLabel
        case cancelButton
        case addButton
        case noCustomPets

        // Popover & Meeting
        case untitledEvent
        case otherSource
        case allDayText
        case openInCalendarApp
        case durationMinutes(Int)
        case overlappingEvents(Int)
        case joinMeeting(String)

        // Time Indicator Tooltip
        case todayDate(String)
        case remainingWorkTime(String)
        case remainingDayTime(String)

        // About & General
        case launchAtLogin
        case appDescription

        var ko: String {
            switch self {
            case .toggleBar: return "타임라인 바 표시"
            case .refresh: return "새로고침"
            case .settings: return "설정..."
            case .quit: return "NudgeLine 종료"

            case .tabTimeline: return "타임라인"
            case .tabAppearance: return "인디케이터"
            case .tabSchedule: return "시간 및 캘린더"
            case .tabGeneral: return "일반"

            case .barPositionAndThicknessSection: return "화면 배치 및 크기"
            case .barHoverEffectsSection: return "마우스 호버 효과"
            case .barBackgroundSection: return "타임라인 배경"
            case .hoverCardStyleSection: return "일정 카드"
            case .timeIndicatorSection: return "시간 표시자"
            case .workHoursSection: return "업무 시간"
            case .visibleCalendarsSection: return "표시할 캘린더"
            case .systemPreferencesSection: return "시스템 설정"

            case .enableSegmentRimLabel: return "블록 테두리 강조"
            case .enableSegmentGlowLabel: return "블록 네온 효과"
            case .creditsOriginal: return "원작: Andreas Katzian & ARTMIXTURE (2014-2015)"

            case .launchAtLogin: return "로그인할 때 자동 실행"
            case .appDescription: return "화면 가장자리에 오늘 일정을 시각화하는 세련된 macOS 캘린더 타임라인 바"

            case .permissionNeeded: return "macOS 캘린더 접근 권한이 필요합니다."
            case .requestPermission: return "권한 요청"
            case .permissionRequestFailed(let err): return "캘린더 권한 요청 실패: \(err)"
            case .openSystemPrivacy: return "시스템 설정 열기"
            case .noCalendars: return "등록된 캘린더가 없습니다."
            case .manageAccountsButton: return "시스템 계정 관리..."
            case .openCalendarApp: return "캘린더 앱 열기"
            case .resetDefault: return "기본값"
            case .allDayBadge: return "종일"

            case .mode24Hours: return "24시간 전체 모드 (00:00 ~ 24:00)"
            case .workStartTime: return "업무 시작 시각:"
            case .workEndTime: return "업무 종료 시각:"

            case .barPositionLabel: return "바 위치:"
            case .showOnAllScreens: return "모든 디스플레이에 표시"
            case .positionLeft: return "화면 좌측"
            case .positionRight: return "화면 우측"
            case .positionBottom: return "화면 하단"
            case .defaultThickness: return "기본 두께:"
            case .expandOnHover: return "두께 자동 확장"
            case .hoverThickness: return "확장 두께:"
            case .backgroundStyle: return "배경 스타일:"
            case .styleAdaptive: return "시스템 테마 (자동)"
            case .styleDark: return "다크"
            case .styleLight: return "라이트"
            case .styleCustom: return "사용자 정의 색상"
            case .backgroundColor: return "배경 색상:"
            case .backgroundOpacity: return "배경 투명도:"
            case .cardStyleLabel: return "카드 형태:"
            case .cardThemeLabel: return "카드 테마:"
            case .cardOpacityLabel: return "카드 투명도:"
            case .styleActionCard: return "액션 카드"
            case .styleSummaryBubble: return "요약 말풍선"

            case .indicatorStyleLabel: return "표시자 형태:"
            case .styleTriangleTick: return "삼각 틱"
            case .styleRoundDome: return "라운드 돔"
            case .styleBlock: return "돌출 블록"
            case .stylePointRing: return "포인트 링"
            case .indicatorColorLabel: return "표시자 색상:"
            case .indicatorRimLabel: return "테두리 강조"
            case .indicatorGlowLabel: return "네온 효과"

            case .petCompanionSection: return "대롱대롱 펫"
            case .showPetCompanionLabel: return "대롱대롱 펫 표시:"
            case .petCharacterLabel: return "펫 캐릭터:"
            case .styleHangingCat: return "삼색고양이"
            case .styleHangingDog: return "진도백구"
            case .styleHangingWhiteTiger: return "백호"
            case .styleCustomPet: return "사용자 설정 펫"
            case .languageLabel: return "언어:"

            case .petHideMotionLabel: return "마우스 접근 시 숨김 모션:"
            case .petNotSupportedOnBottom: return "화면 하단 배치 시에는 펫 표시가 지원되지 않습니다."
            case .hideStyleTailPeek: return "왼쪽으로 숨기 (꼬리 살랑)"
            case .hideStyleHeadPeek: return "오른쪽으로 숨기 (머리 빼꼼)"
            case .hideStylePop: return "없어지기 (팝/소멸)"
            case .hideStyleVortex: return "없어지기 (회오리)"
            case .hideStyleSquish: return "없어지기 (슬라임)"
            case .hideStyleSmoke: return "없어지기 (연기)"
            case .hideStyleFadeOut: return "없어지기 (팝/소멸)"

            case .customPetSection: return "사용자 설정 펫"
            case .addCustomPet: return "사용자 설정 펫 추가"
            case .customPetEditorTitle: return "사용자 설정 펫 편집기"
            case .petNameLabel: return "펫 이름"
            case .petNamePlaceholder: return "예: 삼색이, 백구"
            case .framesLabel: return "프레임"
            case .framesGuide: return "1. 포맷: PNG (투명)\n2. 기본: 80 × 116 px\n   (=레티나: 40 × 58 pt)\n3. 권장: 10장 미만"
            case .dragDropGuide: return "PNG 파일들을 여기에 드래그하거나\n아래 '+' 버튼을 눌러 추가하세요"
            case .previewLabel: return "미리보기"
            case .speedLabel: return "애니메이션 속도"
            case .speedSlow: return "느리게"
            case .speedFast: return "빠르게"
            case .leftHideOffsetLabel: return "왼쪽 숨기 오프셋"
            case .rightHideOffsetLabel: return "오른쪽 숨기 오프셋"
            case .cancelButton: return "취소"
            case .addButton: return "추가"
            case .noCustomPets: return "등록된 사용자 설정 펫이 없습니다."

            case .untitledEvent: return "(제목 없음)"
            case .otherSource: return "기타"
            case .allDayText: return "하루 종일"
            case .openInCalendarApp: return "캘린더 앱에서 보기"
            case .durationMinutes(let m): return "(\(m)분)"
            case .overlappingEvents(let count): return "일정 \(count)개 겹침"
            case .joinMeeting(let p): return "\(p) 바로 참여"
            case .todayDate(let d): return "오늘: \(d)"
            case .remainingWorkTime(let t): return "남은 업무 시간: \(t)"
            case .remainingDayTime(let t): return "남은 하루 시간: \(t)"
            }
        }

        var en: String {
            switch self {
            case .toggleBar: return "Show Timeline Bar"
            case .refresh: return "Refresh Calendars"
            case .settings: return "Settings..."
            case .quit: return "Quit NudgeLine"

            case .tabTimeline: return "Timeline"
            case .tabAppearance: return "Indicators"
            case .tabSchedule: return "Schedule"
            case .tabGeneral: return "General"

            case .barPositionAndThicknessSection: return "Position & Size"
            case .barHoverEffectsSection: return "Hover Effects"
            case .barBackgroundSection: return "Timeline Background"
            case .hoverCardStyleSection: return "Event Card"
            case .timeIndicatorSection: return "Time Indicator"
            case .workHoursSection: return "Working Hours"
            case .visibleCalendarsSection: return "Visible Calendars"
            case .systemPreferencesSection: return "System Preferences"

            case .enableSegmentRimLabel: return "Block Rim Highlight"
            case .enableSegmentGlowLabel: return "Block Neon Glow"
            case .creditsOriginal: return "Inspired by PixelScheduler (2014-2015) by Andreas Katzian & ARTMIXTURE"

            case .launchAtLogin: return "Launch at Login"
            case .appDescription: return "A sleek macOS edge timeline bar that visualizes today's schedule along screen edges."

            case .permissionNeeded: return "Calendar access permission is required."
            case .requestPermission: return "Request Access"
            case .permissionRequestFailed(let err): return "Calendar permission request failed: \(err)"
            case .openSystemPrivacy: return "Open System Settings"
            case .noCalendars: return "No calendars found."
            case .manageAccountsButton: return "Manage System Accounts..."
            case .openCalendarApp: return "Open Calendar App"
            case .resetDefault: return "Default"
            case .allDayBadge: return "All Day"

            case .mode24Hours: return "24-Hour Mode (00:00 - 24:00)"
            case .workStartTime: return "Start Time:"
            case .workEndTime: return "End Time:"

            case .barPositionLabel: return "Bar Position:"
            case .showOnAllScreens: return "Show on All Displays"
            case .positionLeft: return "Left Edge"
            case .positionRight: return "Right Edge"
            case .positionBottom: return "Bottom Edge"
            case .defaultThickness: return "Default Width:"
            case .expandOnHover: return "Auto-expand Thickness"
            case .hoverThickness: return "Expanded Width:"
            case .backgroundStyle: return "Background Style:"
            case .styleAdaptive: return "System Adaptive (Auto)"
            case .styleDark: return "Dark"
            case .styleLight: return "Light"
            case .styleCustom: return "Custom Color"
            case .backgroundColor: return "Background Color:"
            case .backgroundOpacity: return "Opacity:"
            case .cardStyleLabel: return "Card Style:"
            case .cardThemeLabel: return "Card Theme:"
            case .cardOpacityLabel: return "Card Opacity:"
            case .styleActionCard: return "Action Card"
            case .styleSummaryBubble: return "Summary Bubble"

            case .indicatorStyleLabel: return "Indicator Style:"
            case .styleTriangleTick: return "Triangle Tick"
            case .styleRoundDome: return "Round Dome"
            case .styleBlock: return "Protruding Block"
            case .stylePointRing: return "Point Ring"
            case .indicatorColorLabel: return "Indicator Color:"
            case .indicatorRimLabel: return "Rim Highlight"
            case .indicatorGlowLabel: return "Neon Glow"

            case .petCompanionSection: return "Hanging Pet Companion"
            case .showPetCompanionLabel: return "Pet Companion:"
            case .petCharacterLabel: return "Pet Character:"
            case .styleHangingCat: return "Calico Cat"
            case .styleHangingDog: return "White Jindo Dog"
            case .styleHangingWhiteTiger: return "White Tiger"
            case .styleCustomPet: return "Custom Pet"
            case .languageLabel: return "Language:"

            case .petHideMotionLabel: return "Hover Hide Motion:"
            case .petNotSupportedOnBottom: return "Pet companion is not supported on the bottom edge."
            case .hideStyleTailPeek: return "Hide Left (Tail Wag)"
            case .hideStyleHeadPeek: return "Hide Right (Head Peek)"
            case .hideStylePop: return "Disappear (Pop)"
            case .hideStyleVortex: return "Disappear (Vortex)"
            case .hideStyleSquish: return "Disappear (Squish)"
            case .hideStyleSmoke: return "Disappear (Smoke)"
            case .hideStyleFadeOut: return "Invisible Fade-out (Cloak)"

            case .customPetSection: return "Custom Pets"
            case .addCustomPet: return "Add Custom Pet"
            case .customPetEditorTitle: return "Custom Pet Editor"
            case .petNameLabel: return "Pet Name"
            case .petNamePlaceholder: return "e.g., Patches, Snowy"
            case .framesLabel: return "Frames"
            case .framesGuide: return "1. Format: PNG (Alpha)\n2. Size: 80 × 116 px\n   (=Retina: 40 × 58 pt)\n3. Frames: < 10 frames"
            case .dragDropGuide: return "Drag & drop PNG files here\nor click '+' below to add"
            case .previewLabel: return "Preview"
            case .speedLabel: return "Animation Speed"
            case .speedSlow: return "Slow"
            case .speedFast: return "Fast"
            case .leftHideOffsetLabel: return "Left Hide Offset"
            case .rightHideOffsetLabel: return "Right Hide Offset"
            case .cancelButton: return "Cancel"
            case .addButton: return "Add"
            case .noCustomPets: return "No custom pets registered."

            case .untitledEvent: return "(Untitled)"
            case .otherSource: return "Other"
            case .allDayText: return "All Day"
            case .openInCalendarApp: return "Open in Calendar App"
            case .durationMinutes(let m): return "(\(m)m)"
            case .overlappingEvents(let count): return "\(count) Overlapping Events"
            case .joinMeeting(let p): return "Join \(p)"

            case .todayDate(let d): return "Today: \(d)"
            case .remainingWorkTime(let t): return "Remaining Work Time: \(t)"
            case .remainingDayTime(let t): return "Remaining Day Time: \(t)"
            }
        }
    }
}

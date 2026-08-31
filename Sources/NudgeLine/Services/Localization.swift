// 한국어/영어 1:1 매핑 다국어 지역화 사전
import Foundation

// MARK: - 1. 지원 언어 모델
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

// MARK: - 2. 다국어 엔진 및 번역 키 정의
public struct L10n {
    public static func tr(_ key: Key, lang: AppLanguage = AppSettings.shared.language) -> String {
        return lang.isKorean ? key.ko : key.en
    }

    public enum Key: Sendable {
        // 메뉴바 및 컨텍스트 메뉴
        case refresh
        case settings
        case quit

        // 환경설정 4대 핵심 탭
        case tabTimeline
        case tabAppearance
        case tabSchedule
        case tabGeneral

        // 탭 1: 타임라인 섹션
        case barPositionAndThicknessSection
        case barHoverEffectsSection
        case barBackgroundSection

        // 탭 2: 인디케이터 섹션
        case hoverCardStyleSection
        case timeIndicatorSection

        // 탭 3: 일정 섹션
        case workHoursSection
        case visibleCalendarsSection

        // 탭 4: 일반 섹션
        case systemPreferencesSection
        case enableSegmentRimLabel
        case enableSegmentGlowLabel
        case creditsOriginal

        // 캘린더 권한 및 연동
        case permissionNeeded
        case requestPermission
        case permissionRequestFailed(String)
        case openSystemPrivacy
        case noCalendars
        case manageAccountsButton
        case openCalendarApp
        case resetDefault
        case allDayBadge

        // 업무 시간 및 타임라인 범위
        case mode24Hours
        case workStartTime
        case workEndTime

        // 바 외형 및 배치
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

        // 펫 캐릭터 및 표시자
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

        // 일정 알림 효과
        case eventTriggerEffectSection
        case showEventTriggerEffectLabel
        case hourlyAlertLabel
        case eventTriggerEffectStyleLabel
        case effectThunder
        case effectCherry
        case effectAutumn
        case effectWinter
        case effectNone

        // 펫 숨김 모션
        case petHideMotionLabel
        case hideStyleTailPeek
        case hideStyleHeadPeek
        case hideStylePop
        case hideStyleVortex
        case hideStyleSquish
        case hideStyleSmoke

        // 커스텀 펫 편집기
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

        // 팝오버 및 회의 연동
        case untitledEvent
        case otherSource
        case allDayText
        case openInCalendarApp
        case durationMinutes(Int)
        case overlappingEvents(Int)
        case joinMeeting(String)
        case unverifiedMeetingLink

        // 시간 표시자 툴팁
        case todayDate(String)
        case remainingWorkTime(String)
        case remainingDayTime(String)

        // 일반 설정
        case launchAtLogin
        case hideOnScreenShareLabel
        case hideOnFullScreenLabel
        case appDescription
    }
}

// MARK: - 3. 한국어(KO) 번역 테이블
extension L10n.Key {
    var ko: String {
        switch self {
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
        case .hideOnScreenShareLabel: return "화상회의 · 녹화 · 가상화면에 표시 안 함"
        case .hideOnFullScreenLabel: return "전체 화면 시 숨김"
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

        case .mode24Hours: return "24시간 전체 타임라인 (00:00 ~ 24:00)"
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

        case .eventTriggerEffectSection: return "일정 알림 효과"
        case .showEventTriggerEffectLabel: return "알림 효과 표시:"
        case .hourlyAlertLabel: return "정각 알림"
        case .eventTriggerEffectStyleLabel: return "효과 종류:"
        case .effectThunder: return "일렉트릭 썬더"
        case .effectCherry: return "체리블라섬"
        case .effectAutumn: return "낙엽 회오리"
        case .effectWinter: return "눈꽃 크리스탈"
        case .effectNone: return "효과 끄기"

        case .petHideMotionLabel: return "마우스 접근 시 숨기:"
        case .hideStyleTailPeek: return "숨기 (꼬리 살랑)"
        case .hideStyleHeadPeek: return "숨기 (머리 빼꼼)"
        case .hideStylePop: return "사라지기 (퐁!)"
        case .hideStyleVortex: return "사라지기 (빙글빙글)"
        case .hideStyleSquish: return "사라지기 (쫀득)"
        case .hideStyleSmoke: return "사라지기 (스르륵)"

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
        case .unverifiedMeetingLink: return "⚠️ 링크 확인 필요"
        case .todayDate(let d): return "오늘: \(d)"
        case .remainingWorkTime(let t): return "남은 업무 시간: \(t)"
        case .remainingDayTime(let t): return "남은 하루 시간: \(t)"
        }
    }
}

// MARK: - 4. 영어(EN) 번역 테이블
extension L10n.Key {
    var en: String {
        switch self {
        case .refresh: return "Refresh"
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
        case .hideOnScreenShareLabel: return "Exclude from Meetings, Capture & Virtual Display"
        case .hideOnFullScreenLabel: return "Hide in Full Screen"
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

        case .mode24Hours: return "Full 24-Hour Timeline (00:00 - 24:00)"
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

        case .eventTriggerEffectSection: return "Event Alert Effects"
        case .showEventTriggerEffectLabel: return "Show Alert Effect:"
        case .hourlyAlertLabel: return "On the Hour"
        case .eventTriggerEffectStyleLabel: return "Effect Type:"
        case .effectThunder: return "Electric Thunder"
        case .effectCherry: return "Cherry Blossom"
        case .effectAutumn: return "Leaf Swirl"
        case .effectWinter: return "Snow Crystal"
        case .effectNone: return "None"

        case .petHideMotionLabel: return "Hover Hide Motion:"
        case .hideStyleTailPeek: return "Hide (Tail Wag)"
        case .hideStyleHeadPeek: return "Hide (Head Peek)"
        case .hideStylePop: return "Disappear (Pop)"
        case .hideStyleVortex: return "Disappear (Swirl)"
        case .hideStyleSquish: return "Disappear (Squish)"
        case .hideStyleSmoke: return "Disappear (Smoke)"

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
        case .unverifiedMeetingLink: return "⚠️ Verify Link"

        case .todayDate(let d): return "Today: \(d)"
        case .remainingWorkTime(let t): return "Remaining Work Time: \(t)"
        case .remainingDayTime(let t): return "Remaining Day Time: \(t)"
        }
    }
}

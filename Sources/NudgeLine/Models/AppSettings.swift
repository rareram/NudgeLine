// 앱 전역 설정 모델 및 UserDefaults 영속화 관리
import Foundation
import SwiftUI
import Combine

// MARK: - 1. 환경설정 열거형 모델 (Enums)
public enum EventHoverStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case card = "card"               // 액션 카드 (미팅/캘린더)
    case simpleInfo = "simpleInfo"   // 요약 말풍선 (초경량)

    public var id: String { rawValue }

    public func title(lang: AppLanguage = .system) -> String {
        switch self {
        case .card: return L10n.tr(.styleActionCard, lang: lang)
        case .simpleInfo: return L10n.tr(.styleSummaryBubble, lang: lang)
        }
    }

    public func renderer() -> EventHoverStyleRenderer {
        switch self {
        case .card: return DetailCardHoverRenderer()
        case .simpleInfo: return SimpleInfoHoverRenderer()
        }
    }
}

public enum EventCardTheme: String, Codable, CaseIterable, Identifiable, Sendable {
    case adaptive = "adaptive"       // 시스템 테마 (자동)
    case dark = "dark"               // 다크
    case light = "light"             // 라이트

    public var id: String { rawValue }

    public func title(lang: AppLanguage = .system) -> String {
        switch self {
        case .adaptive: return L10n.tr(.styleAdaptive, lang: lang)
        case .dark: return L10n.tr(.styleDark, lang: lang)
        case .light: return L10n.tr(.styleLight, lang: lang)
        }
    }

    public func isDark(for colorScheme: ColorScheme) -> Bool {
        switch self {
        case .adaptive: return colorScheme == .dark
        case .dark: return true
        case .light: return false
        }
    }
}

public enum CurrentTimeIndicatorStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case triangleTick = "triangleTick" // 삼각 틱 (타입 3)
    case roundDome = "roundDome"       // 라운드 돔 (타입 2)
    case block = "block"               // 돌출 블록 (타입 1)
    case pointRing = "pointRing"       // 포인트 링 (타입 4)

    public var id: String { rawValue }

    public func title(lang: AppLanguage = .system) -> String {
        switch self {
        case .triangleTick: return L10n.tr(.styleTriangleTick, lang: lang)
        case .roundDome: return L10n.tr(.styleRoundDome, lang: lang)
        case .block: return L10n.tr(.styleBlock, lang: lang)
        case .pointRing: return L10n.tr(.stylePointRing, lang: lang)
        }
    }
}

public enum HangingPetType: String, Codable, CaseIterable, Identifiable, Sendable {
    case calicoCat   = "calicoCat"   // 삼색고양이
    case jindoDog    = "jindoDog"    // 진도백구
    case whiteTiger  = "whiteTiger"  // 백호 (기본 펫)
    case custom      = "custom"      // 사용자 설정 펫

    public var id: String { rawValue }

    public func title(lang: AppLanguage = .system) -> String {
        switch self {
        case .calicoCat: return L10n.tr(.styleHangingCat, lang: lang)
        case .jindoDog: return L10n.tr(.styleHangingDog, lang: lang)
        case .whiteTiger: return L10n.tr(.styleHangingWhiteTiger, lang: lang)
        case .custom: return L10n.tr(.styleCustomPet, lang: lang)
        }
    }
}

public enum PetHideStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case tailPeek = "tailPeek"       // 왼쪽으로 숨기 (꼬리 살랑)
    case headPeek = "headPeek"       // 오른쪽으로 숨기 (머리 빼꼼)
    case pop      = "pop"            // 없어지기 (팝/소멸)
    case vortex   = "vortex"         // 없어지기 (회오리)
    case squish   = "squish"         // 없어지기 (슬라임)
    case smoke    = "smoke"          // 없어지기 (연기)

    public static var allCases: [PetHideStyle] {
        [.tailPeek, .headPeek, .pop, .vortex, .squish, .smoke]
    }

    public var id: String { rawValue }

    public func title(lang: AppLanguage = .system) -> String {
        switch self {
        case .tailPeek: return L10n.tr(.hideStyleTailPeek, lang: lang)
        case .headPeek: return L10n.tr(.hideStyleHeadPeek, lang: lang)
        case .pop:      return L10n.tr(.hideStylePop, lang: lang)
        case .vortex:   return L10n.tr(.hideStyleVortex, lang: lang)
        case .squish:   return L10n.tr(.hideStyleSquish, lang: lang)
        case .smoke:    return L10n.tr(.hideStyleSmoke, lang: lang)
        }
    }
}

public enum BarStyleMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case adaptive = "adaptive"       // 시스템 테마 (자동)
    case dark = "dark"               // 다크
    case light = "light"             // 라이트
    case custom = "custom"           // 사용자 정의 색상

    public var id: String { rawValue }

    public func title(lang: AppLanguage = .system) -> String {
        switch self {
        case .adaptive: return L10n.tr(.styleAdaptive, lang: lang)
        case .dark: return L10n.tr(.styleDark, lang: lang)
        case .light: return L10n.tr(.styleLight, lang: lang)
        case .custom: return L10n.tr(.styleCustom, lang: lang)
        }
    }
}

public enum BarPosition: String, Codable, CaseIterable, Identifiable, Sendable {
    case left = "left"               // 화면 좌측
    case right = "right"             // 화면 우측
    case bottom = "bottom"           // 화면 하단

    public var id: String { rawValue }

    public func title(lang: AppLanguage = .system) -> String {
        switch self {
        case .left: return L10n.tr(.positionLeft, lang: lang)
        case .right: return L10n.tr(.positionRight, lang: lang)
        case .bottom: return L10n.tr(.positionBottom, lang: lang)
        }
    }

    public var isHorizontal: Bool {
        return self == .bottom
    }
}

// MARK: - 2. 앱 전역 설정 저장소 본체 (AppSettings)
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    // MARK: 2-1. UserDefaults 저장소 키
    private enum Keys {
        static let language = "settings_language"
        static let eventHoverStyle = "settings_event_hover_style"
        static let eventCardTheme = "settings_event_card_theme"
        static let cardOpacity = "settings_card_opacity"
        static let barPosition = "settings_bar_position"
        static let showOnAllScreens = "settings_show_on_all_screens"
        static let startHour = "settings_start_hour"
        static let startMinute = "settings_start_minute"
        static let endHour = "settings_end_hour"
        static let endMinute = "settings_end_minute"
        static let is24HourMode = "settings_is_24hour_mode"
        static let barWidth = "settings_bar_width"
        static let expandOnHover = "settings_expand_on_hover"
        static let hoverWidth = "settings_hover_width"
        static let calendarVisibility = "settings_calendar_visibility"
        static let calendarCustomColors = "settings_calendar_custom_colors"
        static let barStyleMode = "settings_bar_style_mode"
        static let trackColorHex = "settings_track_color_hex"
        static let trackOpacity = "settings_track_opacity"
        static let currentTimeColorHex = "settings_current_time_color_hex"
        static let currentTimeIndicatorStyle = "settings_current_time_indicator_style"
        static let enableIndicatorRim = "settings_enable_indicator_rim"
        static let enableIndicatorGlow = "settings_enable_indicator_glow"
        static let isPetEnabled = "settings_is_pet_enabled"
        static let selectedPetType = "settings_selected_pet_type"
        static let selectedCustomPetId = "settings_selected_custom_pet_id"
        static let petHideStyle = "settings_pet_hide_style"
        static let enableSegmentRim = "settings_enable_segment_rim"
        static let enableSegmentGlow = "settings_enable_segment_glow"
        static let hideOnScreenShare = "settings_hide_on_screen_share"
        static let hideOnFullScreen = "settings_hide_on_full_screen"
    }

    private let defaults = UserDefaults.standard

    // MARK: 2-2. 관찰 가능한 상태 프로퍼티 (@Published)
    @Published public var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Keys.language) }
    }

    @Published public var eventHoverStyle: EventHoverStyle {
        didSet { defaults.set(eventHoverStyle.rawValue, forKey: Keys.eventHoverStyle) }
    }

    @Published public var eventCardTheme: EventCardTheme {
        didSet { defaults.set(eventCardTheme.rawValue, forKey: Keys.eventCardTheme) }
    }

    @Published public var cardOpacity: Double {
        didSet { defaults.set(cardOpacity, forKey: Keys.cardOpacity) }
    }

    @Published public var currentTimeIndicatorStyle: CurrentTimeIndicatorStyle {
        didSet { defaults.set(currentTimeIndicatorStyle.rawValue, forKey: Keys.currentTimeIndicatorStyle) }
    }

    @Published public var enableIndicatorRim: Bool {
        didSet { defaults.set(enableIndicatorRim, forKey: Keys.enableIndicatorRim) }
    }

    @Published public var enableIndicatorGlow: Bool {
        didSet { defaults.set(enableIndicatorGlow, forKey: Keys.enableIndicatorGlow) }
    }

    @Published public var isPetEnabled: Bool {
        didSet { defaults.set(isPetEnabled, forKey: Keys.isPetEnabled) }
    }

    @Published public var selectedPetType: HangingPetType {
        didSet { defaults.set(selectedPetType.rawValue, forKey: Keys.selectedPetType) }
    }

    @Published public var petHideStyle: PetHideStyle {
        didSet { defaults.set(petHideStyle.rawValue, forKey: Keys.petHideStyle) }
    }

    @Published public var selectedCustomPetId: String? {
        didSet { defaults.set(selectedCustomPetId, forKey: Keys.selectedCustomPetId) }
    }

    // 로컬 개발 빌드 판별 (Bundle ID 접미사 및 컴파일 플래그)
    public var isDevBuild: Bool {
        #if LOCAL_DEV
        return true
        #else
        return Bundle.main.bundleIdentifier?.hasSuffix(".dev") ?? false
        #endif
    }

    @Published public var barStyleMode: BarStyleMode {
        didSet { defaults.set(barStyleMode.rawValue, forKey: Keys.barStyleMode) }
    }

    @Published public var trackColorHex: String {
        didSet { defaults.set(trackColorHex, forKey: Keys.trackColorHex) }
    }

    @Published public var trackOpacity: Double {
        didSet { defaults.set(trackOpacity, forKey: Keys.trackOpacity) }
    }

    @Published public var currentTimeColorHex: String {
        didSet { defaults.set(currentTimeColorHex, forKey: Keys.currentTimeColorHex) }
    }

    @Published public var barPosition: BarPosition {
        didSet { defaults.set(barPosition.rawValue, forKey: Keys.barPosition) }
    }

    @Published public var showOnAllScreens: Bool {
        didSet { defaults.set(showOnAllScreens, forKey: Keys.showOnAllScreens) }
    }

    @Published public var hideOnScreenShare: Bool {
        didSet { defaults.set(hideOnScreenShare, forKey: Keys.hideOnScreenShare) }
    }

    @Published public var hideOnFullScreen: Bool {
        didSet { defaults.set(hideOnFullScreen, forKey: Keys.hideOnFullScreen) }
    }

    @Published public var startHour: Int {
        didSet { defaults.set(startHour, forKey: Keys.startHour) }
    }

    @Published public var startMinute: Int {
        didSet { defaults.set(startMinute, forKey: Keys.startMinute) }
    }

    @Published public var endHour: Int {
        didSet { defaults.set(endHour, forKey: Keys.endHour) }
    }

    @Published public var endMinute: Int {
        didSet { defaults.set(endMinute, forKey: Keys.endMinute) }
    }

    @Published public var is24HourMode: Bool {
        didSet { defaults.set(is24HourMode, forKey: Keys.is24HourMode) }
    }

    @Published public var barWidth: CGFloat {
        didSet { defaults.set(Double(barWidth), forKey: Keys.barWidth) }
    }

    @Published public var expandOnHover: Bool {
        didSet { defaults.set(expandOnHover, forKey: Keys.expandOnHover) }
    }

    @Published public var hoverWidth: CGFloat {
        didSet { defaults.set(Double(hoverWidth), forKey: Keys.hoverWidth) }
    }

    @Published public var calendarVisibility: [String: Bool] {
        didSet { defaults.set(calendarVisibility, forKey: Keys.calendarVisibility) }
    }

    @Published public var calendarCustomColors: [String: String] {
        didSet { defaults.set(calendarCustomColors, forKey: Keys.calendarCustomColors) }
    }

    @Published public var enableSegmentRim: Bool {
        didSet { defaults.set(enableSegmentRim, forKey: Keys.enableSegmentRim) }
    }

    @Published public var enableSegmentGlow: Bool {
        didSet { defaults.set(enableSegmentGlow, forKey: Keys.enableSegmentGlow) }
    }

    // MARK: 2-3. 초기화 (UserDefaults 영속 데이터 로드 및 마이그레이션)
    private init() {
        let savedLang = defaults.string(forKey: Keys.language) ?? AppLanguage.system.rawValue
        self.language = AppLanguage(rawValue: savedLang) ?? .system

        let savedHoverStyle = defaults.string(forKey: Keys.eventHoverStyle) ?? EventHoverStyle.card.rawValue
        self.eventHoverStyle = EventHoverStyle(rawValue: savedHoverStyle) ?? .card

        let savedCardTheme = defaults.string(forKey: Keys.eventCardTheme) ?? EventCardTheme.adaptive.rawValue
        self.eventCardTheme = EventCardTheme(rawValue: savedCardTheme) ?? .adaptive

        let savedOpacity = defaults.double(forKey: Keys.cardOpacity)
        self.cardOpacity = savedOpacity > 0 ? savedOpacity : 0.30

        let savedBarStyle = defaults.string(forKey: Keys.barStyleMode) ?? BarStyleMode.adaptive.rawValue
        self.barStyleMode = BarStyleMode(rawValue: savedBarStyle) ?? .adaptive

        self.trackColorHex = defaults.string(forKey: Keys.trackColorHex) ?? "#000000"
        let savedTrackOpacity = defaults.double(forKey: Keys.trackOpacity)
        self.trackOpacity = savedTrackOpacity > 0 ? savedTrackOpacity : 0.20

        self.currentTimeColorHex = defaults.string(forKey: Keys.currentTimeColorHex) ?? "#FF3B30"

        let savedIndicatorStyle = defaults.string(forKey: Keys.currentTimeIndicatorStyle) ?? CurrentTimeIndicatorStyle.triangleTick.rawValue
        self.currentTimeIndicatorStyle = CurrentTimeIndicatorStyle(rawValue: savedIndicatorStyle) ?? .triangleTick

        self.enableIndicatorRim = defaults.object(forKey: Keys.enableIndicatorRim) != nil ? defaults.bool(forKey: Keys.enableIndicatorRim) : false
        self.enableIndicatorGlow = defaults.object(forKey: Keys.enableIndicatorGlow) != nil ? defaults.bool(forKey: Keys.enableIndicatorGlow) : false

        let savedPetType = defaults.string(forKey: Keys.selectedPetType) ?? HangingPetType.whiteTiger.rawValue
        let loadedPetType: HangingPetType
        if savedPetType == "cat" {
            loadedPetType = .calicoCat
        } else if savedPetType == "dog" {
            loadedPetType = .jindoDog
        } else {
            loadedPetType = HangingPetType(rawValue: savedPetType) ?? .whiteTiger
        }
        self.selectedPetType = loadedPetType
        self.isPetEnabled = defaults.object(forKey: Keys.isPetEnabled) != nil ? defaults.bool(forKey: Keys.isPetEnabled) : true

        let savedCustomPetId = defaults.string(forKey: Keys.selectedCustomPetId) ?? ""
        self.selectedCustomPetId = savedCustomPetId

        let savedPetHideStyle = defaults.string(forKey: Keys.petHideStyle) ?? ""
        if let loadedHideStyle = PetHideStyle(rawValue: savedPetHideStyle) {
            self.petHideStyle = loadedHideStyle
        } else {
            self.petHideStyle = .tailPeek
            defaults.set(PetHideStyle.tailPeek.rawValue, forKey: Keys.petHideStyle)
        }

        let savedPosition = defaults.string(forKey: Keys.barPosition) ?? BarPosition.left.rawValue
        self.barPosition = BarPosition(rawValue: savedPosition) ?? .left

        self.showOnAllScreens = defaults.bool(forKey: Keys.showOnAllScreens)
        self.hideOnScreenShare = defaults.object(forKey: Keys.hideOnScreenShare) != nil ? defaults.bool(forKey: Keys.hideOnScreenShare) : true
        self.hideOnFullScreen = defaults.object(forKey: Keys.hideOnFullScreen) != nil ? defaults.bool(forKey: Keys.hideOnFullScreen) : true

        let sHour = defaults.object(forKey: Keys.startHour) != nil ? defaults.integer(forKey: Keys.startHour) : 9
        self.startHour = max(0, min(23, sHour))

        let sMin = defaults.object(forKey: Keys.startMinute) != nil ? defaults.integer(forKey: Keys.startMinute) : 0
        self.startMinute = max(0, min(59, sMin))

        let eHour = defaults.object(forKey: Keys.endHour) != nil ? defaults.integer(forKey: Keys.endHour) : 18
        self.endHour = max(0, min(23, eHour))

        let eMin = defaults.object(forKey: Keys.endMinute) != nil ? defaults.integer(forKey: Keys.endMinute) : 0
        self.endMinute = max(0, min(59, eMin))

        self.is24HourMode = defaults.bool(forKey: Keys.is24HourMode)

        let savedBarWidth = defaults.double(forKey: Keys.barWidth)
        self.barWidth = savedBarWidth > 0 ? savedBarWidth : 2.0

        self.expandOnHover = defaults.object(forKey: Keys.expandOnHover) != nil ? defaults.bool(forKey: Keys.expandOnHover) : true

        let savedHoverWidth = defaults.double(forKey: Keys.hoverWidth)
        self.hoverWidth = savedHoverWidth > 0 ? savedHoverWidth : 3.0

        self.calendarVisibility = (defaults.dictionary(forKey: Keys.calendarVisibility) as? [String: Bool]) ?? [:]
        self.calendarCustomColors = (defaults.dictionary(forKey: Keys.calendarCustomColors) as? [String: String]) ?? [:]

        self.enableSegmentRim = defaults.object(forKey: Keys.enableSegmentRim) != nil ? defaults.bool(forKey: Keys.enableSegmentRim) : false
        self.enableSegmentGlow = defaults.object(forKey: Keys.enableSegmentGlow) != nil ? defaults.bool(forKey: Keys.enableSegmentGlow) : false
    }
}

// MARK: - 3. 캘린더 가시성 및 사용자 지정 색상 관리
extension AppSettings {
    public func isCalendarVisible(id: String) -> Bool {
        return calendarVisibility[id] ?? true
    }

    public func setCalendarVisible(id: String, visible: Bool) {
        calendarVisibility[id] = visible
    }

    public func customColor(for id: String) -> Color? {
        guard let hex = calendarCustomColors[id] else { return nil }
        return Color(hex: hex)
    }

    public func effectiveCurrentTimeColor() -> Color {
        return Color(hex: currentTimeColorHex) ?? .red
    }

    public func effectiveTrackColor() -> Color {
        return Color(hex: trackColorHex) ?? .black
    }

    public func setCustomColor(for id: String, color: Color?) {
        if let color = color, let hex = color.toHex() {
            calendarCustomColors[id] = hex
        } else {
            calendarCustomColors.removeValue(forKey: id)
        }
    }
}

// MARK: - 4. 타임라인 날짜 및 시간 범위 계산 헬퍼
extension AppSettings {
    public func startDate(for baseDate: Date = Date()) -> Date {
        let calendar = Calendar.current
        if is24HourMode {
            return calendar.startOfDay(for: baseDate)
        }
        var comps = calendar.dateComponents([.year, .month, .day], from: baseDate)
        comps.hour = startHour
        comps.minute = startMinute
        comps.second = 0
        return calendar.date(from: comps) ?? calendar.startOfDay(for: baseDate)
    }

    public func endDate(for baseDate: Date = Date()) -> Date {
        let calendar = Calendar.current
        if is24HourMode {
            let start = calendar.startOfDay(for: baseDate)
            return calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86400)
        }
        var comps = calendar.dateComponents([.year, .month, .day], from: baseDate)
        comps.hour = endHour
        comps.minute = endMinute
        comps.second = 0
        let date = calendar.date(from: comps) ?? baseDate
        let start = startDate(for: baseDate)
        if date <= start {
            return start.addingTimeInterval(3600 * 8)
        }
        return date
    }
}

// MARK: - 5. SwiftUI Color <-> 16진수 HEX 변환 유틸리티
public extension Color {
    init?(hex: String) {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanHex.hasPrefix("#") {
            cleanHex.removeFirst()
        }
        guard cleanHex.count == 6 || cleanHex.count == 8 else { return nil }

        var intVal: UInt64 = 0
        guard Scanner(string: cleanHex).scanHexInt64(&intVal) else { return nil }

        let r, g, b, a: Double
        if cleanHex.count == 6 {
            r = Double((intVal >> 16) & 0xFF) / 255.0
            g = Double((intVal >> 8) & 0xFF) / 255.0
            b = Double(intVal & 0xFF) / 255.0
            a = 1.0
        } else {
            r = Double((intVal >> 24) & 0xFF) / 255.0
            g = Double((intVal >> 16) & 0xFF) / 255.0
            b = Double((intVal >> 8) & 0xFF) / 255.0
            a = Double(intVal & 0xFF) / 255.0
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    func toHex() -> String? {
        guard let components = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        let r = Int(round(components.redComponent * 255.0))
        let g = Int(round(components.greenComponent * 255.0))
        let b = Int(round(components.blueComponent * 255.0))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

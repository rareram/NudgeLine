// 캘린더 이벤트 모델, 화상회의 링크 정규식 파서, 일정 클러스터링 및 세그먼트 슬라이싱
import Foundation
import SwiftUI
import EventKit

// MARK: - 1. 화상회의 플랫폼 열거형 및 메타데이터
public enum MeetingPlatform: String, Hashable, Sendable {
    case googleMeet = "Google Meet"
    case zoom = "Zoom"
    case teams = "Microsoft Teams"
    case faceTime = "FaceTime"
    case webex = "Webex"
    case whaleOn = "Whale ON"
    case discord = "Discord"
    case lark = "Lark"
    case jitsi = "Jitsi Meet"
    case whereby = "Whereby"
    case chime = "Amazon Chime"
    case generic = "Meeting"
    case unverified = "Unverified"

    public var iconName: String {
        switch self {
        case .googleMeet: return "video.fill"
        case .zoom: return "video.badge.waveform.fill"
        case .teams: return "person.2.wave.2.fill"
        case .faceTime: return "video.fill"
        case .webex: return "video.circle.fill"
        case .whaleOn: return "video.bubble.fill"
        case .discord: return "bubble.left.and.bubble.right.fill"
        case .lark: return "paperplane.fill"
        case .jitsi: return "video.fill"
        case .whereby: return "video.fill"
        case .chime: return "video.fill"
        case .generic: return "video"
        case .unverified: return "exclamationmark.triangle.fill"
        }
    }

    public var brandColor: Color {
        switch self {
        case .googleMeet: return Color(red: 0.0, green: 0.65, blue: 0.35)
        case .zoom: return Color(red: 0.18, green: 0.53, blue: 0.98)
        case .teams: return Color(red: 0.38, green: 0.40, blue: 0.85)
        case .faceTime: return Color(red: 0.20, green: 0.78, blue: 0.35)
        case .webex: return Color(red: 0.0, green: 0.70, blue: 0.75)
        case .whaleOn: return Color(red: 0.0, green: 0.78, blue: 0.24)
        case .discord: return Color(red: 0.35, green: 0.40, blue: 0.95)
        case .lark: return Color(red: 0.0, green: 0.84, blue: 0.73)
        case .jitsi: return Color(red: 0.11, green: 0.46, blue: 0.74)
        case .whereby: return Color(red: 1.0, green: 0.41, blue: 0.31)
        case .chime: return Color(red: 0.18, green: 0.49, blue: 0.20)
        case .generic: return .blue
        case .unverified: return Color.orange
        }
    }
}

// 화상회의 바로가기 정보
public struct MeetingInfo: Hashable, Sendable {
    public let platform: MeetingPlatform
    public let url: URL
}

// 관련 웹/문서/세미나 링크 정보
public struct WebLinkInfo: Hashable, Sendable {
    public let url: URL
    public let displayHost: String

    public init(url: URL, displayHost: String) {
        self.url = url
        self.displayHost = displayHost
    }
}

// MARK: - 2. 캘린더 이벤트 모델 (CalendarEvent)
public struct CalendarEvent: Identifiable, Hashable, Sendable {
    public let id: String
    public let rawTitle: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let calendarIdentifier: String
    public let calendarTitle: String
    public let rawSourceTitle: String
    public let defaultColor: Color
    public let location: String?
    public let url: URL?
    public let notes: String?
    public let status: EKEventStatus
    public let isDeclined: Bool
    public let isCanceled: Bool
    public let meetingInfo: MeetingInfo?
    public let webLink: WebLinkInfo?

    public var isCanceledOrDeclined: Bool {
        isCanceled || isDeclined
    }

    public init(from ekEvent: EKEvent) {
        self.id = ekEvent.eventIdentifier ?? UUID().uuidString
        self.rawTitle = (ekEvent.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.isAllDay = ekEvent.isAllDay
        self.calendarIdentifier = ekEvent.calendar.calendarIdentifier
        self.calendarTitle = ekEvent.calendar.title
        self.rawSourceTitle = (ekEvent.calendar.source?.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if let cgColor = ekEvent.calendar.cgColor {
            self.defaultColor = Color(cgColor: cgColor)
        } else {
            self.defaultColor = .blue
        }
        self.location = ekEvent.location?.strippingHTMLTags()
        self.url = ekEvent.url
        self.notes = ekEvent.notes?.strippingHTMLTags()
        self.status = ekEvent.status
        self.isCanceled = (ekEvent.status == .canceled)
        let isCurrentUserDeclined = ekEvent.attendees?.contains(where: { $0.isCurrentUser && $0.participantStatus == .declined }) ?? false
        self.isDeclined = isCurrentUserDeclined

        var currentUserEmail: String? = nil
        if let currentAttendee = (ekEvent.attendees ?? []).first(where: { $0.isCurrentUser }) {
            let rawUrl = currentAttendee.url.absoluteString
            let clean = rawUrl.hasPrefix("mailto:") ? String(rawUrl.dropFirst(7)) : rawUrl
            if clean.contains("@") {
                currentUserEmail = clean
            }
        }

        let meeting = CalendarEvent.extractMeetingInfo(url: ekEvent.url, location: ekEvent.location, notes: ekEvent.notes, currentUserEmail: currentUserEmail)
        self.meetingInfo = meeting
        self.webLink = CalendarEvent.extractWebLink(url: ekEvent.url, notes: ekEvent.notes, meetingInfo: meeting)
    }

    public init(
        id: String = UUID().uuidString,
        rawTitle: String = "",
        startDate: Date = Date(),
        endDate: Date = Date(),
        isAllDay: Bool = false,
        calendarIdentifier: String = "preview_cal",
        calendarTitle: String = "Calendar",
        rawSourceTitle: String = "",
        defaultColor: Color = .blue,
        location: String? = nil,
        url: URL? = nil,
        notes: String? = nil,
        status: EKEventStatus = .confirmed,
        isDeclined: Bool = false,
        isCanceled: Bool = false,
        meetingInfo: MeetingInfo? = nil,
        webLink: WebLinkInfo? = nil
    ) {
        self.id = id
        self.rawTitle = rawTitle
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.calendarIdentifier = calendarIdentifier
        self.calendarTitle = calendarTitle
        self.rawSourceTitle = rawSourceTitle
        self.defaultColor = defaultColor
        self.location = location
        self.url = url
        self.notes = notes
        self.status = status
        self.isDeclined = isDeclined
        self.isCanceled = isCanceled
        let meeting = meetingInfo ?? CalendarEvent.extractMeetingInfo(url: url, location: location, notes: notes)
        self.meetingInfo = meeting
        self.webLink = webLink ?? CalendarEvent.extractWebLink(url: url, notes: notes, meetingInfo: meeting)
    }

    public func title(lang: AppLanguage = AppSettings.shared.language) -> String {
        rawTitle.isEmpty ? L10n.tr(.untitledEvent, lang: lang) : rawTitle
    }

    public func sourceTitle(lang: AppLanguage = AppSettings.shared.language) -> String {
        rawSourceTitle.isEmpty ? L10n.tr(.otherSource, lang: lang) : rawSourceTitle
    }

    public func effectiveColor(settings: AppSettings) -> Color {
        if let custom = settings.customColor(for: calendarIdentifier) {
            return custom
        }
        return defaultColor
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    public func formattedTimeRange(lang: AppLanguage = AppSettings.shared.language) -> String {
        if isAllDay {
            return L10n.tr(.allDayText, lang: lang)
        }
        let startStr = Self.timeFormatter.string(from: startDate)
        let endStr = Self.timeFormatter.string(from: endDate)
        return "\(startStr) ~ \(endStr)"
    }

    public var durationMinutes: Int {
        let diff = endDate.timeIntervalSince(startDate)
        return max(1, Int(diff / 60))
    }

    // 시스템 자동 생성 노이즈(Google Meet, Teams, Zoom 등)를 제외한 사용자 순수 메모
    public var displayNotes: String? {
        CalendarEvent.cleanNotes(from: notes)
    }

    public static func cleanNotes(from raw: String?) -> String? {
        guard let raw = raw, !raw.isEmpty else { return nil }
        let lines = raw.components(separatedBy: .newlines)
        var filtered: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            // 1. Google Meet 시스템 마커 및 구분선
            if trimmed.contains("-::~") || trimmed.contains("::~-") { continue }
            if trimmed.contains("Do not edit this section") || trimmed.contains("이 섹션을 수정하지 마시기 바랍니다") { continue }
            if trimmed.contains("This event has a video call") || trimmed.contains("이 일정에는 화상 통화가 있습니다") { continue }

            // 2. Microsoft Teams 및 캘린더 애드온 시스템 마커
            if trimmed.hasPrefix("_____") || trimmed.contains("________________") { continue }
            if trimmed.contains("Microsoft Teams") && (trimmed.contains("Need help") || trimmed.contains("Meeting ID") || trimmed.contains("참여")) { continue }
            if trimmed.contains("Join the meeting now") || trimmed.contains("모임 옵션") || trimmed.contains("웹에서 참가") { continue }
            if trimmed.contains("launchAgent=GSuiteAddOn") { continue }

            // 3. Zoom 시스템 마커
            if trimmed.contains("Join Zoom Meeting") || trimmed.contains("One tap mobile") || trimmed.contains("Dial by your location") { continue }

            // 4. 공통 화상회의 회의 ID 및 패스코드 라인
            let lower = trimmed.lowercased()
            if lower.hasPrefix("meeting id:") || lower.hasPrefix("passcode:") || lower.hasPrefix("find a local number:") { continue }

            // 5. 화상회의 직접 접속 링크 라인 (이미 별도 버튼으로 표출됨)
            if trimmed.contains("meet.google.com") ||
               trimmed.contains("teams.microsoft.com") ||
               trimmed.contains("teams.live.com") ||
               trimmed.contains("zoom.us") ||
               trimmed.contains("facetime.apple.com") ||
               trimmed.contains("webex.com") ||
               (trimmed.contains("google.com/url?") && (trimmed.contains("teams.") || trimmed.contains("zoom."))) {
                continue
            }

            filtered.append(trimmed)
        }

        if filtered.isEmpty { return nil }
        let result = filtered.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? nil : result
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(startDate)
        hasher.combine(endDate)
        hasher.combine(rawTitle)
        hasher.combine(isAllDay)
        hasher.combine(calendarIdentifier)
        hasher.combine(isDeclined)
        hasher.combine(isCanceled)
        hasher.combine(webLink)
    }

    public static func == (lhs: CalendarEvent, rhs: CalendarEvent) -> Bool {
        return lhs.id == rhs.id &&
            lhs.startDate == rhs.startDate &&
            lhs.endDate == rhs.endDate &&
            lhs.rawTitle == rhs.rawTitle &&
            lhs.isAllDay == rhs.isAllDay &&
            lhs.calendarIdentifier == rhs.calendarIdentifier &&
            lhs.isDeclined == rhs.isDeclined &&
            lhs.isCanceled == rhs.isCanceled &&
            lhs.webLink == rhs.webLink
    }
}

// MARK: - 3. 화상회의 URL 정규식 파서 및 피싱 방어 검증
extension CalendarEvent {
    // MARK: 3-1. 화상회의 플랫폼별 사전 컴파일된 정규식 (성능 최적화: 1회 컴파일 캐싱)
    private enum MeetingRegex {
        static let meet = try? NSRegularExpression(pattern: #"https?://meet\.google\.com/[a-zA-Z0-9_.\-/?=&%]+"#, options: [.caseInsensitive])
        static let zoom = try? NSRegularExpression(pattern: #"https?://[a-zA-Z0-9.\-_]*zoom\.(?:us|com|gov|de)/[a-zA-Z0-9_.\-/?=&]+"#, options: [.caseInsensitive])
        static let teams = try? NSRegularExpression(pattern: #"https?://teams\.microsoft\.com/[a-zA-Z0-9_.\-/?=&%]+"#, options: [.caseInsensitive])
        static let teamsLive = try? NSRegularExpression(pattern: #"https?://teams\.live\.com/[a-zA-Z0-9_.\-/?=&%]+"#, options: [.caseInsensitive])
        static let faceTime = try? NSRegularExpression(pattern: #"https?://facetime\.apple\.com/[a-zA-Z0-9_.\-/?=&%#]+"#, options: [.caseInsensitive])
        static let faceTimeScheme = try? NSRegularExpression(pattern: #"facetime(?:-audio)?://[a-zA-Z0-9_.\-/?=&%#+@]+"#, options: [.caseInsensitive])
        static let webex = try? NSRegularExpression(pattern: #"https?://[a-zA-Z0-9.\-_]*webex\.com/[a-zA-Z0-9_.\-/?=&%]+"#, options: [.caseInsensitive])
        static let whaleOn = try? NSRegularExpression(pattern: #"https?://whaleon\.naver\.com/[a-zA-Z0-9_.\-/?=&%]+"#, options: [.caseInsensitive])
        static let discord = try? NSRegularExpression(pattern: #"https?://(?:www\.)?discord\.(?:gg|com)/[a-zA-Z0-9_.\-/?=&%]+"#, options: [.caseInsensitive])
        static let lark = try? NSRegularExpression(pattern: #"https?://[a-zA-Z0-9.\-_]*larksuite\.com/[a-zA-Z0-9_.\-/?=&%]+"#, options: [.caseInsensitive])
        static let feishu = try? NSRegularExpression(pattern: #"https?://[a-zA-Z0-9.\-_]*feishu\.cn/[a-zA-Z0-9_.\-/?=&%]+"#, options: [.caseInsensitive])
        static let jitsi = try? NSRegularExpression(pattern: #"https?://meet\.jit\.si/[a-zA-Z0-9_.\-/?=&%]+"#, options: [.caseInsensitive])
        static let jitsi8x8 = try? NSRegularExpression(pattern: #"https?://8x8\.vc/[a-zA-Z0-9_.\-/?=&%]+"#, options: [.caseInsensitive])
        static let whereby = try? NSRegularExpression(pattern: #"https?://[a-zA-Z0-9.\-_]*whereby\.com/[a-zA-Z0-9_.\-/?=&%]+"#, options: [.caseInsensitive])
        static let chime = try? NSRegularExpression(pattern: #"https?://app\.chime\.aws/[a-zA-Z0-9_.\-/?=&%]+"#, options: [.caseInsensitive])
        static let genericMeeting = try? NSRegularExpression(pattern: #"https?://[a-zA-Z0-9.\-_]+/(?:meeting|join|call|conference|j|room|bridge)/[a-zA-Z0-9_.\-/?=&%]+"#, options: [.caseInsensitive])
        static let anyUrl = try? NSRegularExpression(pattern: #"https?://[a-zA-Z0-9.\-_]+\.[a-zA-Z]{2,}[a-zA-Z0-9_.\-/?=&%:]*"#, options: [.caseInsensitive])

        // 기업 환경 URL 래퍼 (SafeLinks 및 Google 리디렉터)
        static let safeLinks = try? NSRegularExpression(pattern: #"https?://[a-zA-Z0-9.-]*safelinks\.protection\.outlook\.com/[^\s"'<>]+"#, options: [.caseInsensitive])
        static let googleRedirect = try? NSRegularExpression(pattern: #"https?://(?:www\.)?google\.[a-z]{2,}(?:\.[a-z]{2,})?/url\?[^\s"'<>]+"#, options: [.caseInsensitive])
    }

    // ponytail: URL 끝단 특수문자 정제 및 프로토콜 스킴 유효성 검증 단일 헬퍼
    private static func sanitizeUrl(
        _ raw: String,
        allowedSchemes: Set<String> = ["http", "https", "zoommtg", "msteams", "facetime", "facetime-audio"]
    ) -> URL? {
        var trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let trailingPunctuation = CharacterSet(charactersIn: ".,;:)>]}'\"`")
        while let last = trimmed.unicodeScalars.last, trailingPunctuation.contains(last) {
            trimmed.removeLast()
        }
        guard let validUrl = URL(string: trimmed),
              let scheme = validUrl.scheme?.lowercased(),
              allowedSchemes.contains(scheme) else {
            return nil
        }
        return validUrl
    }

    // 래핑된 엔터프라이즈 URL(Outlook SafeLinks / Google Redirect)의 타깃 URL 디코딩
    private static func unwrapRedirectUrl(from candidate: String) -> String? {
        guard let comps = URLComponents(string: candidate),
              let host = comps.host?.lowercased() else { return nil }

        let queryKey: String?
        if host == "safelinks.protection.outlook.com" || host.hasSuffix(".safelinks.protection.outlook.com") {
            queryKey = "url"
        } else if (host == "google.com" || host.hasSuffix(".google.com")), comps.path == "/url" {
            queryKey = "q"
        } else {
            queryKey = nil
        }

        guard let key = queryKey,
              let target = comps.queryItems?.first(where: { $0.name.lowercased() == key })?.value,
              let decoded = target.removingPercentEncoding,
              decoded.hasPrefix("http://") || decoded.hasPrefix("https://") else {
            return nil
        }
        return decoded
    }

    // 본문/위치/URL 내 화상회의 링크 정규식 추출
    private static func extractMeetingInfo(url: URL?, location: String?, notes: String?, currentUserEmail: String? = nil) -> MeetingInfo? {
        let combined = [url?.absoluteString, location, notes].compactMap { $0 }.joined(separator: "\n")
        guard !combined.isEmpty else { return nil }

        // 빠른 O(1) 조기 탈출: 링크 스킴이 전혀 없는 일반 일정은 정규식 검사를 건너뜀
        let hasPotentialUrl = combined.contains("http://") ||
            combined.contains("https://") ||
            combined.contains("zoommtg://") ||
            combined.contains("msteams://") ||
            combined.contains("facetime://") ||
            combined.contains("facetime-audio://")
        guard hasPotentialUrl else { return nil }

        // HTML 엔티티 복원
        let sanitized = combined
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")

        // 2단계 안전 언래핑: SafeLinks 또는 Google Redirect 래퍼를 캡처하여 타깃 URL을 선두에 주입
        var workingText = sanitized
        if let safeLinkMatch = firstMatch(in: sanitized, regex: MeetingRegex.safeLinks),
           let unwrapped = unwrapRedirectUrl(from: safeLinkMatch) {
            workingText = "\(unwrapped)\n" + workingText
        } else if let googleMatch = firstMatch(in: sanitized, regex: MeetingRegex.googleRedirect),
                  let unwrapped = unwrapRedirectUrl(from: googleMatch) {
            workingText = "\(unwrapped)\n" + workingText
        }

        // 도메인 위조 피싱 방어: URL host 일치 검사 (서브도메인 위조 차단 및 상위 부모 도메인 무단 매칭 배제)
        func matchesDomain(_ url: URL, validDomains: [String]) -> Bool {
            guard let host = url.host?.lowercased() else { return false }
            return validDomains.contains { domain in
                host == domain || host.hasSuffix("." + domain)
            }
        }

        // 1. Google Meet (표준 코드, /lookup/..., /landing 등 모든 meet.google.com 경로 지원)
        if let match = firstMatch(in: workingText, regex: MeetingRegex.meet),
           var validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["meet.google.com"]) {
            // 다중 구글 계정 세션 충돌 방지를 위한 authuser 파라미터 자동 바인딩 (currentUser 이메일 한정)
            if let email = currentUserEmail, !email.isEmpty,
               var comps = URLComponents(url: validUrl, resolvingAgainstBaseURL: false) {
                var items = comps.queryItems ?? []
                if !items.contains(where: { $0.name.lowercased() == "authuser" }) {
                    items.append(URLQueryItem(name: "authuser", value: email))
                    comps.queryItems = items
                    if let augmented = comps.url {
                        validUrl = augmented
                    }
                }
            }
            return MeetingInfo(platform: .googleMeet, url: validUrl)
        }

        // 2. Zoom
        if let match = firstMatch(in: workingText, regex: MeetingRegex.zoom),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["zoom.us", "zoom.com", "zoom.gov", "zoom.de"]) {
            return MeetingInfo(platform: .zoom, url: validUrl)
        }

        // 3. Microsoft Teams
        if let match = firstMatch(in: workingText, regex: MeetingRegex.teams),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["teams.microsoft.com"]) {
            return MeetingInfo(platform: .teams, url: validUrl)
        }
        if let match = firstMatch(in: workingText, regex: MeetingRegex.teamsLive),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["teams.live.com"]) {
            return MeetingInfo(platform: .teams, url: validUrl)
        }

        // 4. Apple FaceTime (웹 링크 및 네이티브 스킴)
        if let match = firstMatch(in: workingText, regex: MeetingRegex.faceTime),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["facetime.apple.com"]) {
            return MeetingInfo(platform: .faceTime, url: validUrl)
        }
        if let match = firstMatch(in: workingText, regex: MeetingRegex.faceTimeScheme),
           let validUrl = sanitizeUrl(match) {
            return MeetingInfo(platform: .faceTime, url: validUrl)
        }

        // 5. Cisco Webex
        if let match = firstMatch(in: workingText, regex: MeetingRegex.webex),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["webex.com"]) {
            return MeetingInfo(platform: .webex, url: validUrl)
        }

        // 5. Naver Whale ON
        if let match = firstMatch(in: workingText, regex: MeetingRegex.whaleOn),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["whaleon.naver.com"]) {
            return MeetingInfo(platform: .whaleOn, url: validUrl)
        }

        // 6. Discord
        if let match = firstMatch(in: workingText, regex: MeetingRegex.discord),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["discord.gg", "discord.com"]) {
            return MeetingInfo(platform: .discord, url: validUrl)
        }

        // 7. Lark (Feishu)
        if let match = firstMatch(in: workingText, regex: MeetingRegex.lark),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["larksuite.com"]) {
            return MeetingInfo(platform: .lark, url: validUrl)
        }
        if let match = firstMatch(in: workingText, regex: MeetingRegex.feishu),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["feishu.cn"]) {
            return MeetingInfo(platform: .lark, url: validUrl)
        }

        // 8. Jitsi Meet
        if let match = firstMatch(in: workingText, regex: MeetingRegex.jitsi),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["meet.jit.si"]) {
            return MeetingInfo(platform: .jitsi, url: validUrl)
        }
        if let match = firstMatch(in: workingText, regex: MeetingRegex.jitsi8x8),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["8x8.vc"]) {
            return MeetingInfo(platform: .jitsi, url: validUrl)
        }

        // 9. Whereby
        if let match = firstMatch(in: workingText, regex: MeetingRegex.whereby),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["whereby.com"]) {
            return MeetingInfo(platform: .whereby, url: validUrl)
        }

        // 10. Amazon Chime
        if let match = firstMatch(in: workingText, regex: MeetingRegex.chime),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["app.chime.aws", "chime.aws"]) {
            return MeetingInfo(platform: .chime, url: validUrl)
        }

        // 11. 명시적 미팅 URL
        if let match = firstMatch(in: workingText, regex: MeetingRegex.genericMeeting),
           let validUrl = sanitizeUrl(match) {
            return MeetingInfo(platform: .generic, url: validUrl)
        }

        // 12. 미검증 외부 링크
        if let match = firstMatch(in: workingText, regex: MeetingRegex.anyUrl),
           let validUrl = sanitizeUrl(match) {
            return MeetingInfo(platform: .unverified, url: validUrl)
        }

        return nil
    }

    private static func firstMatch(in text: String, regex: NSRegularExpression?) -> String? {
        guard let regex = regex else { return nil }
        let nsString = text as NSString
        let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        guard let m = match else { return nil }
        return nsString.substring(with: m.range)
    }

    // MARK: 3-2. 일반 웹 링크 (세미나, 웨비나, 문서 등) 추출
    public static func extractDisplayHost(from url: URL) -> String {
        let targetString = unwrapRedirectUrl(from: url.absoluteString) ?? url.absoluteString
        guard let targetUrl = URL(string: targetString),
              let host = targetUrl.host?.lowercased() else {
            return url.host ?? url.absoluteString
        }
        if host.hasPrefix("www.") {
            return String(host.dropFirst(4))
        }
        return host
    }

    private static func isExcludedWebLink(candidateUrl: URL, meetingInfo: MeetingInfo?) -> Bool {
        // 화상회의 버튼 URL과 동일하면 제외 (공식 화상회의 버튼과 중복 방지)
        if let meeting = meetingInfo, meeting.platform != .unverified {
            if candidateUrl.absoluteString == meeting.url.absoluteString {
                return true
            }
            let unwrappedCandidate = unwrapRedirectUrl(from: candidateUrl.absoluteString) ?? candidateUrl.absoluteString
            let unwrappedMeeting = unwrapRedirectUrl(from: meeting.url.absoluteString) ?? meeting.url.absoluteString
            if unwrappedCandidate == unwrappedMeeting {
                return true
            }
        }

        let targetString = unwrapRedirectUrl(from: candidateUrl.absoluteString) ?? candidateUrl.absoluteString
        guard let target = URL(string: targetString),
              let host = target.host?.lowercased() else {
            return true
        }

        // 1. 공식 화상회의 플랫폼 도메인은 제외 (화상회의는 하단 전용 액션 버튼으로 표출)
        let meetingDomains = [
            "zoom.us", "zoom.com", "zoom.gov", "zoom.de",
            "meet.google.com",
            "teams.microsoft.com", "teams.live.com",
            "webex.com",
            "whaleon.naver.com",
            "discord.gg", "discord.com",
            "larksuite.com", "feishu.cn",
            "meet.jit.si", "8x8.vc",
            "whereby.com",
            "chime.aws", "facetime.apple.com"
        ]
        if meetingDomains.contains(where: { host == $0 || host.hasSuffix("." + $0) }) {
            return true
        }

        // 2. 캘린더 시스템 자동 첨부 및 관리 도메인은 제외 (구글/아웃룩 시스템 링크 및 미해결 리디렉터)
        if host == "calendar.google.com" || host.hasSuffix(".calendar.google.com") {
            return true
        }
        if (host == "google.com" || host.hasSuffix(".google.com")) && (target.path.hasPrefix("/calendar") || target.path == "/url") {
            return true
        }
        if host == "outlook.office.com" || host == "outlook.live.com" {
            if target.path.contains("/calendar") {
                return true
            }
        }
        if host == "dialin.teams.microsoft.com" ||
           target.path.contains("meetingOptions") ||
           target.path.contains("download") ||
           target.path.contains("JoinTeamsMeeting") {
            return true
        }

        // 3. 이미지 직접 링크 제외
        let pathExtension = target.pathExtension.lowercased()
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "svg", "webp", "bmp"]
        if imageExtensions.contains(pathExtension) {
            return true
        }

        return false
    }

    public static func extractWebLink(url: URL?, notes: String?, meetingInfo: MeetingInfo?) -> WebLinkInfo? {
        // 1순위: Apple 캘린더의 명시적 URL 필드 (ekEvent.url)
        if let explicitUrl = url {
            let scheme = explicitUrl.scheme?.lowercased()
            if scheme == "http" || scheme == "https" {
                if !isExcludedWebLink(candidateUrl: explicitUrl, meetingInfo: meetingInfo) {
                    let display = extractDisplayHost(from: explicitUrl)
                    return WebLinkInfo(url: explicitUrl, displayHost: display)
                }
            }
        }

        // 2순위: 본문 메모(notes)에서 첫 번째 유효한 외부 링크 추출 (구글 캘린더 등)
        // 시스템 보일러플레이트 노이즈가 제거된 사용자 순수 메모 영역에서만 링크를 탐색합니다.
        let cleanText = cleanNotes(from: notes)
        guard let notesText = cleanText, !notesText.isEmpty else { return nil }
        guard notesText.contains("http://") || notesText.contains("https://") else { return nil }

        // HTML 엔티티 복원
        let sanitized = notesText
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")

        guard let regex = MeetingRegex.anyUrl else { return nil }
        let nsString = sanitized as NSString
        let matches = regex.matches(in: sanitized, options: [], range: NSRange(location: 0, length: nsString.length))

        for m in matches {
            let rawMatch = nsString.substring(with: m.range)
            guard let candidateUrl = sanitizeUrl(rawMatch, allowedSchemes: ["http", "https"]) else {
                continue
            }

            if !isExcludedWebLink(candidateUrl: candidateUrl, meetingInfo: meetingInfo) {
                let display = extractDisplayHost(from: candidateUrl)
                return WebLinkInfo(url: candidateUrl, displayHost: display)
            }
        }

        return nil
    }
}

// MARK: - 4. 타임라인 세그먼트 및 클러스터링 데이터 모델
public struct EventCluster: Identifiable, Equatable, Sendable {
    public let id: String
    public let start: Date
    public let end: Date
    public let events: [CalendarEvent]

    public static func == (lhs: EventCluster, rhs: EventCluster) -> Bool {
        return lhs.id == rhs.id
    }
}

public struct TimelineSegment: Identifiable {
    public let id: String
    public let start: Date
    public let end: Date
    public let events: [CalendarEvent]
    public let cluster: EventCluster

    public var isOverlap: Bool {
        return events.count > 1
    }

    public var isInactive: Bool {
        events.allSatisfy { $0.isCanceledOrDeclined }
    }
}

// MARK: - 5. 일정 중첩 분석 및 시간 구간 슬라이싱 알고리즘
extension CalendarEvent {
    public static func buildSegments(from rawEvents: [CalendarEvent], dayStart: Date, dayEnd: Date) -> [TimelineSegment] {
        let timedEvents = filterAndSortEvents(rawEvents, dayStart: dayStart, dayEnd: dayEnd)
        guard !timedEvents.isEmpty else { return [] }

        // 1단계: 연속된 중첩 일정 클러스터링
        let clusters = createClusters(from: timedEvents, dayStart: dayStart, dayEnd: dayEnd)

        // 2단계: 시간 교차점 기준 세그먼트 분할
        return sliceClustersIntoSegments(clusters)
    }

    // 종일 일정을 제외하고 유효 시간 범위 내 일정을 시작 시각 순 정렬
    private static func filterAndSortEvents(_ rawEvents: [CalendarEvent], dayStart: Date, dayEnd: Date) -> [CalendarEvent] {
        return rawEvents.filter { !$0.isAllDay }.compactMap { event -> CalendarEvent? in
            let s = max(dayStart, event.startDate)
            let e = min(dayEnd, event.endDate)
            guard e > s else { return nil }
            return event
        }.sorted { $0.startDate < $1.startDate }
    }

    // 시간상 연속되거나 중첩된 일정들을 하나의 클러스터로 그룹화
    private static func createClusters(from timedEvents: [CalendarEvent], dayStart: Date, dayEnd: Date) -> [EventCluster] {
        var clusters: [EventCluster] = []
        var currentClusterEvents: [CalendarEvent] = []
        var clusterStart = timedEvents[0].startDate
        var clusterEnd = timedEvents[0].endDate

        for event in timedEvents {
            if event.startDate < clusterEnd {
                currentClusterEvents.append(event)
                if event.endDate > clusterEnd {
                    clusterEnd = event.endDate
                }
            } else {
                if !currentClusterEvents.isEmpty {
                    let stableId = currentClusterEvents.map { $0.id }.sorted().joined(separator: "_")
                    clusters.append(EventCluster(
                        id: stableId,
                        start: max(dayStart, clusterStart),
                        end: min(dayEnd, clusterEnd),
                        events: currentClusterEvents
                    ))
                }
                currentClusterEvents = [event]
                clusterStart = event.startDate
                clusterEnd = event.endDate
            }
        }

        if !currentClusterEvents.isEmpty {
            let stableId = currentClusterEvents.map { $0.id }.sorted().joined(separator: "_")
            clusters.append(EventCluster(
                id: stableId,
                start: max(dayStart, clusterStart),
                end: min(dayEnd, clusterEnd),
                events: currentClusterEvents
            ))
        }

        return clusters
    }

    // 클러스터 내부의 시작/종료 교차점들을 잘게 슬라이스하여 겹침 세그먼트 생성
    private static func sliceClustersIntoSegments(_ clusters: [EventCluster]) -> [TimelineSegment] {
        var segments: [TimelineSegment] = []

        for cluster in clusters {
            var timePoints = Set<TimeInterval>()
            timePoints.insert(cluster.start.timeIntervalSinceReferenceDate)
            timePoints.insert(cluster.end.timeIntervalSinceReferenceDate)
            for ev in cluster.events {
                let s = max(cluster.start, min(cluster.end, ev.startDate)).timeIntervalSinceReferenceDate
                let e = max(cluster.start, min(cluster.end, ev.endDate)).timeIntervalSinceReferenceDate
                timePoints.insert(s)
                timePoints.insert(e)
            }

            let sortedPoints = Array(timePoints).sorted()
            for i in 0..<(sortedPoints.count - 1) {
                let segStartSec = sortedPoints[i]
                let segEndSec = sortedPoints[i + 1]
                guard segEndSec > segStartSec else { continue }

                let segStart = Date(timeIntervalSinceReferenceDate: segStartSec)
                let segEnd = Date(timeIntervalSinceReferenceDate: segEndSec)
                let midSec = (segStartSec + segEndSec) / 2
                let midDate = Date(timeIntervalSinceReferenceDate: midSec)

                let active = cluster.events.filter { ev in
                    ev.startDate <= midDate && ev.endDate >= midDate
                }

                if !active.isEmpty {
                    let segmentId = "\(cluster.id)_\(Int(segStartSec))_\(Int(segEndSec))"
                    segments.append(TimelineSegment(
                        id: segmentId,
                        start: segStart,
                        end: segEnd,
                        events: active,
                        cluster: cluster
                    ))
                }
            }
        }

        return segments
    }
}

// MARK: - 6. HTML 태그 및 특수문자 엔티티 정제 확장
public extension String {
    func strippingHTMLTags() -> String {
        var text = self
            .replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "</p>", with: "\n", options: .caseInsensitive)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&#x27;", with: "'")

        text = text.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - 7. macOS 캘린더 앱 연동 실행기
public enum CalendarAppLauncher {
    public static func open(event: CalendarEvent? = nil) {
        // 일정이 전달된 경우 캘린더 앱에서 해당 날짜로 이동을 시도합니다.
        if let event = event {
            let cal = Calendar.current
            let y = cal.component(.year, from: event.startDate)
            let m = cal.component(.month, from: event.startDate)
            let d = cal.component(.day, from: event.startDate)

            let scriptSource = """
            tell application "Calendar"
                activate
                view date (date ("\(m)/\(d)/\(y)"))
            end tell
            """
            if let script = NSAppleScript(source: scriptSource) {
                var errorDict: NSDictionary?
                script.executeAndReturnError(&errorDict)
                if errorDict == nil {
                    return
                }
            }
        }

        // 특정 날짜 이동이 필요 없거나 스크립트 실행 실패 시 캘린더 앱을 바로 엽니다.
        if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") {
            NSWorkspace.shared.openApplication(at: appUrl, configuration: NSWorkspace.OpenConfiguration())
        } else {
            let defaultPath = URL(fileURLWithPath: "/System/Applications/Calendar.app")
            if FileManager.default.fileExists(atPath: defaultPath.path) {
                NSWorkspace.shared.open(defaultPath)
            }
        }
    }
}

// MARK: - 8. 화상회의 네이티브 앱 다이렉트 실행기 및 웹 폴백
public enum MeetingAppLauncher {
    public static func open(meeting: MeetingInfo) {
        if let nativeUrl = nativeSchemeUrl(for: meeting) {
            if NSWorkspace.shared.open(nativeUrl) {
                return
            }
        }
        // 네이티브 앱 미설치 또는 스킴 지원 불가 시 웹 브라우저 폴백
        NSWorkspace.shared.open(meeting.url)
    }

    public static func nativeSchemeUrl(for meeting: MeetingInfo) -> URL? {
        let url = meeting.url
        switch meeting.platform {
        case .teams:
            // https://teams.microsoft.com/... -> msteams://teams.microsoft.com/...
            if var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                comps.scheme = "msteams"
                return comps.url
            }
        case .zoom:
            // zoommtg://zoom.us/join?confno=... (단, /my/ 개인 룸은 웹 유지)
            guard let host = url.host?.lowercased(), host.contains("zoom"),
                  !url.path.contains("/my/") else { return nil }
            let urlString = url.absoluteString
                .replacingOccurrences(of: "?", with: "&")
                .replacingOccurrences(of: "/j/", with: "/join?confno=")
            if var comps = URLComponents(string: urlString) {
                comps.scheme = "zoommtg"
                return comps.url
            }
        case .webex:
            // https://*.webex.com/... -> webex://...
            if var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                comps.scheme = "webex"
                return comps.url
            }
        case .discord:
            // discord://...
            if var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                comps.scheme = "discord"
                return comps.url
            }
        case .faceTime:
            let scheme = url.scheme?.lowercased()
            if scheme == "facetime" || scheme == "facetime-audio" {
                return url
            }
        default:
            break
        }
        return nil
    }
}

// MARK: - 9. 배열 안전 인덱스 참조 유틸리티
extension Array {
    public subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

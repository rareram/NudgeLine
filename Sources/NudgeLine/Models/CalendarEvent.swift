// 캘린더 이벤트 모델, 화상회의 링크 정규식 파서, 일정 클러스터링 및 세그먼트 슬라이싱
import Foundation
import SwiftUI
import EventKit

// MARK: - 1. 화상회의 플랫폼 열거형 및 메타데이터
public enum MeetingPlatform: String, Hashable, Sendable {
    case googleMeet = "Google Meet"
    case zoom = "Zoom"
    case teams = "Microsoft Teams"
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
    public let meetingInfo: MeetingInfo?

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
        self.meetingInfo = CalendarEvent.extractMeetingInfo(url: ekEvent.url, location: ekEvent.location, notes: ekEvent.notes)
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
        meetingInfo: MeetingInfo? = nil
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
        self.meetingInfo = meetingInfo
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

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(startDate)
        hasher.combine(endDate)
        hasher.combine(rawTitle)
        hasher.combine(isAllDay)
        hasher.combine(calendarIdentifier)
    }

    public static func == (lhs: CalendarEvent, rhs: CalendarEvent) -> Bool {
        return lhs.id == rhs.id &&
            lhs.startDate == rhs.startDate &&
            lhs.endDate == rhs.endDate &&
            lhs.rawTitle == rhs.rawTitle &&
            lhs.isAllDay == rhs.isAllDay &&
            lhs.calendarIdentifier == rhs.calendarIdentifier
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
        static let anyUrl = try? NSRegularExpression(pattern: #"https?://[a-zA-Z0-9.\-_]+\.[a-zA-Z]{2,}[a-zA-Z0-9_.\-/?=&%]*"#, options: [.caseInsensitive])
    }

    // 본문/위치/URL 내 화상회의 링크 정규식 추출
    private static func extractMeetingInfo(url: URL?, location: String?, notes: String?) -> MeetingInfo? {
        let combined = [url?.absoluteString, location, notes].compactMap { $0 }.joined(separator: "\n")
        guard !combined.isEmpty else { return nil }

        // 빠른 O(1) 조기 탈출: 링크 스킴이 전혀 없는 일반 일정은 정규식 검사를 건너뜀
        let hasPotentialUrl = combined.contains("http://") ||
            combined.contains("https://") ||
            combined.contains("zoommtg://") ||
            combined.contains("msteams://")
        guard hasPotentialUrl else { return nil }

        // HTML 엔티티 복원
        let sanitized = combined
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")

        // URL 끝단 특수문자 정제
        func sanitizeUrl(_ raw: String) -> URL? {
            var trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            let trailingPunctuation = CharacterSet(charactersIn: ".,;:)>]}'\"`")
            while let last = trimmed.unicodeScalars.last, trailingPunctuation.contains(last) {
                trimmed.removeLast()
            }
            if let validUrl = URL(string: trimmed),
               let scheme = validUrl.scheme?.lowercased(),
               (scheme == "http" || scheme == "https" || scheme == "zoommtg" || scheme == "msteams") {
                return validUrl
            }
            return nil
        }

        // 도메인 위조 피싱 방어: URL host 일치 검사 (서브도메인 위조 차단 및 상위 부모 도메인 무단 매칭 배제)
        func matchesDomain(_ url: URL, validDomains: [String]) -> Bool {
            guard let host = url.host?.lowercased() else { return false }
            return validDomains.contains { domain in
                host == domain || host.hasSuffix("." + domain)
            }
        }

        // 1. Google Meet (표준 코드, /lookup/..., /landing 등 모든 meet.google.com 경로 지원)
        if let match = firstMatch(in: sanitized, regex: MeetingRegex.meet),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["meet.google.com"]) {
            return MeetingInfo(platform: .googleMeet, url: validUrl)
        }

        // 2. Zoom
        if let match = firstMatch(in: sanitized, regex: MeetingRegex.zoom),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["zoom.us", "zoom.com", "zoom.gov", "zoom.de"]) {
            return MeetingInfo(platform: .zoom, url: validUrl)
        }

        // 3. Microsoft Teams
        if let match = firstMatch(in: sanitized, regex: MeetingRegex.teams),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["teams.microsoft.com"]) {
            return MeetingInfo(platform: .teams, url: validUrl)
        }
        if let match = firstMatch(in: sanitized, regex: MeetingRegex.teamsLive),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["teams.live.com"]) {
            return MeetingInfo(platform: .teams, url: validUrl)
        }

        // 4. Cisco Webex
        if let match = firstMatch(in: sanitized, regex: MeetingRegex.webex),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["webex.com"]) {
            return MeetingInfo(platform: .webex, url: validUrl)
        }

        // 5. Naver Whale ON
        if let match = firstMatch(in: sanitized, regex: MeetingRegex.whaleOn),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["whaleon.naver.com"]) {
            return MeetingInfo(platform: .whaleOn, url: validUrl)
        }

        // 6. Discord
        if let match = firstMatch(in: sanitized, regex: MeetingRegex.discord),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["discord.gg", "discord.com"]) {
            return MeetingInfo(platform: .discord, url: validUrl)
        }

        // 7. Lark (Feishu)
        if let match = firstMatch(in: sanitized, regex: MeetingRegex.lark),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["larksuite.com"]) {
            return MeetingInfo(platform: .lark, url: validUrl)
        }
        if let match = firstMatch(in: sanitized, regex: MeetingRegex.feishu),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["feishu.cn"]) {
            return MeetingInfo(platform: .lark, url: validUrl)
        }

        // 8. Jitsi Meet
        if let match = firstMatch(in: sanitized, regex: MeetingRegex.jitsi),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["meet.jit.si"]) {
            return MeetingInfo(platform: .jitsi, url: validUrl)
        }
        if let match = firstMatch(in: sanitized, regex: MeetingRegex.jitsi8x8),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["8x8.vc"]) {
            return MeetingInfo(platform: .jitsi, url: validUrl)
        }

        // 9. Whereby
        if let match = firstMatch(in: sanitized, regex: MeetingRegex.whereby),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["whereby.com"]) {
            return MeetingInfo(platform: .whereby, url: validUrl)
        }

        // 10. Amazon Chime
        if let match = firstMatch(in: sanitized, regex: MeetingRegex.chime),
           let validUrl = sanitizeUrl(match),
           matchesDomain(validUrl, validDomains: ["app.chime.aws", "chime.aws"]) {
            return MeetingInfo(platform: .chime, url: validUrl)
        }

        // 11. 명시적 미팅 URL
        if let match = firstMatch(in: sanitized, regex: MeetingRegex.genericMeeting),
           let validUrl = sanitizeUrl(match) {
            return MeetingInfo(platform: .generic, url: validUrl)
        }

        // 12. 미검증 외부 링크
        if let match = firstMatch(in: sanitized, regex: MeetingRegex.anyUrl),
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
        // 날짜 지정 시 AppleScript로 해당 날짜 화면 이동
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

        // 기본 번들 ID 기반 캘린더 앱 실행
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

// MARK: - 8. 배열 안전 인덱스 참조 유틸리티
extension Array {
    public subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

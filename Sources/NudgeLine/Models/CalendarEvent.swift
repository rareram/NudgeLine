// 캘린더 이벤트 모델, 화상회의 링크 정규식 파서, 일정 클러스터링 및 세그먼트 슬라이싱
import Foundation
import SwiftUI
import EventKit

// 지원 화상회의 플랫폼
public enum MeetingPlatform: String, Hashable {
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
public struct MeetingInfo: Hashable {
    public let platform: MeetingPlatform
    public let url: URL
}

// EventKit 래퍼 일정 데이터 모델
public struct CalendarEvent: Identifiable, Hashable {
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

    // 본문/위치/URL 내 화상회의 링크 정규식 추출
    private static func extractMeetingInfo(url: URL?, location: String?, notes: String?) -> MeetingInfo? {
        let combined = [url?.absoluteString, location, notes].compactMap { $0 }.joined(separator: "\n")
        guard !combined.isEmpty else { return nil }

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
               (scheme == "http" || scheme == "https") {
                return validUrl
            }
            if let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let validUrl = URL(string: encoded),
               let scheme = validUrl.scheme?.lowercased(),
               (scheme == "http" || scheme == "https") {
                return validUrl
            }
            return nil
        }

        // 도메인 위조 피싱 방어: URL host 끝자리 일치 검사 (예: teams.microsoft.com.evil.com 차단)
        func matchesDomain(_ rawHost: String, targets: [String]) -> Bool {
            let host = rawHost.trimmingCharacters(in: CharacterSet(charactersIn: "."))
            return targets.contains { target in
                host == target || host.hasSuffix("." + target)
            }
        }

        // 공식 화상회의 플랫폼 화이트리스트 1차 판별 (매칭 실패 시 nil)
        func identifyOfficialPlatform(for candidateUrl: URL) -> MeetingInfo? {
            guard let rawHost = candidateUrl.host?.lowercased() else { return nil }
            let host = rawHost.trimmingCharacters(in: CharacterSet(charactersIn: "."))

            // Microsoft Teams
            if matchesDomain(host, targets: ["teams.microsoft.com", "teams.live.com", "teams.cloud.microsoft"]) {
                return MeetingInfo(platform: .teams, url: candidateUrl)
            }

            // Google Meet
            if matchesDomain(host, targets: ["meet.google.com"]) {
                return MeetingInfo(platform: .googleMeet, url: candidateUrl)
            }

            // Zoom
            if matchesDomain(host, targets: ["zoom.us", "zoom.com", "zoom.gov", "zoom.com.cn"]) {
                return MeetingInfo(platform: .zoom, url: candidateUrl)
            }

            // Webex
            if matchesDomain(host, targets: ["webex.com"]) {
                return MeetingInfo(platform: .webex, url: candidateUrl)
            }

            // Naver Whale ON
            if matchesDomain(host, targets: ["whale.naver.com", "whaleon.naver.com"]) {
                return MeetingInfo(platform: .whaleOn, url: candidateUrl)
            }

            // Discord
            if matchesDomain(host, targets: ["discord.com", "discord.gg"]) {
                return MeetingInfo(platform: .discord, url: candidateUrl)
            }

            // Lark / Feishu
            if matchesDomain(host, targets: ["larksuite.com", "feishu.cn"]) {
                return MeetingInfo(platform: .lark, url: candidateUrl)
            }

            // Jitsi Meet
            if matchesDomain(host, targets: ["meet.jit.si"]) {
                return MeetingInfo(platform: .jitsi, url: candidateUrl)
            }

            // Whereby
            if matchesDomain(host, targets: ["whereby.com"]) {
                return MeetingInfo(platform: .whereby, url: candidateUrl)
            }

            // Amazon Chime
            if matchesDomain(host, targets: ["chime.aws"]) {
                return MeetingInfo(platform: .chime, url: candidateUrl)
            }

            // 기타 공식 플랫폼 (Gather, VooV 등)
            if matchesDomain(host, targets: ["gather.town", "voovmeeting.com", "meeting.tencent.com"]) {
                return MeetingInfo(platform: .generic, url: candidateUrl)
            }

            return nil
        }

        // 1단계: 본문 내 모든 URL 파싱 및 정제
        let urlPattern = "https?://[^\\s<>\"]+"
        var candidateUrls: [URL] = []

        if let matches = matchAllRegex(pattern: urlPattern, in: sanitized) {
            for rawUrl in matches {
                if let validUrl = sanitizeUrl(rawUrl) {
                    candidateUrls.append(validUrl)
                }
            }
        }

        if let eventUrl = url, let validUrl = sanitizeUrl(eventUrl.absoluteString) {
            if !candidateUrls.contains(validUrl) {
                candidateUrls.append(validUrl)
            }
        }

        guard !candidateUrls.isEmpty else { return nil }

        // 2단계: 공식 화상회의 화이트리스트 우선 탐색 (First-Match 역전 방지)
        for candidate in candidateUrls {
            if let official = identifyOfficialPlatform(for: candidate) {
                return official
            }
        }

        // 3단계: 공식 플랫폼이 없는 경우, 첫 번째 유효 URL을 미검증 링크로 안전하게 폴백
        if let firstCandidate = candidateUrls.first {
            return MeetingInfo(platform: .unverified, url: firstCandidate)
        }

        return nil
    }

    private static func matchAllRegex(pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let nsString = text as NSString
        let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        guard !results.isEmpty else { return nil }
        return results.map { nsString.substring(with: $0.range) }
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
    }

    public static func == (lhs: CalendarEvent, rhs: CalendarEvent) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - 중첩 일정 클러스터 모델
public struct EventCluster: Identifiable, Equatable {
    public let id: String
    public let start: Date
    public let end: Date
    public let events: [CalendarEvent]

    public static func == (lhs: EventCluster, rhs: EventCluster) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - 타임라인 단위 세그먼트 슬라이스 모델
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

// MARK: - 일정 중첩 분석 및 시간 구간 슬라이싱
extension CalendarEvent {
    public static func buildSegments(from rawEvents: [CalendarEvent], dayStart: Date, dayEnd: Date) -> [TimelineSegment] {
        let timedEvents = rawEvents.filter { !$0.isAllDay }.compactMap { event -> CalendarEvent? in
            let s = max(dayStart, event.startDate)
            let e = min(dayEnd, event.endDate)
            guard e > s else { return nil }
            return event
        }.sorted { $0.startDate < $1.startDate }

        guard !timedEvents.isEmpty else { return [] }

        // 1. 연속된 중첩 일정 클러스터링
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

        // 2. 시간 교차점 기준 세그먼트 분할
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

// MARK: - HTML 태그 및 엔티티 정제 확장
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

// MARK: - Apple 캘린더 앱 연동 실행기
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

// MARK: - 배열 안전 인덱스 참조 확장
extension Array {
    public subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

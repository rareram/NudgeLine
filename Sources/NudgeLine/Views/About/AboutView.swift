// NudgeLine 앱 정보(About) 윈도우 컨트롤러 및 뷰
import SwiftUI
import AppKit

// MARK: - 1. NudgeLine 앱 정보 뷰 (AboutView)
public struct AboutView: View {
    @ObservedObject private var settings = AppSettings.shared

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.4"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "439"
    }

    public init() {}

    public var body: some View {
        VStack(spacing: 11) {
            // 84pt 고해상도 앱 아이콘
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 84, height: 84)
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)

            // 타이틀, 버전 및 감성 부제목
            VStack(spacing: 3) {
                Text("NudgeLine")
                    .font(.system(size: 19, weight: .bold))

                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Text(L10n.tr(.appDescription, lang: settings.language))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.top, 2)
            }

            Divider()
                .padding(.horizontal, 16)
                .padding(.vertical, 2)

            // 최신 빌드 핵심 변경 사항 하이라이트 박스 (고정 상시 노출)
            VStack(alignment: .leading, spacing: 6) {
                Text("v\(appVersion) (Build \(buildNumber)) \(L10n.tr(.releaseHighlightsTitle, lang: settings.language))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(LocalizedStringKey(L10n.tr(.releaseHighlights, lang: settings.language)))
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
            .cornerRadius(8)
            .padding(.horizontal, 22)

            // 외부 액션 링크 버튼군
            HStack(spacing: 8) {
                Link(destination: UpdateService.repoURL) {
                    Text(L10n.tr(.aboutViewRepo, lang: settings.language))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Link(destination: URL(string: "https://github.com/rareram/NudgeLine/issues")!) {
                    Text(L10n.tr(.aboutFeedback, lang: settings.language))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 22)

            // 저작권 표시
            Text("Copyright © 2026 rareram. All rights reserved.")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .padding(.vertical, 16)
        .frame(width: 320)
    }
}

// MARK: - 2. 앱 정보 윈도우 컨트롤러 (AboutWindowController)
public final class AboutWindowController: NSWindowController {
    public static let shared = AboutWindowController()

    private static let windowWidth: CGFloat = 320
    private static let windowHeight: CGFloat = 385

    private init() {
        let hostingController = NSHostingController(rootView: AboutView())
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Self.windowWidth, height: Self.windowHeight),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.contentViewController = hostingController
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 앱 정보 단일 윈도우 활성화 및 포커스 부여
    public func show() {
        guard let window = self.window else { return }
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
}

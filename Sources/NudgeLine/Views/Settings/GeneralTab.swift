// 환경설정 탭 4: 일반 설정 (언어, 로그인 시 자동 실행, 모든 화면 표시, 앱 정보)
import AppKit
import SwiftUI

struct GeneralTab: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject private var launchHelper = LaunchAtLoginHelper.shared
    @State private var updateStatus: UpdateCheckStatus = .idle
    @State private var logoClickCount: Int = 0
    @State private var lastLogoClickTime: Date = .distantPast
    @State private var showPawPrints: Bool = false
    @State private var logoBounce: Bool = false
    @State private var pawPrints: [PawPrintItem] = []

    var body: some View {
        VStack(spacing: 12) {
            // 앱 정보 헤더
            VStack(spacing: 6) {
                if let appIcon = NSImage(named: "AppIcon") ?? NSApp.applicationIconImage {
                    Image(nsImage: appIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 56, height: 56)
                        .scaleEffect(logoBounce ? 1.2 : 1.0)
                        .rotationEffect(.degrees(logoBounce ? 12 : 0))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            handleLogoClick()
                        }
                }

                Text(settings.isDevBuild ? "NudgeLine (Dev)" : "NudgeLine")
                    .font(.title3)
                    .fontWeight(.bold)

                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"
                let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "60"
                HStack(spacing: 6) {
                    Text("Version \(appVersion) (Build \(buildNumber))\(settings.isDevBuild ? " [DEV]" : "")")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    updateCheckView(currentVersion: appVersion, currentBuild: buildNumber)
                }

                Text(L10n.tr(.appDescription, lang: settings.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 2)
                    .padding(.bottom, 6)
            }
            .padding(.top, 4)

            // 시스템 환경설정 폼
            Form {
                Section(header: Text(L10n.tr(.systemPreferencesSection, lang: settings.language)).fontWeight(.semibold)) {
                    LabeledContent {
                        HStack {
                            Picker("", selection: $settings.language) {
                                ForEach(AppLanguage.allCases, id: \.self) { lang in
                                    Text(lang.title).tag(lang)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .fixedSize()
                            Spacer()
                        }
                    } label: {
                        Text(L10n.tr(.languageLabel, lang: settings.language))
                            .frame(minWidth: 100, alignment: .trailing)
                    }

                    LabeledContent {
                        HStack {
                            Picker("", selection: $settings.preferredMapService) {
                                ForEach(PreferredMapService.allCases) { service in
                                    Text(service.title(lang: settings.language)).tag(service)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .fixedSize()
                            Spacer()
                        }
                    } label: {
                        Text(L10n.tr(.preferredMapServiceLabel, lang: settings.language))
                            .frame(minWidth: 100, alignment: .trailing)
                    }

                    Toggle(L10n.tr(.launchAtLogin, lang: settings.language), isOn: Binding(
                        get: { launchHelper.isEnabled },
                        set: { launchHelper.setEnabled($0) }
                    ))

                    Toggle(L10n.tr(.showOnAllScreens, lang: settings.language), isOn: $settings.showOnAllScreens)

                    Toggle(L10n.tr(.hideOnScreenShareLabel, lang: settings.language), isOn: $settings.hideOnScreenShare)

                    Toggle(L10n.tr(.hideOnFullScreenLabel, lang: settings.language), isOn: $settings.hideOnFullScreen)
                }
            }
            .formStyle(.columns)
            .padding(.horizontal, 16)
            .padding(.vertical, 4)

            // 하단 크레딧 및 종료
            VStack(spacing: 6) {
                Link(L10n.tr(.githubRepo, lang: settings.language), destination: UpdateService.repoURL)
                    .font(.system(size: 11))

                Text(L10n.tr(.creditsOriginal, lang: settings.language))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)

                Button(role: .destructive, action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text(L10n.tr(.quit, lang: settings.language))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
        .background {
            if showPawPrints {
                GeometryReader { geo in
                    ForEach(pawPrints) { item in
                        Image(systemName: "pawprint.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: item.size, height: item.size)
                            .foregroundStyle(Color.primary)
                            .opacity(item.opacity)
                            .rotationEffect(item.angle)
                            .position(x: geo.size.width * item.xRatio, y: geo.size.height * item.yRatio)
                    }
                }
                .allowsHitTesting(false)
                .transition(.opacity)
            }
        }
    }
}

// MARK: - 2. 업데이트 확인 상태 모델 및 뷰 (Update Check Model & Views)
enum UpdateCheckStatus: Equatable {
    case idle
    case checking
    case upToDate
    case newVersion(UpdateService.ReleaseInfo)
    case failed
}

extension GeneralTab {
    @ViewBuilder
    func updateCheckView(currentVersion: String, currentBuild: String) -> some View {
        HStack(spacing: 4) {
            switch updateStatus {
            case .idle:
                Button(action: { checkForUpdates(currentVersion: currentVersion, currentBuild: currentBuild) }) {
                    Text(L10n.tr(.checkForUpdates, lang: settings.language))
                        .font(.caption)
                }
                .buttonStyle(.link)

            case .checking:
                ProgressView()
                    .controlSize(.mini)
                Text(L10n.tr(.checkingForUpdates, lang: settings.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)

            case .upToDate:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                Text(L10n.tr(.upToDate, lang: settings.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)

            case .newVersion(let release):
                HStack(spacing: 5) {
                    Text(L10n.tr(.newVersionAvailable(release.version), lang: settings.language))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)

                    if release.zipURL != nil {
                        Button(action: {
                            UpdateService.shared.startInAppDownload(release: release)
                        }) {
                            Text(L10n.tr(.updateNowInApp, lang: settings.language))
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.mini)
                    } else {
                        Link(L10n.tr(.viewRelease, lang: settings.language), destination: release.url)
                            .font(.caption)
                    }
                }

            case .failed:
                Text(L10n.tr(.checkUpdateFailed, lang: settings.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(action: { checkForUpdates(currentVersion: currentVersion, currentBuild: currentBuild) }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func checkForUpdates(currentVersion: String, currentBuild: String) {
        updateStatus = .checking
        UpdateService.shared.fetchLatestRelease { result in
            switch result {
            case .success(let release):
                if UpdateService.isNewerVersion(latest: release.version, current: currentVersion, currentBuild: currentBuild) {
                    self.updateStatus = .newVersion(release)
                } else {
                    self.updateStatus = .upToDate
                }
            case .failure:
                self.updateStatus = .failed
            }
        }
    }
}

private struct PawPrintItem: Identifiable {
    let id: Int
    let xRatio: CGFloat
    let yRatio: CGFloat
    let size: CGFloat
    let angle: Angle
    let opacity: Double
}

extension GeneralTab {
    private func handleLogoClick() {
        let now = Date()
        if now.timeIntervalSince(lastLogoClickTime) > 1.5 {
            logoClickCount = 1
        } else {
            logoClickCount += 1
        }
        lastLogoClickTime = now

        if logoClickCount >= 7 {
            logoClickCount = 0
            pawPrints = generatePawPrints()

            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                logoBounce = true
            }
            withAnimation(.easeIn(duration: 0.5)) {
                showPawPrints = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    logoBounce = false
                }
            }
        }
    }

    private func generatePawPrints() -> [PawPrintItem] {
        var prints: [PawPrintItem] = []

        let spots: [(x: CGFloat, y: CGFloat, angle: Double)] = [
            (0.16, 0.20, -35),
            (0.28, 0.14, -10),
            (0.82, 0.18, 45),
            (0.70, 0.28, 65),
            (0.38, 0.40, -75),
            (0.54, 0.48, 20),
            (0.68, 0.56, -45),
            (0.15, 0.62, 85),
            (0.25, 0.76, 35),
            (0.85, 0.68, -115),
            (0.72, 0.84, -85),
            (0.44, 0.82, -15),
            (0.32, 0.08, -50),
            (0.66, 0.10, 30)
        ]

        for (index, spot) in spots.enumerated() {
            let randomX = spot.x + CGFloat.random(in: -0.04...0.04)
            let randomY = spot.y + CGFloat.random(in: -0.04...0.04)
            let size = CGFloat.random(in: 50...100)
            let opacity = Double.random(in: 0.20...0.35)
            let angle = Angle.degrees(spot.angle + Double.random(in: -30...30))

            prints.append(PawPrintItem(
                id: index,
                xRatio: min(max(randomX, 0.06), 0.94),
                yRatio: min(max(randomY, 0.06), 0.94),
                size: size,
                angle: angle,
                opacity: opacity
            ))
        }

        return prints
    }
}

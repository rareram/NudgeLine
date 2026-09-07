// 환경설정 탭 4: 일반 설정 (언어, 로그인 시 자동 실행, 모든 화면 표시, 앱 정보)
import AppKit
import SwiftUI

struct GeneralTab: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject private var launchHelper = LaunchAtLoginHelper.shared
    @State private var updateStatus: UpdateCheckStatus = .idle

    var body: some View {
        VStack(spacing: 12) {
            // 앱 정보 헤더
            VStack(spacing: 6) {
                if let appIcon = NSImage(named: "AppIcon") ?? NSApp.applicationIconImage {
                    Image(nsImage: appIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 56, height: 56)
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
    }
}

// MARK: - 2. 업데이트 확인 상태 모델 및 뷰 (Update Check Model & Views)
enum UpdateCheckStatus: Equatable {
    case idle
    case checking
    case upToDate
    case newVersion(String, URL)
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

            case .newVersion(let version, let url):
                HStack(spacing: 4) {
                    Text(L10n.tr(.newVersionAvailable(version), lang: settings.language))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    Link(L10n.tr(.viewRelease, lang: settings.language), destination: url)
                        .font(.caption)
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
                    self.updateStatus = .newVersion(release.version, release.url)
                } else {
                    self.updateStatus = .upToDate
                }
            case .failure:
                self.updateStatus = .failed
            }
        }
    }
}

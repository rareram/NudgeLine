// 환경설정 탭 4: 일반 설정 (언어, 로그인 시 자동 실행, 모든 화면 표시, 앱 정보)
import AppKit
import SwiftUI

struct GeneralTab: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject private var launchHelper = LaunchAtLoginHelper.shared

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
                Text("Version \(appVersion) (Build \(buildNumber))\(settings.isDevBuild ? " [DEV]" : "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(L10n.tr(.appDescription, lang: settings.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
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
            VStack(spacing: 8) {
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
            }
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
    }
}

// 환경설정 탭 4: 미리알림 연동 설정 (연동 활성화, 마커 타이밍, 활성 목록 필터)
import AppKit
import EventKit
import SwiftUI

struct RemindersTab: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var reminderService: ReminderService

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                // 1. 미리알림 연동 활성화
                Section(header: Text(L10n.tr(.remindersIntegrationSection, lang: settings.language)).fontWeight(.semibold)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle(L10n.tr(.enableRemindersLabel, lang: settings.language), isOn: $settings.enableReminders)
                            .onChange(of: settings.enableReminders) { _, enabled in
                                if enabled && !reminderService.isAuthorized() {
                                    reminderService.requestAccess()
                                }
                            }
                        Text(L10n.tr(.enableRemindersDescription, lang: settings.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 18)
                    }
                }

                Divider().opacity(0.4).padding(.vertical, 4)

                // 2. 마커 설정 (표시 범위, 표시 모양)
                Section(header: Text(L10n.tr(.reminderProximitySection, lang: settings.language)).fontWeight(.semibold)) {
                    LabeledContent(L10n.tr(.reminderProximityLabel, lang: settings.language)) {
                        HStack {
                            Picker("", selection: $settings.reminderProximityMinutes) {
                                Text(L10n.tr(.reminderRange1Hour, lang: settings.language)).tag(60)
                                Text(L10n.tr(.reminderRange2Hours, lang: settings.language)).tag(120)
                                Text(L10n.tr(.reminderRange3Hours, lang: settings.language)).tag(180)
                                Text(L10n.tr(.reminderRange4Hours, lang: settings.language)).tag(240)
                                Text(L10n.tr(.reminderRange12Hours, lang: settings.language)).tag(720)
                                Text(L10n.tr(.reminderRangeAllDay, lang: settings.language)).tag(1440)
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 150, alignment: .leading)
                            Spacer()
                        }
                    }

                    LabeledContent(L10n.tr(.reminderMarkerStyleLabel, lang: settings.language)) {
                        HStack(spacing: 8) {
                            Picker("", selection: $settings.reminderMarkerStyle) {
                                ForEach(ReminderMarkerStyle.allCases) { style in
                                    Text(style.title(lang: settings.language)).tag(style)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 150, alignment: .leading)

                            Button(L10n.tr(.previewLabel, lang: settings.language)) {
                                NotificationCenter.default.post(name: .previewReminderMarker, object: nil)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            Spacer()
                        }
                    }
                }
                .disabled(!settings.enableReminders)
                .opacity(settings.enableReminders ? 1.0 : 0.45)

                Divider().opacity(0.4).padding(.vertical, 4)

                // 3. 표시할 미리알림 목록
                Section(header: Text(L10n.tr(.visibleReminderListsSection, lang: settings.language)).fontWeight(.semibold)) {
                    if !settings.enableReminders {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L10n.tr(.enableRemindersDescription, lang: settings.language))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .frame(height: 180, alignment: .topLeading)
                    } else if !reminderService.isAuthorized() {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.tr(.remindersPermissionNeeded, lang: settings.language))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            HStack {
                                Button(L10n.tr(.requestPermission, lang: settings.language)) {
                                    reminderService.requestAccess()
                                }
                                .buttonStyle(.borderedProminent)

                                Button(L10n.tr(.openSystemPrivacy, lang: settings.language)) {
                                    ReminderService.openPrivacySettings()
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .frame(height: 180, alignment: .topLeading)
                    } else if reminderService.reminderLists.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L10n.tr(.noReminderLists, lang: settings.language))
                                .foregroundStyle(.secondary)
                            Button(L10n.tr(.refresh, lang: settings.language)) {
                                reminderService.refreshSources()
                                reminderService.loadReminderLists()
                                reminderService.fetchReminders()
                            }
                        }
                        .padding(.vertical, 4)
                        .frame(height: 180, alignment: .topLeading)
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                ForEach(reminderService.reminderLists) { list in
                                    ReminderListRowView(list: list, settings: settings)
                                        .padding(.horizontal, 8)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .frame(height: 180)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )

                        HStack(spacing: 12) {
                            Button(action: openRemindersNativeApp) {
                                Label(L10n.tr(.openRemindersApp, lang: settings.language), systemImage: "checklist")
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)

                            Spacer()

                            Button(action: {
                                reminderService.refreshSources()
                                reminderService.loadReminderLists()
                                reminderService.fetchReminders()
                            }) {
                                Label(L10n.tr(.refresh, lang: settings.language), systemImage: "arrow.clockwise")
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
                .disabled(!settings.enableReminders)
                .opacity(settings.enableReminders ? 1.0 : 0.45)
            }
            .formStyle(.columns)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .onAppear {
            if settings.enableReminders {
                reminderService.checkAuthorizationStatus()
            }
        }
    }

    private func openRemindersNativeApp() {
        if let url = URL(string: "x-apple-reminderkit://") {
            NSWorkspace.shared.open(url)
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Reminders.app"))
        }
    }
}

// MARK: - 개별 미리알림 목록 행 뷰
private struct ReminderListRowView: View {
    let list: ReminderListInfo
    @ObservedObject var settings: AppSettings

    var body: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: Binding(
                get: { settings.isReminderListVisible(id: list.id) },
                set: { settings.setReminderListVisible(id: list.id, visible: $0) }
            ))
            .labelsHidden()

            Circle()
                .fill(list.color)
                .frame(width: 10, height: 10)

            Text(list.title)
                .font(.body)
                .lineLimit(1)

            Spacer()

            Text(list.sourceTitle)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }
}

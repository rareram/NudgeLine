// 환경설정 탭 3: 일정 및 캘린더 설정 (근무 시간, 활성 캘린더 목록, 개별 색상)
import AppKit
import EventKit
import SwiftUI

struct ScheduleTab: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var calendarService: CalendarService

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                // 1. 근무 시간 설정
                Section(header: Text(L10n.tr(.workHoursSection, lang: settings.language)).fontWeight(.semibold)) {
                    Toggle(L10n.tr(.mode24Hours, lang: settings.language), isOn: $settings.is24HourMode)

                    LabeledContent(L10n.tr(.workStartTime, lang: settings.language)) {
                        HStack(spacing: 6) {
                            Picker("", selection: $settings.startHour) {
                                ForEach(0..<24, id: \.self) { h in
                                    Text(String(format: "%02d", h)).tag(h)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 58)

                            Text(":")
                                .fontWeight(.bold)

                            Picker("", selection: $settings.startMinute) {
                                ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { m in
                                    Text(String(format: "%02d", m)).tag(m)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 58)
                        }
                    }
                    .disabled(settings.is24HourMode)
                    .opacity(settings.is24HourMode ? 0.45 : 1.0)

                    LabeledContent(L10n.tr(.workEndTime, lang: settings.language)) {
                        HStack(spacing: 6) {
                            Picker("", selection: $settings.endHour) {
                                ForEach(0..<24, id: \.self) { h in
                                    Text(String(format: "%02d", h)).tag(h)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 58)

                            Text(":")
                                .fontWeight(.bold)

                            Picker("", selection: $settings.endMinute) {
                                ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { m in
                                    Text(String(format: "%02d", m)).tag(m)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 58)
                        }
                    }
                    .disabled(settings.is24HourMode)
                    .opacity(settings.is24HourMode ? 0.45 : 1.0)
                }

                Divider().opacity(0.4).padding(.vertical, 4)

                // 2. 활성 캘린더 선택 및 색상 지정
                Section(header: Text(L10n.tr(.visibleCalendarsSection, lang: settings.language)).fontWeight(.semibold)) {
                    if !calendarService.isAuthorized() {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.tr(.permissionNeeded, lang: settings.language))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            HStack {
                                Button(L10n.tr(.requestPermission, lang: settings.language)) {
                                    calendarService.requestAccess()
                                }
                                .buttonStyle(.borderedProminent)

                                Button(L10n.tr(.openSystemPrivacy, lang: settings.language)) {
                                    CalendarService.openPrivacySettings()
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } else if calendarService.sourceGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L10n.tr(.noCalendars, lang: settings.language))
                                .foregroundStyle(.secondary)
                            Button(L10n.tr(.manageAccountsButton, lang: settings.language)) {
                                openInternetAccounts()
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                ForEach(calendarService.sourceGroups) { group in
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(group.title)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.top, 4)

                                        ForEach(group.calendars) { cal in
                                            CalendarRowView(cal: cal, settings: settings)
                                                .padding(.horizontal, 8)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .frame(height: 275)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )

                        HStack(spacing: 12) {
                            Button(action: openInternetAccounts) {
                                Label(L10n.tr(.manageAccountsButton, lang: settings.language), systemImage: "person.crop.circle.badge.plus")
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)

                            Spacer()

                            Button(action: openCalendarApp) {
                                Label(L10n.tr(.openCalendarApp, lang: settings.language), systemImage: "calendar")
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)

                            Spacer()

                            Button(action: {
                                calendarService.loadCalendars()
                                calendarService.fetchEvents(settings: settings)
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
            }
            .formStyle(.columns)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func openInternetAccounts() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Internet-Accounts-Settings.extension") {
            NSWorkspace.shared.open(url)
        } else if let legacyUrl = URL(string: "x-apple.systempreferences:com.apple.preference.internetaccounts") {
            NSWorkspace.shared.open(legacyUrl)
        }
    }

    private func openCalendarApp() {
        CalendarAppLauncher.open(event: nil)
    }
}

// MARK: - 개별 캘린더 항목 행 뷰
private struct CalendarRowView: View {
    let cal: CalendarInfo
    @ObservedObject var settings: AppSettings

    var body: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: Binding(
                get: { settings.isCalendarVisible(id: cal.id) },
                set: { settings.setCalendarVisible(id: cal.id, visible: $0) }
            ))
            .labelsHidden()

            Circle()
                .fill(settings.customColor(for: cal.id) ?? cal.defaultColor)
                .frame(width: 10, height: 10)

            Text(cal.title)
                .font(.body)

            Spacer()

            ColorPicker("", selection: Binding(
                get: { settings.customColor(for: cal.id) ?? cal.defaultColor },
                set: { settings.setCustomColor(for: cal.id, color: $0) }
            ), supportsOpacity: false)
            .labelsHidden()

            if settings.customColor(for: cal.id) != nil {
                Button(L10n.tr(.resetDefault, lang: settings.language)) {
                    settings.setCustomColor(for: cal.id, color: nil)
                }
                .font(.caption2)
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// 환경설정 4대 탭(타임라인, 외형, 일정, 일반) 모달 창 뷰
import SwiftUI
import EventKit
import AppKit

public struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var calendarService: CalendarService
    @ObservedObject var petService: CustomPetService = .shared

    @State private var selectedTab = 0

    public init(settings: AppSettings = .shared, calendarService: CalendarService = .shared) {
        self.settings = settings
        self.calendarService = calendarService
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 상단 탭 툴바
            HStack(spacing: 16) {
                TabToolbarButton(
                    title: L10n.tr(.tabTimeline, lang: settings.language),
                    icon: "guidepoint.vertical.arrowtriangle.forward",
                    isSelected: selectedTab == 0
                ) {
                    selectedTab = 0
                }

                TabToolbarButton(
                    title: L10n.tr(.tabAppearance, lang: settings.language),
                    icon: "calendar.day.timeline.leading",
                    isSelected: selectedTab == 1
                ) {
                    selectedTab = 1
                }

                TabToolbarButton(
                    title: L10n.tr(.tabSchedule, lang: settings.language),
                    icon: "calendar.badge.clock",
                    isSelected: selectedTab == 2
                ) {
                    selectedTab = 2
                }

                TabToolbarButton(
                    title: L10n.tr(.tabGeneral, lang: settings.language),
                    icon: "gear",
                    isSelected: selectedTab == 3
                ) {
                    selectedTab = 3
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity)

            Divider()

            // 2. Content Area (파인더 방식: 콘텐츠는 즉시 교체하고, 윈도우 프레임만 애니메이션)
            Group {
                switch selectedTab {
                case 0:
                    TimelineTab(settings: settings)
                case 1:
                    AppearanceTab(settings: settings)
                case 2:
                    ScheduleTab(settings: settings, calendarService: calendarService)
                case 3:
                    GeneralTab(settings: settings)
                default:
                    EmptyView()
                }
            }
            .frame(width: 470, alignment: .top)
            .padding(.vertical, 10)
        }
        .frame(width: 480)
        .onAppear {
            resizeWindow()
        }
        .onChange(of: selectedTab) { _, _ in
            resizeWindow()
        }
        .onChange(of: petService.customPets.count) { _, _ in
            resizeWindow()
        }
    }

    // 탭 전환 시 실제 콘텐츠 ideal size(NSHostingView fittingSize)에 맞춰 NSWindow 프레임을 부드럽게 동기화
    private func resizeWindow() {
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first(where: { $0.title == "NudgeLine" && $0.isVisible }),
                  let contentView = window.contentView else { return }

            let idealSize = contentView.fittingSize
            guard idealSize.height > 0 else { return }

            let targetContentSize = NSSize(width: 480, height: idealSize.height)
            let newWindowFrame = window.frameRect(forContentRect: NSRect(origin: window.frame.origin, size: targetContentSize))
            let adjustedOrigin = NSPoint(x: window.frame.minX, y: window.frame.maxY - newWindowFrame.height)
            let finalFrame = NSRect(origin: adjustedOrigin, size: newWindowFrame.size)

            if abs(window.frame.height - finalFrame.height) > 1 {
                window.setFrame(finalFrame, display: true, animate: true)
            }
        }
    }
}

// MARK: - Finder Style Toolbar Button
private struct TabToolbarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .frame(height: 24)
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary.opacity(0.75))
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}


// MARK: - 탭 1: 타임라인 설정 (위치, 두께, 호버 확장, 배경)
private struct TimelineTab: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                // 1. 화면 배치 및 크기
                Section(header: Text(L10n.tr(.barPositionAndThicknessSection, lang: settings.language)).fontWeight(.semibold)) {
                    Picker(selection: $settings.barPosition) {
                        Text(L10n.tr(.positionLeft, lang: settings.language)).tag(BarPosition.left)
                        Text(L10n.tr(.positionRight, lang: settings.language)).tag(BarPosition.right)
                        Text(L10n.tr(.positionBottom, lang: settings.language)).tag(BarPosition.bottom)
                    } label: {
                        Text(L10n.tr(.barPositionLabel, lang: settings.language))
                            .frame(minWidth: 95, alignment: .trailing)
                    }
                    .pickerStyle(.segmented)

                    LabeledContent {
                        HStack(spacing: 8) {
                            Slider(
                                value: $settings.barWidth,
                                in: 1...10,
                                step: 1
                            )
                            Text("\(Int(settings.barWidth))px")
                                .frame(width: 38, alignment: .trailing)
                        }
                    } label: {
                        Text(L10n.tr(.defaultThickness, lang: settings.language))
                            .frame(minWidth: 95, alignment: .trailing)
                    }
                }

                Divider().opacity(0.4).padding(.vertical, 4)

                // 2. 마우스 호버 효과
                Section(header: Text(L10n.tr(.barHoverEffectsSection, lang: settings.language)).fontWeight(.semibold)) {
                    Toggle(L10n.tr(.expandOnHover, lang: settings.language), isOn: $settings.expandOnHover)

                    LabeledContent {
                        HStack(spacing: 8) {
                            Slider(
                                value: Binding(
                                    get: { max(settings.barWidth, settings.hoverWidth) },
                                    set: { settings.hoverWidth = max(settings.barWidth, $0) }
                                ),
                                in: 1...10,
                                step: 1
                            )
                            Text("\(Int(max(settings.barWidth, settings.hoverWidth)))px")
                                .frame(width: 38, alignment: .trailing)
                        }
                    } label: {
                        Text(L10n.tr(.hoverThickness, lang: settings.language))
                            .frame(minWidth: 95, alignment: .trailing)
                    }
                    .disabled(!settings.expandOnHover)

                    Toggle(L10n.tr(.enableSegmentRimLabel, lang: settings.language), isOn: $settings.enableSegmentRim)
                    Toggle(L10n.tr(.enableSegmentGlowLabel, lang: settings.language), isOn: $settings.enableSegmentGlow)
                }

                Divider().opacity(0.4).padding(.vertical, 4)

                // 3. 타임라인 배경
                Section(header: Text(L10n.tr(.barBackgroundSection, lang: settings.language)).fontWeight(.semibold)) {
                    Picker(selection: $settings.barStyleMode) {
                        ForEach(BarStyleMode.allCases, id: \.self) { mode in
                            Text(mode.title(lang: settings.language)).tag(mode)
                        }
                    } label: {
                        Text(L10n.tr(.backgroundStyle, lang: settings.language))
                            .frame(minWidth: 95, alignment: .trailing)
                    }

                    if settings.barStyleMode == .custom {
                        LabeledContent {
                            ColorPicker("", selection: Binding(
                                get: { Color(hex: settings.trackColorHex) ?? Color.gray },
                                set: { if let hex = $0.toHex() { settings.trackColorHex = hex } }
                            ), supportsOpacity: false)
                            .labelsHidden()
                        } label: {
                            Text(L10n.tr(.backgroundColor, lang: settings.language))
                                .frame(minWidth: 95, alignment: .trailing)
                        }
                    }

                    LabeledContent {
                        HStack(spacing: 8) {
                            Slider(value: $settings.trackOpacity, in: 0.0...1.0)
                            Text("\(Int(settings.trackOpacity * 100))%")
                                .frame(width: 38, alignment: .trailing)
                        }
                    } label: {
                        Text(L10n.tr(.backgroundOpacity, lang: settings.language))
                            .frame(minWidth: 95, alignment: .trailing)
                    }
                }
            }
            .formStyle(.columns)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

        }
    }
}
// MARK: - 탭 2: 외형 설정 (팝오버 테마, 인디케이터 스타일, 펫 마스코트)
private struct AppearanceTab: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject private var petService = CustomPetService.shared
    @State private var isShowingCustomPetEditor: Bool = false

    private var petSelectionBinding: Binding<String> {
        Binding<String>(
            get: {
                if settings.selectedPetType == .custom {
                    return "custom_\(settings.selectedCustomPetId ?? "")"
                }
                return settings.selectedPetType.rawValue
            },
            set: { newValue in
                if newValue.hasPrefix("custom_") {
                    settings.selectedPetType = .custom
                    settings.selectedCustomPetId = String(newValue.dropFirst(7))
                } else {
                    settings.selectedPetType = HangingPetType(rawValue: newValue) ?? .cat
                    settings.selectedCustomPetId = ""
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                // 1. Event Card Style (일정 카드)
                Section(header: Text(L10n.tr(.hoverCardStyleSection, lang: settings.language)).fontWeight(.semibold)) {
                    Picker(selection: $settings.eventHoverStyle) {
                        ForEach(EventHoverStyle.allCases, id: \.self) { style in
                            Text(style.title(lang: settings.language)).tag(style)
                        }
                    } label: {
                        Text(L10n.tr(.cardStyleLabel, lang: settings.language))
                            .frame(minWidth: 135, alignment: .trailing)
                    }

                    Picker(selection: $settings.eventCardTheme) {
                        ForEach(EventCardTheme.allCases, id: \.self) { theme in
                            Text(theme.title(lang: settings.language)).tag(theme)
                        }
                    } label: {
                        Text(L10n.tr(.cardThemeLabel, lang: settings.language))
                            .frame(minWidth: 135, alignment: .trailing)
                    }

                    LabeledContent {
                        HStack(spacing: 8) {
                            Slider(value: $settings.cardOpacity, in: 0.2...1.0)
                            Text("\(Int(settings.cardOpacity * 100))%")
                                .frame(width: 38, alignment: .trailing)
                        }
                    } label: {
                        Text(L10n.tr(.cardOpacityLabel, lang: settings.language))
                            .frame(minWidth: 135, alignment: .trailing)
                    }
                }

                Divider().opacity(0.4).padding(.vertical, 4)

                // 2. Time Indicator Style (시간 표시자)
                Section(header: Text(L10n.tr(.timeIndicatorSection, lang: settings.language)).fontWeight(.semibold)) {
                    Picker(selection: $settings.currentTimeIndicatorStyle) {
                        ForEach(CurrentTimeIndicatorStyle.allCases, id: \.self) { style in
                            Text(style.title(lang: settings.language)).tag(style)
                        }
                    } label: {
                        Text(L10n.tr(.indicatorStyleLabel, lang: settings.language))
                            .frame(minWidth: 135, alignment: .trailing)
                    }

                    LabeledContent {
                        HStack {
                            ColorPicker("", selection: Binding(
                                get: { Color(hex: settings.currentTimeColorHex) ?? Color.red },
                                set: { if let hex = $0.toHex() { settings.currentTimeColorHex = hex } }
                            ), supportsOpacity: false)
                            .labelsHidden()
                            Spacer()
                        }
                    } label: {
                        Text(L10n.tr(.indicatorColorLabel, lang: settings.language))
                            .frame(minWidth: 135, alignment: .trailing)
                    }

                    Toggle(L10n.tr(.indicatorRimLabel, lang: settings.language), isOn: $settings.enableIndicatorRim)
                    Toggle(L10n.tr(.indicatorGlowLabel, lang: settings.language), isOn: $settings.enableIndicatorGlow)
                }

                Divider().opacity(0.4).padding(.vertical, 4)

                // 3. Hanging Pet Companion (대롱대롱 펫)
                Section(header: Text(L10n.tr(.petCompanionSection, lang: settings.language)).fontWeight(.semibold)) {
                    Toggle(isOn: $settings.isPetEnabled) {
                        Text(L10n.tr(.showPetCompanionLabel, lang: settings.language))
                            .frame(minWidth: 135, alignment: .trailing)
                    }
                    .toggleStyle(.switch)
                    .disabled(settings.barPosition == .bottom)

                    if settings.barPosition == .bottom {
                        Text(L10n.tr(.petNotSupportedOnBottom, lang: settings.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Picker(selection: petSelectionBinding) {
                        ForEach(HangingPetType.allCases.filter { $0 != .custom }, id: \.self) { pet in
                            Text(pet.title(lang: settings.language)).tag(pet.rawValue)
                        }
                        if !petService.customPets.isEmpty {
                            Divider()
                            ForEach(petService.customPets) { pet in
                                Text(pet.name).tag("custom_\(pet.id)")
                            }
                        }
                    } label: {
                        Text(L10n.tr(.petCharacterLabel, lang: settings.language))
                            .frame(minWidth: 135, alignment: .trailing)
                    }
                    .disabled(!settings.isPetEnabled || settings.barPosition == .bottom)

                    Picker(selection: $settings.petHideStyle) {
                        ForEach(PetHideStyle.allCases, id: \.self) { style in
                            Text(style.title(lang: settings.language)).tag(style)
                        }
                    } label: {
                        Text(L10n.tr(.petHideMotionLabel, lang: settings.language))
                            .frame(minWidth: 135, alignment: .trailing)
                    }
                    .disabled(!settings.isPetEnabled || settings.barPosition == .bottom)

                    // Custom Pet Management & List
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(L10n.tr(.customPetSection, lang: settings.language))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Button(L10n.tr(.addCustomPet, lang: settings.language)) {
                                isShowingCustomPetEditor = true
                            }
                            .font(.caption)
                        }

                        if petService.customPets.isEmpty {
                            Text(L10n.tr(.noCustomPets, lang: settings.language))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ScrollView(.horizontal, showsIndicators: true) {
                                HStack(spacing: 10) {
                                    ForEach(petService.customPets) { pet in
                                        CustomPetThumbItem(
                                            pet: pet,
                                            isSelected: settings.selectedPetType == .custom && (settings.selectedCustomPetId ?? "") == pet.id,
                                            onSelect: {
                                                settings.isPetEnabled = true
                                                settings.selectedPetType = .custom
                                                settings.selectedCustomPetId = pet.id
                                            },
                                            onDelete: {
                                                petService.deletePet(id: pet.id)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 2)
                                .padding(.top, 4)
                                .padding(.bottom, 6)
                            }
                            .frame(width: 275)
                            .scrollIndicators(.visible)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .formStyle(.columns)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .sheet(isPresented: $isShowingCustomPetEditor) {
                CustomPetEditorSheet(settings: settings)
            }

        }
    }
}
// MARK: - 탭 3: 일정 및 캘린더 설정 (근무 시간, 활성 캘린더 목록, 개별 색상)
private struct ScheduleTab: View {
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
                                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                                        NSWorkspace.shared.open(url)
                                    }
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

// MARK: - 탭 4: 일반 설정 (언어, 로그인 시 자동 실행, 모든 화면 표시, 앱 정보)
private struct GeneralTab: View {
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
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
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
                    Picker(L10n.tr(.languageLabel, lang: settings.language), selection: $settings.language) {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            Text(lang.title).tag(lang)
                        }
                    }

                    Toggle(L10n.tr(.launchAtLogin, lang: settings.language), isOn: Binding(
                        get: { launchHelper.isEnabled },
                        set: { launchHelper.setEnabled($0) }
                    ))

                    Toggle(L10n.tr(.showOnAllScreens, lang: settings.language), isOn: $settings.showOnAllScreens)
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
// MARK: - 커스텀 펫 미니 썸네일 뷰
private struct MiniPetThumbView: View {
    let petId: String
    let fps: Double
    @ObservedObject private var petService = CustomPetService.shared

    var body: some View {
        let frames = petService.getFrames(for: petId)
        if frames.isEmpty {
            Image(systemName: "photo")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        } else {
            TimelineView(.periodic(from: .now, by: 1.0 / max(1.0, fps))) { context in
                let count = max(1, frames.count)
                let index = Int(context.date.timeIntervalSince1970 * fps) % count
                if let image = frames[safe: index] {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .padding(2)
                }
            }
        }
    }
}

// MARK: - 커스텀 펫 썸네일 카드 항목
private struct CustomPetThumbItem: View {
    let pet: CustomPet
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 3) {
            ZStack(alignment: .topTrailing) {
                MiniPetThumbView(petId: pet.id, fps: pet.fps)
                    .frame(width: 32, height: 32)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )

                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                        .background(Circle().fill(Color.white).frame(width: 10, height: 10))
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: -4)
            }

            Text(pet.name)
                .font(.system(size: 10))
                .lineLimit(1)
                .frame(width: 44)
        }
        .onTapGesture(perform: onSelect)
    }
}

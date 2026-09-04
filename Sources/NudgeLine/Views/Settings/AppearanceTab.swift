// 환경설정 탭 2: 외형 설정 (팝오버 테마, 인디케이터 스타일, 펫 마스코트)
import SwiftUI

struct AppearanceTab: View {
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
                    settings.selectedPetType = HangingPetType(rawValue: newValue) ?? .whiteTiger
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
                    LabeledContent {
                        HStack {
                            Picker("", selection: $settings.eventHoverStyle) {
                                ForEach(EventHoverStyle.allCases, id: \.self) { style in
                                    Text(style.title(lang: settings.language)).tag(style)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .fixedSize()
                            Spacer()
                        }
                    } label: {
                        Text(L10n.tr(.cardStyleLabel, lang: settings.language))
                            .frame(minWidth: 135, alignment: .trailing)
                    }

                    LabeledContent {
                        HStack {
                            Picker("", selection: $settings.eventCardTheme) {
                                ForEach(EventCardTheme.allCases, id: \.self) { theme in
                                    Text(theme.title(lang: settings.language)).tag(theme)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .fixedSize()
                            Spacer()
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
                    LabeledContent {
                        HStack {
                            Picker("", selection: $settings.currentTimeIndicatorStyle) {
                                ForEach(CurrentTimeIndicatorStyle.allCases, id: \.self) { style in
                                    Text(style.title(lang: settings.language)).tag(style)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .fixedSize()
                            Spacer()
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

                // 3. Event Alert Effects (일정 알림 효과)
                Section(header: Text(L10n.tr(.eventTriggerEffectSection, lang: settings.language)).fontWeight(.semibold)) {
                    // 3-1. 일정 시작 전 알림 (은은한 바 펄스 넛지)
                    LabeledContent {
                        HStack(spacing: 8) {
                            Toggle("", isOn: $settings.enablePreEventAlert)
                                .labelsHidden()
                                .toggleStyle(.switch)

                            Picker("", selection: $settings.preEventAlertMinutes) {
                                Text(L10n.tr(.minutesPrior(5), lang: settings.language)).tag(5)
                                Text(L10n.tr(.minutesPrior(10), lang: settings.language)).tag(10)
                                Text(L10n.tr(.minutesPrior(15), lang: settings.language)).tag(15)
                                Text(L10n.tr(.minutesPrior(20), lang: settings.language)).tag(20)
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .fixedSize()
                            .disabled(!settings.enablePreEventAlert)

                            Button(L10n.tr(.previewLabel, lang: settings.language)) {
                                NotificationCenter.default.post(name: .previewPreEventAlert, object: nil)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(!settings.enablePreEventAlert)

                            Spacer()
                        }
                    } label: {
                        Text(L10n.tr(.preEventAlertLabel, lang: settings.language))
                            .frame(minWidth: 135, alignment: .trailing)
                    }

                    // 3-2. 일정 시작 효과 (16프레임 사계절 방전 및 정각 알림)
                    LabeledContent {
                        HStack(spacing: 8) {
                            Toggle("", isOn: $settings.enableEventTriggerEffect)
                                .labelsHidden()
                                .toggleStyle(.switch)

                            Picker("", selection: $settings.eventTriggerEffectType) {
                                ForEach(EventTriggerEffectType.allCases, id: \.self) { effect in
                                    Text(effect.title(lang: settings.language)).tag(effect)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .fixedSize()
                            .disabled(!settings.enableEventTriggerEffect)

                            Button(L10n.tr(.previewLabel, lang: settings.language)) {
                                NotificationCenter.default.post(name: .previewEventContactEffect, object: nil)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(!settings.enableEventTriggerEffect)

                            Spacer()
                        }
                    } label: {
                        Text(L10n.tr(.eventContactEffectLabel, lang: settings.language))
                            .frame(minWidth: 135, alignment: .trailing)
                    }

                    LabeledContent {
                        HStack {
                            Toggle(L10n.tr(.hourlyAlertLabel, lang: settings.language), isOn: $settings.enableHourlyAlertEffect)
                                .toggleStyle(.checkbox)
                            Spacer()
                        }
                    } label: {
                        Text("")
                            .frame(minWidth: 135, alignment: .trailing)
                    }
                    .disabled(!settings.enableEventTriggerEffect)
                }

                Divider().opacity(0.4).padding(.vertical, 4)

                // 4. Hanging Pet Companion (대롱대롱 펫)
                Section(header: Text(L10n.tr(.petCompanionSection, lang: settings.language)).fontWeight(.semibold)) {
                    Toggle(isOn: $settings.isPetEnabled) {
                        Text(L10n.tr(.showPetCompanionLabel, lang: settings.language))
                            .frame(minWidth: 135, alignment: .trailing)
                    }
                    .toggleStyle(.switch)

                    LabeledContent {
                        HStack {
                            Picker("", selection: petSelectionBinding) {
                                ForEach(HangingPetType.allCases.filter { $0 != .custom }, id: \.self) { pet in
                                    Text(pet.title(lang: settings.language)).tag(pet.rawValue)
                                }
                                if !petService.customPets.isEmpty {
                                    Divider()
                                    ForEach(petService.customPets) { pet in
                                        Text(pet.name).tag("custom_\(pet.id)")
                                    }
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .fixedSize()
                            Spacer()
                        }
                    } label: {
                        Text(L10n.tr(.petCharacterLabel, lang: settings.language))
                            .frame(minWidth: 135, alignment: .trailing)
                    }
                    .disabled(!settings.isPetEnabled)

                    LabeledContent {
                        HStack {
                            Picker("", selection: $settings.petHideStyle) {
                                ForEach(PetHideStyle.allCases, id: \.self) { style in
                                    Text(style.title(lang: settings.language)).tag(style)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .fixedSize()
                            Spacer()
                        }
                    } label: {
                        Text(L10n.tr(.petHideMotionLabel, lang: settings.language))
                            .frame(minWidth: 135, alignment: .trailing)
                    }
                    .disabled(!settings.isPetEnabled)

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
            // 시스템 ProMotion/60Hz 렌더링 주기 동기화 및 뷰 비가시화 시 자동 절전 지원
            TimelineView(.animation(minimumInterval: 1.0 / max(1.0, fps))) { context in
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

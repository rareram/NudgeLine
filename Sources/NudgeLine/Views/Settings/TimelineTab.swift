// 환경설정 탭 1: 타임라인 설정 (위치, 두께, 호버 확장, 배경)
import SwiftUI

struct TimelineTab: View {
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

                    // 2단 체크박스 그리드
                    HStack(alignment: .top, spacing: 32) {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(L10n.tr(.enableSegmentRimLabel, lang: settings.language), isOn: $settings.enableSegmentRim)
                                .toggleStyle(.checkbox)
                            Toggle(L10n.tr(.enableSegmentGlowLabel, lang: settings.language), isOn: $settings.enableSegmentGlow)
                                .toggleStyle(.checkbox)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(L10n.tr(.dimPastEventsLabel, lang: settings.language), isOn: $settings.dimPastEvents)
                                .toggleStyle(.checkbox)
                        }
                        Spacer()
                    }
                    .padding(.top, 4)
                }

                Divider().opacity(0.4).padding(.vertical, 4)

                // 3. 타임라인 배경
                Section(header: Text(L10n.tr(.barBackgroundSection, lang: settings.language)).fontWeight(.semibold)) {
                    LabeledContent {
                        HStack {
                            Picker("", selection: $settings.barStyleMode) {
                                ForEach(BarStyleMode.allCases, id: \.self) { mode in
                                    Text(mode.title(lang: settings.language)).tag(mode)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .fixedSize()
                            Spacer()
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

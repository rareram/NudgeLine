// 사용자 정의 펫 생성/편집 모달 시트 뷰
import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - 1. 커스텀 펫 편집기 모달 본체 (CustomPetEditorSheet)
public struct CustomPetEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var petService = CustomPetService.shared
    @ObservedObject var settings: AppSettings

    @State private var petName: String = ""
    @State private var frames: [NSImage] = []
    @State private var fps: Double = 8.0
    @State private var leftHideOffset: Double = -23.0
    @State private var rightHideOffset: Double = 6.0
    @State private var selectedFrameIndex: Int? = nil
    @State private var isDropTargeted: Bool = false

    public init(settings: AppSettings) {
        self.settings = settings
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Text(L10n.tr(.customPetEditorTitle, lang: settings.language))
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)

            Divider()

            // 메인 폼
            VStack(alignment: .leading, spacing: 12) {
                // 1. 펫 이름 입력
                petNameSection

                Divider()

                // 2. 프레임 이미지 관리 (드래그앤드롭 + 툴바)
                framesManagementSection

                Divider()

                // 3. 실시간 애니메이션 미리보기 및 재생 속도 조절
                previewAndSpeedSection

                Divider()

                // 4. 숨김 오프셋 미세조절 (좌/우 실시간 힌지 프리뷰)
                hideOffsetsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Spacer(minLength: 0)

            Divider()

            // 하단 액션 버튼 (취소 / 추가)
            footerActions
        }
        .frame(width: 450, height: 537)
    }
}

// MARK: - 2. 폼 서브뷰 컴포넌트
extension CustomPetEditorSheet {
    private var petNameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.tr(.petNameLabel, lang: settings.language))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            TextField(L10n.tr(.petNamePlaceholder, lang: settings.language), text: $petName)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var framesManagementSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(L10n.tr(.framesLabel, lang: settings.language))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(frames.count) Frames")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr(.framesGuide, lang: settings.language))
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(width: 140, alignment: .leading)

                VStack(spacing: 0) {
                    ZStack {
                        if frames.isEmpty {
                            VStack(spacing: 6) {
                                Image(systemName: "plus.viewfinder")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.secondary)
                                Text(L10n.tr(.dragDropGuide, lang: settings.language))
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(8)
                        } else {
                            ScrollView(.horizontal, showsIndicators: true) {
                                LazyHStack(spacing: 8) {
                                    ForEach(Array(frames.enumerated()), id: \.offset) { index, frame in
                                        ZStack(alignment: .topTrailing) {
                                            Image(nsImage: frame)
                                                .resizable()
                                                .interpolation(.high)
                                                .scaledToFit()
                                                .frame(width: 44, height: 60)
                                                .padding(4)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(selectedFrameIndex == index ? Color.accentColor.opacity(0.2) : Color.clear)
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(selectedFrameIndex == index ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
                                                )
                                                .onTapGesture {
                                                    selectedFrameIndex = index
                                                }

                                            Text("\(index + 1)")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(.secondary)
                                                .padding(2)
                                        }
                                    }
                                }
                                .padding(8)
                            }
                        }
                    }
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isDropTargeted ? Color.accentColor.opacity(0.1) : Color(NSColor.textBackgroundColor).opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.25), lineWidth: 1)
                    )
                    .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                        handleDrop(providers: providers)
                    }

                    // 하단 툴바
                    HStack(spacing: 0) {
                        Button(action: openFileDialog) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                                .frame(width: 28, height: 22)
                        }
                        .buttonStyle(.plain)

                        Divider().frame(height: 14)

                        Button(action: deleteSelectedOrLastFrame) {
                            Image(systemName: "minus")
                                .font(.system(size: 11, weight: .bold))
                                .frame(width: 28, height: 22)
                        }
                        .buttonStyle(.plain)
                        .disabled(frames.isEmpty)

                        Spacer()
                    }
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
                    .overlay(Rectangle().stroke(Color.secondary.opacity(0.2), lineWidth: 0.5))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var previewAndSpeedSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.tr(.previewLabel, lang: settings.language))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 14) {
                LivePetPreviewBox(frames: frames, fps: fps)
                    .frame(width: 80, height: 72)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(L10n.tr(.speedLabel, lang: settings.language)): \(String(format: "%.1f", fps)) FPS")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    Slider(value: $fps, in: 2...20, step: 0.5)

                    HStack {
                        Text(L10n.tr(.speedSlow, lang: settings.language))
                            .font(.system(size: 9.5))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(L10n.tr(.speedFast, lang: settings.language))
                            .font(.system(size: 9.5))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 2)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var hideOffsetsSection: some View {
        HStack(spacing: 16) {
            // 좌측 숨김 (Tail Peek)
            HStack(spacing: 10) {
                LivePetHidePreviewBox(frames: frames, rotation: -85.0, offset: leftHideOffset)
                    .frame(width: 80, height: 72)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr(.leftHideOffsetLabel, lang: settings.language))
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 0) {
                        Button {
                            leftHideOffset = max(-50.0, leftHideOffset - 1.0)
                        } label: {
                            Image(systemName: "arrowtriangle.backward.fill")
                                .font(.system(size: 8))
                                .frame(width: 22, height: 20)
                        }
                        .buttonStyle(.plain)

                        Divider().frame(height: 12)

                        Text("\(Int(leftHideOffset))px")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .frame(width: 44, height: 20)

                        Divider().frame(height: 12)

                        Button {
                            leftHideOffset = min(20.0, leftHideOffset + 1.0)
                        } label: {
                            Image(systemName: "arrowtriangle.forward.fill")
                                .font(.system(size: 8))
                                .frame(width: 22, height: 20)
                        }
                        .buttonStyle(.plain)
                    }
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 우측 숨김 (Head Peek)
            HStack(spacing: 10) {
                LivePetHidePreviewBox(frames: frames, rotation: 85.0, offset: rightHideOffset)
                    .frame(width: 80, height: 72)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr(.rightHideOffsetLabel, lang: settings.language))
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 0) {
                        Button {
                            rightHideOffset = max(-20.0, rightHideOffset - 1.0)
                        } label: {
                            Image(systemName: "arrowtriangle.backward.fill")
                                .font(.system(size: 8))
                                .frame(width: 22, height: 20)
                        }
                        .buttonStyle(.plain)

                        Divider().frame(height: 12)

                        Text("\(Int(rightHideOffset))px")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .frame(width: 44, height: 20)

                        Divider().frame(height: 12)

                        Button {
                            rightHideOffset = min(50.0, rightHideOffset + 1.0)
                        } label: {
                            Image(systemName: "arrowtriangle.forward.fill")
                                .font(.system(size: 8))
                                .frame(width: 22, height: 20)
                        }
                        .buttonStyle(.plain)
                    }
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var footerActions: some View {
        HStack(spacing: 12) {
            Spacer()

            Button(L10n.tr(.cancelButton, lang: settings.language)) {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Button(L10n.tr(.addButton, lang: settings.language)) {
                saveCustomPet()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(petName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || frames.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - 3. 파일 선택 및 드롭 I/O 핸들러
extension CustomPetEditorSheet {
    private func openFileDialog() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png]

        if panel.runModal() == .OK {
            let sortedURLs = panel.urls.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            for url in sortedURLs {
                if let img = NSImage(contentsOf: url) {
                    frames.append(img)
                }
            }
        }
    }

    private func deleteSelectedOrLastFrame() {
        if let idx = selectedFrameIndex, idx < frames.count {
            frames.remove(at: idx)
            selectedFrameIndex = nil
        } else if !frames.isEmpty {
            frames.removeLast()
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        let group = DispatchGroup()
        let lock = NSLock()
        var collectedURLs: [URL] = []

        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil),
                   url.pathExtension.lowercased() == "png" {
                    lock.lock()
                    collectedURLs.append(url)
                    lock.unlock()
                }
            }
        }

        group.notify(queue: .main) {
            let sortedURLs = collectedURLs.sorted {
                $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
            }
            let loadedImages = sortedURLs.compactMap { NSImage(contentsOf: $0) }
            self.frames.append(contentsOf: loadedImages)
        }
        return true
    }

    private func saveCustomPet() {
        let name = petName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !frames.isEmpty else { return }

        if let saved = petService.savePet(
            name: name,
            fps: fps,
            images: frames,
            leftHideOffset: leftHideOffset,
            rightHideOffset: rightHideOffset
        ) {
            settings.selectedCustomPetId = saved.id
            settings.selectedPetType = .custom
        }
        dismiss()
    }
}

// MARK: - 4. 커스텀 펫 실시간 애니메이션 미리보기 뷰 (100% Retina 크기: 40x58pt)
private struct LivePetPreviewBox: View {
    let frames: [NSImage]
    let fps: Double

    var body: some View {
        ZStack {
            if frames.isEmpty {
                Text("No Frame")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary.opacity(0.5))
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
                            .frame(width: 40, height: 58)
                    }
                }
            }
        }
    }
}

// MARK: - 5. 커스텀 펫 실시간 숨김 모션 프리뷰 박스 (100% Retina 크기, 가로/세로 정중앙 정렬)
private struct LivePetHidePreviewBox: View {
    private static let offScreenBlurRadius: CGFloat = 1.2
    private static let offScreenOpacity: Double = 0.65
    private static let offScreenBgDimOpacity: Double = 0.15

    let frames: [NSImage]
    let rotation: Double
    let offset: Double

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if frames.isEmpty {
                    Text("No Frame")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary.opacity(0.5))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let image = frames.first {
                    // 가상의 바 에지 가이드라인 (박스 가로/세로 정중앙: wallX = 40pt, centerY = 36pt)
                    let wallX = geo.size.width / 2.0
                    let centerY = geo.size.height / 2.0

                    ZStack(alignment: .topLeading) {
                        // 1. 화면 바깥쪽(좌측) 어두운 배경 딤
                        Rectangle()
                            .fill(Color.black.opacity(Self.offScreenBgDimOpacity))
                            .frame(width: wallX, height: geo.size.height)
                            .position(x: wallX / 2.0, y: centerY)

                        // 2. 화면 바깥으로 넘어간 펫 (은은하고 섬세한 소프트 블러 + 아웃포커싱 음영)
                        petImageView(image: image, wallX: wallX, centerY: centerY)
                            .blur(radius: Self.offScreenBlurRadius)
                            .opacity(Self.offScreenOpacity)
                            .mask(
                                Rectangle()
                                    .frame(width: wallX, height: geo.size.height)
                                    .position(x: wallX / 2.0, y: centerY)
                            )

                        // 3. 화면 안쪽 펫 (100% 선명한 원본)
                        petImageView(image: image, wallX: wallX, centerY: centerY)
                            .mask(
                                Rectangle()
                                    .frame(width: wallX, height: geo.size.height)
                                    .position(x: wallX + wallX / 2.0, y: centerY)
                            )

                        // 4. 세로 화면 경계 가이드라인 (파란색 에지 라인)
                        Rectangle()
                            .fill(Color.accentColor.opacity(0.9))
                            .frame(width: 2, height: geo.size.height)
                            .position(x: wallX, y: centerY)
                    }
                    .clipped()
                }
            }
        }
    }

    @ViewBuilder
    private func petImageView(image: NSImage, wallX: CGFloat, centerY: CGFloat) -> some View {
        Image(nsImage: image)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: 40, height: 58)
            .rotationEffect(.degrees(rotation), anchor: UnitPoint(x: 0.0, y: 0.27))
            .position(x: wallX + 20.0 + CGFloat(offset), y: centerY + 13.34)
    }
}

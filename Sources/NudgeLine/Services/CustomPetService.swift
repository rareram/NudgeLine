// 사용자 정의 펫 모델, 디스크 파일 영속화 및 프레임 메모리 캐싱 서비스
import Foundation
import SwiftUI
import AppKit
import Combine

// 사용자 정의 펫 메타데이터 모델
public struct CustomPet: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var fps: Double
    public var frameCount: Int
    public var createdAt: Date
    public var leftHideOffset: Double
    public var rightHideOffset: Double

    public init(
        id: String = UUID().uuidString,
        name: String,
        fps: Double = 8.0,
        frameCount: Int,
        createdAt: Date = Date(),
        leftHideOffset: Double = -23.0,
        rightHideOffset: Double = 6.0
    ) {
        self.id = id
        self.name = name
        self.fps = fps
        self.frameCount = frameCount
        self.createdAt = createdAt
        self.leftHideOffset = leftHideOffset
        self.rightHideOffset = rightHideOffset
    }

    enum CodingKeys: String, CodingKey {
        case id, name, fps, frameCount, createdAt, leftHideOffset, rightHideOffset
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.fps = try container.decode(Double.self, forKey: .fps)
        self.frameCount = try container.decode(Int.self, forKey: .frameCount)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.leftHideOffset = try container.decodeIfPresent(Double.self, forKey: .leftHideOffset) ?? -23.0
        self.rightHideOffset = try container.decodeIfPresent(Double.self, forKey: .rightHideOffset) ?? 6.0
    }
}

public final class CustomPetService: ObservableObject {
    public static let shared = CustomPetService()

    @Published public private(set) var customPets: [CustomPet] = []
    private var imageCache: [String: [NSImage]] = [:]
    private let cacheLock = NSLock()

    private let fileManager = FileManager.default
    private var petsDirectoryURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let dir = appSupport.appendingPathComponent("NudgeLine").appendingPathComponent("CustomPets")
        let legacyDir = appSupport.appendingPathComponent("ScheduleBar2").appendingPathComponent("CustomPets")

        if !fileManager.fileExists(atPath: dir.path) {
            // 구버전 폴더 마이그레이션 및 신규 생성
            if fileManager.fileExists(atPath: legacyDir.path) {
                try? fileManager.moveItem(at: legacyDir, to: dir)
            } else {
                try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            }
        }
        return dir
    }

    private init() {
        loadAllPets()
    }

    // 디스크에 저장된 모든 커스텀 펫 메타데이터 및 이미지 프레임 프리로드
    public func loadAllPets() {
        let dir = petsDirectoryURL
        guard let petDirs = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return
        }

        var loaded: [CustomPet] = []
        for petDir in petDirs {
            let metaFile = petDir.appendingPathComponent("metadata.json")
            if let data = try? Data(contentsOf: metaFile),
               let pet = try? JSONDecoder().decode(CustomPet.self, from: data) {
                loaded.append(pet)
            }
        }

        self.customPets = loaded.sorted { $0.createdAt < $1.createdAt }

        // 렌더링 루프 디스크 I/O 방지를 위한 인메모리 캐싱
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            for pet in loaded {
                let isCached: Bool = self.cacheLock.withLock { self.imageCache[pet.id] != nil }
                if !isCached {
                    _ = self.getFrames(for: pet.id)
                }
            }
        }
    }

    // 특정 펫 ID의 PNG 프레임 이미지 목록 반환 (메모리 캐시 우선)
    public func getFrames(for petId: String) -> [NSImage] {
        guard UUID(uuidString: petId) != nil else { return [] }

        let cachedImages = cacheLock.withLock { imageCache[petId] }
        if let cached = cachedImages, !cached.isEmpty {
            return cached
        }

        let petDir = petsDirectoryURL.appendingPathComponent(petId)
        guard let files = try? fileManager.contentsOfDirectory(at: petDir, includingPropertiesForKeys: nil) else {
            return []
        }

        let pngFiles = files.filter { $0.pathExtension.lowercased() == "png" }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

        let images = pngFiles.compactMap { NSImage(contentsOf: $0) }
        cacheLock.withLock {
            imageCache[petId] = images
        }
        return images
    }

    // 신규 커스텀 펫 저장 (PNG 프레임 파일 및 metadata.json 생성)
    @discardableResult
    public func savePet(
        name: String,
        fps: Double,
        images: [NSImage],
        leftHideOffset: Double = -23.0,
        rightHideOffset: Double = 6.0
    ) -> CustomPet? {
        guard !images.isEmpty else { return nil }

        let petId = UUID().uuidString
        let petDir = petsDirectoryURL.appendingPathComponent(petId)
        try? fileManager.createDirectory(at: petDir, withIntermediateDirectories: true)

        // 프레임 이미지 저장
        for (index, img) in images.enumerated() {
            let frameURL = petDir.appendingPathComponent(String(format: "frame_%03d.png", index))
            if let tiff = img.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiff),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                try? pngData.write(to: frameURL)
            }
        }

        let pet = CustomPet(
            id: petId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            fps: fps,
            frameCount: images.count,
            leftHideOffset: leftHideOffset,
            rightHideOffset: rightHideOffset
        )
        let metaURL = petDir.appendingPathComponent("metadata.json")
        if let metaData = try? JSONEncoder().encode(pet) {
            try? metaData.write(to: metaURL)
        }

        cacheLock.withLock {
            imageCache[petId] = images
        }
        loadAllPets()
        return pet
    }

    // 커스텀 펫 삭제 및 디렉토리 정리
    public func deletePet(id: String) {
        guard UUID(uuidString: id) != nil else { return }

        let petDir = petsDirectoryURL.appendingPathComponent(id)
        try? fileManager.removeItem(at: petDir)
        cacheLock.withLock {
            _ = imageCache.removeValue(forKey: id)
        }
        loadAllPets()

        // 활성 선택 펫 삭제 시 기본 펫으로 롤백
        if AppSettings.shared.selectedCustomPetId == id {
            AppSettings.shared.selectedCustomPetId = nil
            AppSettings.shared.selectedPetType = .cat
        }
    }
}

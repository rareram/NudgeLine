// swift-tools-version: 5.9
// 외부 의존성 없는 Apple 네이티브 SPM 설정
import PackageDescription

let package = Package(
    name: "NudgeLine",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "NudgeLine",
            targets: ["NudgeLine"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "NudgeLine",
            dependencies: [],
            path: "Sources/NudgeLine"
        )
    ]
)

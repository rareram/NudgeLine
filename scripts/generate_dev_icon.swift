import AppKit
import Foundation

// 마스터 아이콘 로드
guard CommandLine.arguments.count > 2 else {
    print("Usage: swift generate_dev_icon.swift <input_icon_path> <output_icon_path>")
    exit(1)
}

let inputPath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]

guard let baseImage = NSImage(contentsOfFile: inputPath) else {
    print("Error: Failed to load base icon at \(inputPath)")
    exit(1)
}

let size = CGSize(width: 1024, height: 1024)
let devImage = NSImage(size: size)

devImage.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else {
    exit(1)
}

// 1. 원본 아이콘 렌더링
baseImage.draw(in: CGRect(origin: .zero, size: size))

// 2. 우측 상단 DEV 배지 렌더링
let badgeRect = CGRect(x: 600, y: 720, width: 280, height: 140)
let badgePath = NSBezierPath(roundedRect: badgeRect, xRadius: 40, yRadius: 40)

// 그림자
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: NSColor.black.withAlphaComponent(0.45).cgColor)

// 오렌지/앰버 그라데이션 배경
let colorSpace = CGColorSpaceCreateDeviceRGB()
let gradientColors = [
    NSColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0).cgColor,
    NSColor(red: 0.95, green: 0.35, blue: 0.05, alpha: 1.0).cgColor
] as CFArray
let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: [0.0, 1.0])!

badgePath.addClip()
ctx.drawLinearGradient(gradient, start: CGPoint(x: 600, y: 860), end: CGPoint(x: 880, y: 720), options: [])
ctx.restoreGState()

// 배지 테두리
NSColor.white.withAlphaComponent(0.4).setStroke()
badgePath.lineWidth = 6
badgePath.stroke()

// DEV 텍스트 각인
let paragraphStyle = NSMutableParagraphStyle()
paragraphStyle.alignment = .center

let font = NSFont.systemFont(ofSize: 76, weight: .heavy)
let attributes: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white,
    .paragraphStyle: paragraphStyle,
    .shadow: {
        let s = NSShadow()
        s.shadowOffset = CGSize(width: 0, height: -2)
        s.shadowBlurRadius = 4
        s.shadowColor = NSColor.black.withAlphaComponent(0.3)
        return s
    }()
]

let text = "DEV" as NSString
let textRect = CGRect(x: 600, y: 750, width: 280, height: 85)
text.draw(in: textRect, withAttributes: attributes)

devImage.unlockFocus()

// PNG 저장
guard let tiffData = devImage.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    print("Error: Failed to encode PNG representation")
    exit(1)
}

try pngData.write(to: URL(fileURLWithPath: outputPath))
print("Successfully generated DEV icon at \(outputPath)")

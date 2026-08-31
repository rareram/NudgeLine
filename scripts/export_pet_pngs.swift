import SwiftUI
import AppKit

enum PetType {
    case cat
    case dog
    case whiteTiger
}

// Setup Models & Views to export
let fileManager = FileManager.default
let baseOutputDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("exported_pets")

let pets: [(type: PetType, name: String)] = [
    (.whiteTiger, "WhiteTiger"),
    (.cat, "Cat"),
    (.dog, "Dog")
]

try? fileManager.createDirectory(at: baseOutputDir, withIntermediateDirectories: true)

print("Starting High-Res Transparent PNG Export for NudgeLine...")

for pet in pets {
    // 1. Vertical Hanging Frames (8 frames)
    let vertDir = baseOutputDir.appendingPathComponent(pet.name).appendingPathComponent("vertical_hanging")
    try? fileManager.createDirectory(at: vertDir, withIntermediateDirectories: true)

    print("\n📦 Exporting [\(pet.name)]...")

    for frame in 0..<8 {
        exportFrameToPNG(frameIndex: frame, petType: pet.type, to: vertDir.appendingPathComponent("frame_\(frame).png"))
    }
}

print("\n✨ All Pet PNGs successfully exported to: \(baseOutputDir.path)")

// MARK: - Export Renderer Helper
func exportFrameToPNG(frameIndex: Int, petType: PetType, to outputURL: URL) {
    let scale: CGFloat = 4.0 // 4x Ultra High-Res Export for clean pixel-perfect editing
    let width: CGFloat = 24 * scale
    let height: CGFloat = 35 * scale

    let image = NSImage(size: NSSize(width: width, height: height))
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return
    }

    context.clear(CGRect(x: 0, y: 0, width: width, height: height))
    context.scaleBy(x: scale, y: scale)

    // Manual Drawing matching Canvas logic for precise frame capture
    drawVerticalFrame(context: context, petType: petType, frameIndex: frameIndex)

    image.unlockFocus()

    if let tiffData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        try? pngData.write(to: outputURL)
        print("  ✓ Saved: \(outputURL.lastPathComponent)")
    }
}

func drawVerticalFrame(context: CGContext, petType: PetType, frameIndex: Int) {
    let tailOffsets: [CGFloat] = [-3.8, -2.8, 0.0, 2.8, 3.8, 2.8, 0.0, -2.8]
    let headTilts: [CGFloat] = [-1.5, -0.8, 0.0, 0.8, 1.5, 0.8, 0.0, -0.8]
    let pawLifts: [CGFloat] = [0.0, -0.8, -1.6, -0.8, 0.0, 0.6, 1.2, 0.6]
    let legSways: [CGFloat] = [-1.8, -1.0, 0.0, 1.0, 1.8, 1.0, 0.0, -1.0]
    let breathY: [CGFloat] = [0.0, 0.4, 0.8, 0.4, 0.0, -0.4, -0.8, -0.4]

    let tailSway = tailOffsets[frameIndex]
    let headTilt = headTilts[frameIndex]
    let pawLift = pawLifts[frameIndex]
    let legSway = legSways[frameIndex]
    let bY = breathY[frameIndex]

    let mainColor: NSColor
    let subColor: NSColor = .white
    let stripeColor: NSColor
    let earInnerColor = NSColor(red: 1.0, green: 0.55, blue: 0.65, alpha: 1.0)
    let blushColor = NSColor(red: 1.0, green: 0.45, blue: 0.55, alpha: 0.68)
    let eyeColor = NSColor(red: 0.15, green: 0.12, blue: 0.12, alpha: 1.0)
    let mouthColor = NSColor(red: 0.50, green: 0.28, blue: 0.22, alpha: 1.0)

    switch petType {
    case .cat:
        mainColor = NSColor(red: 1.0, green: 0.64, blue: 0.28, alpha: 1.0)
        stripeColor = NSColor(red: 0.72, green: 0.38, blue: 0.12, alpha: 1.0)
    case .dog:
        mainColor = NSColor(red: 0.94, green: 0.70, blue: 0.34, alpha: 1.0)
        stripeColor = NSColor(red: 0.80, green: 0.54, blue: 0.20, alpha: 1.0)
    case .whiteTiger:
        mainColor = NSColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 1.0)
        stripeColor = NSColor(red: 0.18, green: 0.18, blue: 0.22, alpha: 1.0)
    }

    // 1. Tail
    context.saveGState()
    context.setStrokeColor(mainColor.cgColor)
    context.setLineWidth(4.4)
    context.setLineCap(.round)
    context.beginPath()
    context.move(to: CGPoint(x: 14, y: 35 - (22 + bY)))
    context.addCurve(to: CGPoint(x: 14 + tailSway, y: 35 - (33.5 + bY)),
                     control1: CGPoint(x: 16.5 + (tailSway * 0.5), y: 35 - (27.5 + bY)),
                     control2: CGPoint(x: 17.5 + tailSway, y: 35 - (30.5 + bY)))
    context.strokePath()
    context.restoreGState()

    // 2. Back Paws
    context.setFillColor(subColor.cgColor)
    context.fillEllipse(in: CGRect(x: 6.5 + legSway, y: 35 - (21 + bY) - 4.2, width: 4.3, height: 4.2))
    context.fillEllipse(in: CGRect(x: 12.0 - legSway, y: 35 - (21 + bY) - 4.2, width: 4.3, height: 4.2))

    // Paw Jellies
    context.setFillColor(earInnerColor.withAlphaComponent(0.85).cgColor)
    context.fillEllipse(in: CGRect(x: 7.7 + legSway, y: 35 - (23 + bY) - 1.4, width: 1.8, height: 1.4))
    context.fillEllipse(in: CGRect(x: 13.2 - legSway, y: 35 - (23 + bY) - 1.4, width: 1.8, height: 1.4))

    // 3. Body & Belly
    context.setFillColor(mainColor.cgColor)
    let bodyPath = CGPath(roundedRect: CGRect(x: 5.5, y: 35 - (13.0 + bY) - 10.5, width: 12.0, height: 10.5), cornerWidth: 5.2, cornerHeight: 5.2, transform: nil)
    context.addPath(bodyPath)
    context.fillPath()

    context.setFillColor(subColor.cgColor)
    context.fillEllipse(in: CGRect(x: 7.5, y: 35 - (14.0 + bY) - 8.5, width: 8.0, height: 8.5))

    // 4. Front Paws
    context.setFillColor(subColor.cgColor)
    context.fillEllipse(in: CGRect(x: 0, y: 35 - 4.0 - 5.2, width: 6.2, height: 5.2))
    context.fillEllipse(in: CGRect(x: 0.5, y: 35 - (11.5 + pawLift) - 4.8, width: 5.8, height: 4.8))

    // 5. Head
    let headX: CGFloat = 3.2 + (headTilt * 0.4)
    let headY: CGFloat = 1.2 + (bY * 0.5)
    let headRect = CGRect(x: headX, y: 35 - headY - 14.8, width: 16.8, height: 14.8)
    context.setFillColor(mainColor.cgColor)
    context.fillEllipse(in: headRect)

    // Ears
    if petType == .whiteTiger {
        context.setFillColor(stripeColor.cgColor)
        context.fillEllipse(in: CGRect(x: headX + 1.0, y: 35 - (headY - 0.5) - 5.2, width: 5.6, height: 5.2))
        context.fillEllipse(in: CGRect(x: headX + 11.5, y: 35 - (headY - 0.5) - 5.2, width: 5.6, height: 5.2))
        context.setFillColor(earInnerColor.cgColor)
        context.fillEllipse(in: CGRect(x: headX + 2.0, y: 35 - (headY + 0.5) - 3.4, width: 3.6, height: 3.4))
        context.fillEllipse(in: CGRect(x: headX + 12.5, y: 35 - (headY + 0.5) - 3.4, width: 3.6, height: 3.4))
    }

    // White Muzzle
    context.setFillColor(subColor.cgColor)
    context.fillEllipse(in: CGRect(x: headX + 4.8, y: 35 - (headY + 7.8) - 5.8, width: 7.4, height: 5.8))

    // Eyes
    context.setFillColor(eyeColor.cgColor)
    context.fillEllipse(in: CGRect(x: headX + 3.8, y: 35 - (headY + 6.2) - 3.4, width: 2.8, height: 3.4))
    context.fillEllipse(in: CGRect(x: headX + 10.6, y: 35 - (headY + 6.2) - 3.4, width: 2.8, height: 3.4))

    // Eye Highlights
    context.setFillColor(NSColor.white.cgColor)
    context.fillEllipse(in: CGRect(x: headX + 4.4, y: 35 - (headY + 6.6) - 1.3, width: 1.1, height: 1.3))
    context.fillEllipse(in: CGRect(x: headX + 11.2, y: 35 - (headY + 6.6) - 1.3, width: 1.1, height: 1.3))

    // Blush
    context.setFillColor(blushColor.cgColor)
    context.fillEllipse(in: CGRect(x: headX + 1.8, y: 35 - (headY + 9.5) - 2.0, width: 3.0, height: 2.0))
    context.fillEllipse(in: CGRect(x: headX + 12.4, y: 35 - (headY + 9.5) - 2.0, width: 3.0, height: 2.0))

    // Nose
    let noseColor = (petType == .dog) ? eyeColor : earInnerColor
    context.setFillColor(noseColor.cgColor)
    context.fillEllipse(in: CGRect(x: headX + 7.6, y: 35 - (headY + 8.5) - 1.3, width: 1.8, height: 1.3))

    // Tiger Forehead 王 mark
    if petType == .whiteTiger {
        context.setFillColor(stripeColor.cgColor)
        context.fill(CGRect(x: headX + 6.3, y: 35 - (headY + 1.8) - 1.1, width: 4.6, height: 1.1))
        context.fill(CGRect(x: headX + 7.0, y: 35 - (headY + 3.8) - 1.0, width: 3.2, height: 1.0))
        context.fill(CGRect(x: headX + 8.0, y: 35 - (headY + 1.6) - 3.5, width: 1.2, height: 3.5))

        // Whiskers
        context.fill(CGRect(x: headX + 0.6, y: 35 - (headY + 7.0) - 1.1, width: 2.8, height: 1.1))
        context.fill(CGRect(x: headX + 0.4, y: 35 - (headY + 8.8) - 1.1, width: 2.5, height: 1.1))
        context.fill(CGRect(x: headX + 13.6, y: 35 - (headY + 7.0) - 1.1, width: 2.8, height: 1.1))
        context.fill(CGRect(x: headX + 14.0, y: 35 - (headY + 8.8) - 1.1, width: 2.5, height: 1.1))
    }
}


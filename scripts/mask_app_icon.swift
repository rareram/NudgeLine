import AppKit
import Foundation

let sourcePath = "draft/logo/option_e3_glass_bold_jelly.png"
guard let sourceImage = NSImage(contentsOfFile: sourcePath) else {
    print("Error: Cannot load \(sourcePath)")
    exit(1)
}

let size = CGSize(width: 1024, height: 1024)

// Standard macOS Icon bounds: centered squircle of size 834x834 with radius 185
let targetSquircleRect = CGRect(x: 95, y: 95, width: 834, height: 834)
let targetSquirclePath = NSBezierPath(roundedRect: targetSquircleRect, xRadius: 185, yRadius: 185)

let finalRep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size.width),
    pixelsHigh: Int(size.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!

NSGraphicsContext.saveGraphicsState()
let ctx = NSGraphicsContext(bitmapImageRep: finalRep)!
NSGraphicsContext.current = ctx

// Clear full transparent
ctx.cgContext.clear(CGRect(origin: .zero, size: size))

// 1. Draw soft natural drop shadow around the glass icon
ctx.cgContext.saveGState()
ctx.cgContext.setShadow(offset: CGSize(width: 0, height: -14), blur: 32, color: NSColor.black.withAlphaComponent(0.40).cgColor)
NSColor.black.setFill()
targetSquirclePath.fill()
ctx.cgContext.restoreGState()

// 2. Scale up the inner glass artwork so that the glass border matches the squircle exactly!
// In original 1024x1024 image, the inner glass border is roughly at (x: 175, y: 175, w: 674, h: 674).
// To scale (674 -> 834), scale factor = 834 / 674 = ~1.237.
// Center pivot is (512, 512).
// Draw rect for source image:
// newWidth = 1024 * 1.240 = 1270, newHeight = 1270
// origin = 512 - 1270/2 = -123
let scaledRect = CGRect(x: -123, y: -123, width: 1270, height: 1270)

ctx.cgContext.saveGState()
targetSquirclePath.addClip()
sourceImage.draw(in: scaledRect)
ctx.cgContext.restoreGState()

// 3. Crisp Glass Rim Highlight on top
ctx.cgContext.saveGState()
targetSquirclePath.lineWidth = 2.0
NSColor.white.withAlphaComponent(0.40).setStroke()
targetSquirclePath.stroke()
ctx.cgContext.restoreGState()

NSGraphicsContext.restoreGraphicsState()

guard let pngData = finalRep.representation(using: .png, properties: [:]) else { exit(1) }
try? pngData.write(to: URL(fileURLWithPath: "Resources/icon_1024.png"))
try? pngData.write(to: URL(fileURLWithPath: "docs/images/app_icon.png"))
print("Successfully scaled up glass icon and eliminated background margin!")

import AppKit
import Foundation

let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else {
    exit(1)
}

// 1. Background Rounded Squircle
let squircleRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let squirclePath = NSBezierPath(roundedRect: squircleRect, xRadius: 180, yRadius: 180)

ctx.saveGState()
squirclePath.addClip()

// Background Gradient (Deep Modern Navy to Indigo)
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bgColors = [
    NSColor(red: 0.10, green: 0.13, blue: 0.20, alpha: 1.0).cgColor,
    NSColor(red: 0.05, green: 0.07, blue: 0.12, alpha: 1.0).cgColor
] as CFArray
let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0])!
ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])

// Subtle inner glow / grid lines
ctx.restoreGState()

// 2. White subtle border
NSColor.white.withAlphaComponent(0.18).setStroke()
squirclePath.lineWidth = 12
squirclePath.stroke()

// 3. Vertical Timeline Bar Track (Left Edge Graphic)
let barRect = CGRect(x: 240, y: 220, width: 36, height: 584)
let barPath = NSBezierPath(roundedRect: barRect, xRadius: 18, yRadius: 18)
NSColor.white.withAlphaComponent(0.20).setFill()
barPath.fill()

// Event Block 1 (Blue)
let ev1Rect = CGRect(x: 240, y: 600, width: 36, height: 140)
let ev1Path = NSBezierPath(roundedRect: ev1Rect, xRadius: 18, yRadius: 18)
NSColor(red: 0.22, green: 0.58, blue: 0.98, alpha: 1.0).setFill()
ev1Path.fill()

// Event Block 2 (Green)
let ev2Rect = CGRect(x: 240, y: 410, width: 36, height: 110)
let ev2Path = NSBezierPath(roundedRect: ev2Rect, xRadius: 18, yRadius: 18)
NSColor(red: 0.20, green: 0.82, blue: 0.45, alpha: 1.0).setFill()
ev2Path.fill()

// Event Block 3 (Purple)
let ev3Rect = CGRect(x: 240, y: 270, width: 36, height: 90)
let ev3Path = NSBezierPath(roundedRect: ev3Rect, xRadius: 18, yRadius: 18)
NSColor(red: 0.70, green: 0.35, blue: 0.95, alpha: 1.0).setFill()
ev3Path.fill()

// Current Time Indicator (Red line + Pin)
let redY: CGFloat = 530
let redLine = NSBezierPath()
redLine.move(to: CGPoint(x: 215, y: redY))
redLine.line(to: CGPoint(x: 295, y: redY))
NSColor(red: 1.0, green: 0.27, blue: 0.23, alpha: 1.0).setStroke()
redLine.lineWidth = 14
redLine.stroke()

let redDot = NSBezierPath(ovalIn: CGRect(x: 238, y: redY - 14, width: 28, height: 28))
NSColor(red: 1.0, green: 0.27, blue: 0.23, alpha: 1.0).setFill()
redDot.fill()

// 4. Floating Event Card (Folder Tab Bookmark Style)
let cardRect = CGRect(x: 320, y: 460, width: 440, height: 220)
let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 36, yRadius: 36)
NSColor.white.withAlphaComponent(0.12).setFill()
cardPath.fill()
NSColor.white.withAlphaComponent(0.25).setStroke()
cardPath.lineWidth = 4
cardPath.stroke()

// Card Content Lines
let dot1 = NSBezierPath(ovalIn: CGRect(x: 360, y: 605, width: 20, height: 20))
NSColor(red: 0.22, green: 0.58, blue: 0.98, alpha: 1.0).setFill()
dot1.fill()

let line1 = NSBezierPath(roundedRect: CGRect(x: 395, y: 608, width: 200, height: 14), xRadius: 7, yRadius: 7)
NSColor.white.withAlphaComponent(0.9).setFill()
line1.fill()

let line2 = NSBezierPath(roundedRect: CGRect(x: 360, y: 555, width: 340, height: 18), xRadius: 9, yRadius: 9)
NSColor.white.withAlphaComponent(0.95).setFill()
line2.fill()

let line3 = NSBezierPath(roundedRect: CGRect(x: 360, y: 510, width: 240, height: 14), xRadius: 7, yRadius: 7)
NSColor.white.withAlphaComponent(0.6).setFill()
line3.fill()

image.unlockFocus()

// Export PNG
guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    exit(1)
}

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"
try pngData.write(to: URL(fileURLWithPath: outputPath))
print("Successfully generated: \(outputPath)")

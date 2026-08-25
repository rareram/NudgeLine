// Dock 아이콘 없는 백그라운드 보조(Accessory) 앱 진입점
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

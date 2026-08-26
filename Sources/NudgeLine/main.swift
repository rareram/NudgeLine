// Dock 아이콘 없는 백그라운드 보조(Accessory) 앱 진입점
import AppKit

// 중복 실행 방어: 동일 번들 ID 선행 프로세스 감지 시 기존 앱 포커스 후 즉시 종료
let currentBundleId = Bundle.main.bundleIdentifier ?? "com.rareram.NudgeLine"
let currentPid = getpid()
let duplicateInstances = NSRunningApplication.runningApplications(withBundleIdentifier: currentBundleId).filter { $0.processIdentifier != currentPid }

if let primaryInstance = duplicateInstances.first {
    primaryInstance.activate()
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

// ServiceManagement 기반 macOS 로그인 시 자동 실행 관리자
import Foundation
import ServiceManagement
import Combine

public final class LaunchAtLoginHelper: ObservableObject {
    public static let shared = LaunchAtLoginHelper()

    @Published public var isEnabled: Bool = false

    private init() {
        refreshStatus()
    }

    // 현재 로그인 시 자동 실행 등록 상태 갱신
    public func refreshStatus() {
        self.isEnabled = (SMAppService.mainApp.status == .enabled)
    }

    // 로그인 시 자동 실행 활성화/비활성화 토글
    public func setEnabled(_ enable: Bool) {
        do {
            if enable {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            // 실패 시 무시하고 상태 재동기화
        }
        refreshStatus()
    }
}

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

    // 시스템 로그인 항목 등록 상태와 내부 Published 상태 동기화
    public func refreshStatus() {
        self.isEnabled = (SMAppService.mainApp.status == .enabled)
    }

    // 로그인 시 자동 실행 등록/해제 (동일 상태 요청 시 조기 탈출)
    public func setEnabled(_ enable: Bool) {
        guard enable != (SMAppService.mainApp.status == .enabled) else { return }

        do {
            if enable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // 시스템 환경설정 권한 거부(TCC) 등으로 실패 시 실제 상태로 UI 롤백
        }
        refreshStatus()
    }
}


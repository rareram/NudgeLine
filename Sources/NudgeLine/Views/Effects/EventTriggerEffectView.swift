// 일정 및 정각 알림 마이크로 이펙트 렌더링 뷰 (1.0초 16프레임 자동 점멸 및 소멸)
import SwiftUI
import AppKit

public struct EventTriggerEffectView: View {
    public static let canvasSize: CGFloat = 110.0
    public static let frameCount: Int = 16
    public static let frameInterval: TimeInterval = 0.062 // 16프레임 * 62ms ≈ 1.0초

    public let effectType: EventTriggerEffectType
    public let isHorizontal: Bool
    public let barPosition: BarPosition
    public let onComplete: @MainActor () -> Void

    @State private var currentFrame: Int = 0
    @State private var isCompleted: Bool = false

    public init(
        effectType: EventTriggerEffectType,
        isHorizontal: Bool,
        barPosition: BarPosition,
        onComplete: @escaping @MainActor () -> Void
    ) {
        self.effectType = effectType
        self.isHorizontal = isHorizontal
        self.barPosition = barPosition
        self.onComplete = onComplete
    }

    public var body: some View {
        Group {
            if !isCompleted {
                effectImageView
                    .frame(width: Self.canvasSize, height: Self.canvasSize)
                    .rotationEffect(rotationAngle)
                    .scaleEffect(x: scaleX, y: 1.0)
                    .allowsHitTesting(false)
                    .task {
                        await runFrameAnimation()
                    }
                    .onDisappear {
                        isCompleted = true
                        onComplete()
                    }
            }
        }
    }
}

// MARK: - 서브뷰 및 시각 변환 (Subviews & Transformations)
extension EventTriggerEffectView {
    @ViewBuilder
    private var effectImageView: some View {
        if let nsImage = effectType.image(frameIndex: currentFrame) {
            Image(nsImage: nsImage)
                .interpolation(.high)
                .resizable()
                .scaledToFit()
        }
    }

    private var rotationAngle: Angle {
        if isHorizontal {
            // 하단 바: 위쪽으로 방전되도록 -90도 회전
            return .degrees(-90)
        }
        return .zero
    }

    private var scaleX: CGFloat {
        if !isHorizontal && barPosition == .right {
            // 우측 바: 화면 안쪽(좌측)으로 방전되도록 수평 반전
            return -1.0
        }
        return 1.0
    }
}

// MARK: - 16프레임 구조화된 동시성 애니메이션 (Structured Concurrency Engine)
extension EventTriggerEffectView {
    @MainActor
    private func runFrameAnimation() async {
        currentFrame = 0
        let startTime = Date()

        for f in 1..<Self.frameCount {
            guard !Task.isCancelled && !isCompleted else {
                onComplete()
                return
            }
            try? await Task.sleep(nanoseconds: UInt64(Self.frameInterval * 1_000_000_000))
            guard !Task.isCancelled && !isCompleted else {
                onComplete()
                return
            }
            // 미션컨트롤, 스페이스 전환 등으로 인한 지연 시 잔여 프레임 강제 종료 (최대 1.5초 초과 방지)
            if Date().timeIntervalSince(startTime) > 1.5 {
                isCompleted = true
                onComplete()
                return
            }
            currentFrame = f
        }

        // 16프레임 완료 후 종료 콜백 실행
        guard !Task.isCancelled && !isCompleted else {
            onComplete()
            return
        }
        isCompleted = true
        onComplete()
    }
}

// MARK: - 알림 센터 식별자 (Notifications)
extension Notification.Name {
    public static let previewEventContactEffect = Notification.Name("NudgeLine.previewEventContactEffect")
    public static let previewPreEventAlert = Notification.Name("NudgeLine.previewPreEventAlert")
}

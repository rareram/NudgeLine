// 일정 및 정각 알림 마이크로 이펙트 렌더링 뷰 (1.0초 16프레임 자동 점멸 및 소멸)
import SwiftUI
import AppKit

public struct EventTriggerEffectView: View {
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
                    .frame(width: 80, height: 80)
                    .rotationEffect(rotationAngle)
                    .scaleEffect(x: scaleX, y: 1.0)
                    .allowsHitTesting(false)
                    .onAppear {
                        startFrameAnimation()
                    }
                    .onDisappear {
                        isCompleted = true
                    }
            }
        }
    }

    // MARK: - 프레임 이미지 렌더링 (다형성 지원)
    @ViewBuilder
    private var effectImageView: some View {
        if let nsImage = effectType.image(frameIndex: currentFrame) {
            Image(nsImage: nsImage)
                .interpolation(.high)
                .resizable()
                .scaledToFit()
        }
    }

    // MARK: - 방향별 변환 (Rotation / Scale)
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

    // MARK: - 16프레임 1.0초(프레임당 62ms) 실키 스무스 애니메이션 구동
    private func startFrameAnimation() {
        currentFrame = 0

        for f in 1..<Self.frameCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(f) * Self.frameInterval) {
                if !self.isCompleted {
                    self.currentFrame = f
                }
            }
        }

        // 16프레임 완료 후 1.0초 시점에 완전 소멸 및 콜백
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(Self.frameCount) * Self.frameInterval + 0.01) {
            guard !self.isCompleted else { return }
            self.isCompleted = true
            self.onComplete()
        }
    }
}

extension Notification.Name {
    public static let previewEventContactEffect = Notification.Name("NudgeLine.previewEventContactEffect")
}

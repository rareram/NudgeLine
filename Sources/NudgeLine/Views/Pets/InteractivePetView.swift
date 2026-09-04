// 펫 마스코트 피벗 회전 및 6대 숨김 물리 인터랙션 뷰
import AppKit
import SwiftUI

struct InteractivePetView: View {
    let petType: PetType
    let isHorizontal: Bool
    let isBarHovered: Bool
    let isPetProximityHovered: Bool
    @ObservedObject var settings: AppSettings
    let thickness: CGFloat
    let accentColor: Color

    var body: some View {
        let isHovered = isBarHovered || isPetProximityHovered
        let hideStyle = settings.petHideStyle

        HangingPetIndicatorView(
            petType: petType,
            isHorizontal: isHorizontal,
            isRightEdge: settings.barPosition == .right,
            isAnimating: true,
            accentColor: accentColor
        )
        // 1. 소멸 투명도
        .opacity(calculateOpacity(isHovered: isHovered, hideStyle: hideStyle))
        // 2. 블러 효과 (연기 모션)
        .blur(radius: calculateBlur(isHovered: isHovered, hideStyle: hideStyle))
        // 3. 스케일 및 왜곡 (팝, 회오리, 슬라임, 연기)
        .scaleEffect(
            x: calculateScaleX(isHovered: isHovered, hideStyle: hideStyle),
            y: calculateScaleY(isHovered: isHovered, hideStyle: hideStyle),
            anchor: gripPivotAnchor
        )
        // 4. 단일 힌지 피벗 회전 (꼬리/머리 빼꼼 및 회오리 720°)
        .rotationEffect(
            .degrees(calculateRotationAngle(isHovered: isHovered, hideStyle: hideStyle)),
            anchor: gripPivotAnchor
        )
        // 5. 화면 공간 수평 이동 오프셋
        .offset(
            x: calculateOffsetX(isHovered: isHovered, hideStyle: hideStyle),
            y: calculateOffsetY(isHovered: isHovered, hideStyle: hideStyle)
        )
        .animation(
            isHorizontal ? .spring(response: 0.36, dampingFraction: 0.82) : .spring(response: 0.28, dampingFraction: 0.72),
            value: isHovered
        )
    }

    // 단일 힌지 피벗 (PET_SPEC_RULES §1.2, §2.1): 손 접촉 핀 고정 불변
    private var gripPivotAnchor: UnitPoint {
        let centerY: CGFloat = 0.267

        if isHorizontal {
            return UnitPoint(x: 0.50, y: 0.50)
        } else if settings.barPosition == .right {
            return UnitPoint(x: 1.0, y: centerY)
        } else {
            return UnitPoint(x: 0.0, y: centerY)
        }
    }

    private func calculateOpacity(isHovered: Bool, hideStyle: PetHideStyle) -> Double {
        guard isHovered else { return 1.0 }
        switch hideStyle {
        case .tailPeek, .headPeek:
            return 1.0
        case .pop, .vortex, .squish, .smoke:
            return 0.0
        }
    }

    private func calculateBlur(isHovered: Bool, hideStyle: PetHideStyle) -> CGFloat {
        guard isHovered else { return 0.0 }
        return hideStyle == .smoke ? 8.0 : 0.0
    }

    private func calculateScaleX(isHovered: Bool, hideStyle: PetHideStyle) -> CGFloat {
        guard isHovered else { return 1.0 }
        switch hideStyle {
        case .pop, .vortex:
            return 0.05
        case .squish:
            return 1.6
        case .smoke:
            return 1.3
        case .tailPeek, .headPeek:
            return 1.0
        }
    }

    private func calculateScaleY(isHovered: Bool, hideStyle: PetHideStyle) -> CGFloat {
        if isHorizontal && hideStyle == .tailPeek {
            return -1.0 // 하단 바 꼬리살랑: 꼬리가 위로 오도록 상하 반전
        }
        guard isHovered else { return 1.0 }
        switch hideStyle {
        case .pop, .vortex, .squish:
            return 0.05
        case .smoke:
            return 1.3
        case .tailPeek, .headPeek:
            return 1.0
        }
    }

    // PET_SPEC_RULES §3: 노출량은 지정 오프셋(baseX - 8)과 회전 궤적으로만 제어
    private func calculateOffsetX(isHovered: Bool, hideStyle: PetHideStyle) -> CGFloat {
        let baseX: CGFloat = isHorizontal ? -4 : (settings.barPosition == .left ? max(0, thickness - 2) : 0)
        guard isHovered else { return baseX }

        if isHorizontal {
            return baseX
        }

        let isLeft = (settings.barPosition == .left)
        switch hideStyle {
        case .tailPeek:
            return baseX + (isLeft ? -23.0 : 23.0)
        case .headPeek:
            return baseX + (isLeft ? 6.0 : -6.0)
        case .pop, .vortex, .squish, .smoke:
            return baseX
        }
    }

    // 하단 바(두더지 모션: 평상시 머리/꼬리 15px 빼꼼, 호버 시 바닥 아래로 스르륵 쏙 하강 은폐) vs 세로 바 고정 Y 오프셋
    private func calculateOffsetY(isHovered: Bool, hideStyle: PetHideStyle) -> CGFloat {
        if isHorizontal {
            let baseY: CGFloat = 27.0 // 바닥 베젤 뒤에서 머리 또는 꼬리 15px 빼꼼 노출 (+5px 보정)
            if !isHovered {
                return baseY
            }
            switch hideStyle {
            case .headPeek, .tailPeek:
                return 65.0 // 바닥(베젤) 아래로 스르륵 쏙 완전 하강 은폐
            case .pop, .vortex, .squish, .smoke:
                return baseY
            }
        } else {
            return -15.5
        }
    }

    // PET_SPEC_RULES §3 (Left Bar 기준): tailPeek -80° 위로 회전, headPeek +90° 아래로 회전, vortex 720°
    private func calculateRotationAngle(isHovered: Bool, hideStyle: PetHideStyle) -> Double {
        guard isHovered else { return 0.0 }

        if isHorizontal {
            switch hideStyle {
            case .vortex: return 720.0
            case .tailPeek, .headPeek, .pop, .squish, .smoke: return 0.0
            }
        }

        let isLeft = (settings.barPosition == .left)
        switch hideStyle {
        case .tailPeek:
            return isLeft ? -85.0 : 85.0
        case .headPeek:
            return isLeft ? 85.0 : -85.0
        case .vortex:
            return 720.0
        case .pop, .squish, .smoke:
            return 0.0
        }
    }
}

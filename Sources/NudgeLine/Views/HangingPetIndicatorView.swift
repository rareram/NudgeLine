// 기본 내장 펫 3종(고양이, 강아지, 백호) 에셋 렌더러 라우터 뷰
import SwiftUI

public struct HangingPetIndicatorView: View {
    public let petType: PetType
    public let isHorizontal: Bool
    public let isRightEdge: Bool
    // 펫 숨김/비활성 상태 시 16 FPS 렌더링 타이머 일시정지 (CPU/전력 소모 방지)
    public let isAnimating: Bool
    public let accentColor: Color

    public init(
        petType: PetType,
        isHorizontal: Bool,
        isRightEdge: Bool = false,
        isAnimating: Bool = true,
        accentColor: Color = .red
    ) {
        self.petType = petType
        self.isHorizontal = isHorizontal
        self.isRightEdge = isRightEdge
        self.isAnimating = isAnimating
        self.accentColor = accentColor
    }

    public var body: some View {
        Group {
            switch petType {
            case .calicoCat:
                CatPetAsset(isHorizontal: isHorizontal, isRightEdge: isRightEdge, isAnimating: isAnimating, accentColor: accentColor)
            case .jindoDog:
                JindoDogPetAsset(isHorizontal: isHorizontal, isRightEdge: isRightEdge, isAnimating: isAnimating, accentColor: accentColor)
            case .whiteTiger:
                WhiteTigerPetAsset(isHorizontal: isHorizontal, isRightEdge: isRightEdge, isAnimating: isAnimating, accentColor: accentColor)
            }
        }
    }
}

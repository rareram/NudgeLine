// 기본 내장 펫 3종(고양이, 강아지, 백호) 에셋 렌더러 라우터 뷰
import SwiftUI

public struct HangingPetIndicatorView: View {
    public let petType: PetType
    public let isHorizontal: Bool
    public let isRightEdge: Bool
    public let accentColor: Color

    public init(
        petType: PetType,
        isHorizontal: Bool,
        isRightEdge: Bool = false,
        accentColor: Color = .red
    ) {
        self.petType = petType
        self.isHorizontal = isHorizontal
        self.isRightEdge = isRightEdge
        self.accentColor = accentColor
    }

    public var body: some View {
        Group {
            switch petType {
            case .cat:
                CatPetAsset(isHorizontal: isHorizontal, isRightEdge: isRightEdge, accentColor: accentColor)
            case .dog:
                JindoDogPetAsset(isHorizontal: isHorizontal, isRightEdge: isRightEdge, accentColor: accentColor)
            case .whiteTiger:
                WhiteTigerPetAsset(isHorizontal: isHorizontal, isRightEdge: isRightEdge, accentColor: accentColor)
            }
        }
    }
}

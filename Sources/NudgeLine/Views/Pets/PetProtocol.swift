// 기본 내장 펫 캐릭터 종류 열거형 (삼색이, 진도백구, 백호)
import Foundation

public enum PetType: String, Codable, CaseIterable, Identifiable, Sendable {
    case calicoCat  = "calicoCat"  // 삼색고양이
    case jindoDog   = "jindoDog"   // 진도백구
    case whiteTiger = "whiteTiger" // 백호

    public var id: String { rawValue }
}

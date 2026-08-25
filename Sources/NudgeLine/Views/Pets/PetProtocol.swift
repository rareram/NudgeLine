// 기본 내장 펫 캐릭터 종류 열거형
import SwiftUI

public enum PetType: String, Codable, CaseIterable {
    case cat          // 삼색고양이 (Calico Cat)
    case dog          // 진도백구 (White Jindo Dog)
    case whiteTiger   // 백호 (White Tiger)
}

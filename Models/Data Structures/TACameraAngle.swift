//
//  TACameraAngle.swift
//  TechniqueAnalysis
//
//  Created by Trevor on 04.02.19.
//

import Foundation

public enum TACameraAngle: String, Codable {
    case front, back, left, right

    public var opposite: TACameraAngle? {
        switch self {
        case .left:
            return .right
        case .right:
            return .left
        default:
            return nil
        }
    }
}

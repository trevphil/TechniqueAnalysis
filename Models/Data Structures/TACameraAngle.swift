//
//  TACameraAngle.swift
//  TechniqueAnalysis
//
//  Created by Trevor on 04.02.19.
//

import Foundation

/// Describes the camera angle of a video, with respect to someone doing an exercise
public enum TACameraAngle: String, Codable {

    case front, back, left, right, unknown

    /// Returns `left` if the camera angle is `right`, `right` if the camera angle is `left`,
    /// and `nil` otherwise
    public var oppositeSide: TACameraAngle? {
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

//
//  TAPointEstimate.swift
//  TechniqueAnalysis
//
//  Created by Trevor on 04.12.18.
//

import Foundation

/// Basic computational unit for the predicted location of a bodypart at some point in time
public struct TAPointEstimate: Codable {

    // MARK: - Properties

    /// The location of the point, normalized into [0, 1]. The point uses a coordinate space
    /// similar to normal views, where the origin is the bottom-left corner.
    public let point: CGPoint
    /// The confidence level that `bodyPart` is at `point`, normalized into [0, 1]
    public let confidence: Double
    /// The body part being referenced by `point`
    public let bodyPart: TABodyPart?

}

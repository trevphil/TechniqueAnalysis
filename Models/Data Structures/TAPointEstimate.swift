//
//  TAPointEstimate.swift
//  TechniqueAnalysis
//
//  Created by Trevor on 04.12.18.
//

import Foundation

public struct TAPointEstimate: Codable {
    public let point: CGPoint
    public let confidence: Double
    public let bodyPart: TABodyPart?
}

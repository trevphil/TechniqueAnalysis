//
//  TAMeta.swift
//  TechniqueAnalysis
//
//  Created by Trevor on 04.02.19.
//

import Foundation

public struct TAMeta: Codable {

    // MARK: - Properties

    public let isLabeled: Bool
    public let exerciseName: String
    public let exerciseDetail: String
    public let angle: TACameraAngle

    public var debugDescription: String {
        return "<TAMeta: labeled=\(isLabeled); name=\(exerciseName); " +
        "detail=\(exerciseDetail); angle=\(angle.rawValue)>"
    }

    // MARK: - Initialization

    public init(isLabeled: Bool, exerciseName: String, exerciseDetail: String, angle: TACameraAngle) {
        self.isLabeled = isLabeled
        self.exerciseName = exerciseName
        self.exerciseDetail = exerciseDetail
        self.angle = angle
    }

}

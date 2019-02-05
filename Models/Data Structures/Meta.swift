//
//  Meta.swift
//  TechniqueAnalysis
//
//  Created by Trevor on 04.02.19.
//

import Foundation

public struct Meta: Codable {

    // MARK: - Properties

    public let uuid = UUID()
    public let isLabeled: Bool
    public let exerciseName: String
    public let exerciseDetail: String
    public let angle: CameraAngle

    public var description: String {
        return "<Meta: labeled=\(isLabeled); name=\(exerciseName); " +
        "detail=\(exerciseDetail); angle=\(angle.rawValue); uuid=\(uuid)>"
    }

    // MARK: - Initialization

    public init(isLabeled: Bool, exerciseName: String, exerciseDetail: String, angle: CameraAngle) {
        self.isLabeled = isLabeled
        self.exerciseName = exerciseName
        self.exerciseDetail = exerciseDetail
        self.angle = angle
    }

}

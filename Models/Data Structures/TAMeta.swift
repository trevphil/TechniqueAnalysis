//
//  TAMeta.swift
//  TechniqueAnalysis
//
//  Created by Trevor on 04.02.19.
//

import Foundation

/// Metadata structure to hold information for a video or timeseries
public struct TAMeta: Codable {

    // MARK: - Properties

    /// `true` if the referenced video or timeseries is labeled data and `false` otherwise
    public let isLabeled: Bool
    /// The name (title) of the exercise this metadata is referencing
    public let exerciseName: String
    /// Further details about the exercise, for example if the exercise was performed with correct technique or not
    public let exerciseDetail: String
    /// The camera angle used in the video or timeseries that this metadata is referencing
    public let angle: TACameraAngle

    /// String describing all properties of the `TAMeta` object
    public var debugDescription: String {
        return "<TAMeta: labeled=\(isLabeled); name=\(exerciseName); " +
        "detail=\(exerciseDetail); angle=\(angle.rawValue)>"
    }

    // MARK: - Initialization

    /// Create a new `TAMeta` object
    ///
    /// - Parameters:
    ///   - isLabeled: `true` if the referenced video or timeseries is labeled data and `false` otherwise
    ///   - exerciseName: The name (title) of the exercise this metadata is referencing
    ///   - exerciseDetail: Further details about the exercise, for example if the exercise was performed
    ///                     with correct technique or not. Defaults to empty string if you pass `nil`.
    ///   - angle: The camera angle used in the video or timeseries that this metadata is referencing
    public init(isLabeled: Bool, exerciseName: String, exerciseDetail: String?, angle: TACameraAngle) {
        self.isLabeled = isLabeled
        self.exerciseName = exerciseName
        self.exerciseDetail = exerciseDetail ?? ""
        self.angle = angle
    }

}

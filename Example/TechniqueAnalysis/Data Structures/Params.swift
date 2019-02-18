//
//  Params.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/8/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import TechniqueAnalysis

/// Global configuration for fine-tuning algorithm parameters
struct Params {

    /// The warping window used by `TAKnnDTW`
    static let warpingWindow: Int = 75
    /// The minimum confidence level used by `TAKnnDTW`
    static let minConfidence: Double = 0.08
    /// The frames per second used when sampling videos
    static let fps: Double = 35
    /// The length of sub-clips taken from a video when it is processed
    static let clipLength: TimeInterval = 4.5
    /// The inset percentage from the "edges" of a video when it is being processed into sub-clips
    static let insetPercent: Double = 0.15
    /// The ML model type used for pose/posture recognition
    static let modelType: TAPoseEstimationModel.ModelType = .hourglass

    /// A human-readable string of the current configuration
    static var debugDescription: String {
        return "warping_win=\(warpingWindow), min_confidence=\(minConfidence), " +
            "fps=\(Int(fps)), clip_len=\(clipLength)s, inset=\(Int(insetPercent * 100))%, " +
        "model=\(modelType == .cpm ? "cpm" : "hourglass")"
    }

}

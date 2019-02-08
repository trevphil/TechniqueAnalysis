//
//  Params.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/8/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import TechniqueAnalysis

struct Params {

    static let warpingWindow: Int = 100
    static let minConfidence: Double = 0.2
    static let fps: Double = 25
    static let clipLength: TimeInterval = 5
    static let insetPercent: Double = 0.1
    static let modelType: TAPoseEstimationModel.ModelType = .cpm

    static var debugDescription: String {
        return "warping_win=\(warpingWindow), min_confidence=\(minConfidence), " +
            "fps=\(Int(fps)), clip_len=\(clipLength)s, inset=\(Int(insetPercent * 100))%, " +
        "model=\(modelType == .cpm ? "cpm" : "hourglass")"
    }

}

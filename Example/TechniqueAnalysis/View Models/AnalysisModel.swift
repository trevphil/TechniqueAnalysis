//
//  AnalysisModel.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/8/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

class AnalysisModel {

    // MARK: - Properties

    let title: String
    let exerciseType: String
    let videoURL: URL

    // MARK: - Initialization

    init(exerciseType: String, videoURL: URL) {
        self.title = "Analysis"
        self.exerciseType = exerciseType
        self.videoURL = videoURL
    }

}

//
//  ExerciseSelectionModel.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/8/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

class ExerciseSelectionModel {

    // MARK: - Properties

    let title: String
    let availableExercises: [String]

    // MARK: - Initialization

    init() {
        self.title = "Analysis"
        let exercises: Set<String> = Set(VideoManager.shared.unlabeledVideos.map {
            $0.meta.exerciseName
        })
        self.availableExercises = Array(exercises).sorted()
    }

}

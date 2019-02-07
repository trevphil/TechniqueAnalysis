//
//  VideoCell.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 01.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class VideoCell: UITableViewCell {

    // MARK: - Properties

    static let identifier = "VideoCell"
    @IBOutlet private weak var exerciseNameLabel: UILabel!
    @IBOutlet private weak var exerciseDetailLabel: UILabel!
    @IBOutlet private weak var correctExerciseLabel: UILabel!
    @IBOutlet private weak var correctOverallLabel: UILabel!

    // MARK: - Exposed Functions

    func configure(exerciseName: String,
                   exerciseDetail: String,
                   cameraAngle: String,
                   correctExercise: Bool?,
                   correctOverall: Bool?) {
        exerciseNameLabel.text = "\(exerciseName) (\(cameraAngle))"
        exerciseDetailLabel.text = exerciseDetail

        if let correctExercise = correctExercise {
            correctExerciseLabel.text = correctExercise ? "✅" : "❌"
        } else {
            correctExerciseLabel.text = ""
        }

        if let correctOverall = correctOverall {
            correctOverallLabel.text = correctOverall ? "✅" : "❌"
        } else {
            correctOverallLabel.text = ""
        }
    }

}

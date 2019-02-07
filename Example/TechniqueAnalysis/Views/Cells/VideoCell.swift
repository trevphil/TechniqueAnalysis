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
    @IBOutlet private weak var scoreLabel: UILabel!

    // MARK: - Exposed Functions

    func configure(with model: TestModel.TestCase) {
        exerciseNameLabel.text = "\(model.meta.exerciseName) " +
        "(\(model.meta.angle.rawValue.capitalized))"
        exerciseDetailLabel.text = model.meta.exerciseDetail

        if let correctExercise = model.predictedCorrectExercise {
            correctExerciseLabel.text = correctExercise ? "✅" : "❌"
        } else {
            correctExerciseLabel.text = ""
        }

        if let correctOverall = model.predictedCorrectOverall {
            correctOverallLabel.text = correctOverall ? "✅" : "❌"
        } else {
            correctOverallLabel.text = ""
        }

        if let score = model.predictionScore {
            scoreLabel.text = "\(Int(score))"
        } else {
            scoreLabel.text = "--"
        }
    }

}

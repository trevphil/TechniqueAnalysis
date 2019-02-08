//
//  VideoCell.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 01.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import TechniqueAnalysis

class VideoCell: UITableViewCell {

    // MARK: - Properties

    static let identifier = "VideoCell"
    @IBOutlet private weak var exerciseNameLabel: UILabel!
    @IBOutlet private weak var exerciseDetailLabel: UILabel!
    @IBOutlet private weak var correctExerciseLabel: UILabel!
    @IBOutlet private weak var correctExerciseIcon: UILabel!
    @IBOutlet private weak var correctOverallLabel: UILabel!
    @IBOutlet private weak var correctOverallIcon: UILabel!
    @IBOutlet private weak var scoreLabel: UILabel!

    @IBOutlet private weak var predictedExerciseNameLabel: UILabel!
    @IBOutlet private weak var predictedExerciseDetailLabel: UILabel!
    @IBOutlet private weak var runnerUpExerciseNameLabel: UILabel!
    @IBOutlet private weak var runnerUpExerciseDetailLabel: UILabel!
    @IBOutlet private weak var runnerUpScoreLabel: UILabel!

    // MARK: - Exposed Functions

    func configure(with testResult: TestResult) {
        configureResults(testResult)
        configurePrediction(testResult.predictionMeta)
        configureRunnerUp(testResult.runnerUpMeta, runnerUpScore: testResult.runnerUpScore)
    }

    // MARK: - Private Functions

    private func configureResults(_ testResult: TestResult) {
        exerciseNameLabel.text = "\(testResult.testMeta.exerciseName) " +
        "(\(testResult.testMeta.angle.rawValue.capitalized))"
        exerciseDetailLabel.text = testResult.testMeta.exerciseDetail

        if let correctExercise = testResult.predictedCorrectExercise {
            correctExerciseLabel.text = "Correct\nExercise"
            correctExerciseIcon.text = correctExercise ? "✅" : "❌"
        } else {
            correctExerciseLabel.text = ""
            correctExerciseIcon.text = ""
        }

        if let correctOverall = testResult.predictedCorrectOverall {
            correctOverallLabel.text = "Correct\nOverall"
            correctOverallIcon.text = correctOverall ? "✅" : "❌"
        } else {
            correctOverallLabel.text = ""
            correctOverallIcon.text = ""
        }

        if let score = testResult.predictionScore {
            scoreLabel.text = "\(Int(score))"
        } else {
            scoreLabel.text = "--"
        }
    }

    private func configurePrediction(_ predictionMeta: TAMeta?) {
        if let predictionMeta = predictionMeta {
            predictedExerciseNameLabel.text = "\(predictionMeta.exerciseName) " +
            "(\(predictionMeta.angle.rawValue.capitalized))"
            predictedExerciseDetailLabel.text = predictionMeta.exerciseDetail
        } else {
            predictedExerciseNameLabel.text = ""
            predictedExerciseDetailLabel.text = ""
        }
    }

    private func configureRunnerUp(_ runnerUpMeta: TAMeta?, runnerUpScore: Double?) {
        if let runnerUpMeta = runnerUpMeta {
            runnerUpExerciseNameLabel.text = "\(runnerUpMeta.exerciseName) " +
            "(\(runnerUpMeta.angle.rawValue.capitalized))"
            runnerUpExerciseDetailLabel.text = runnerUpMeta.exerciseDetail
        } else {
            runnerUpExerciseNameLabel.text = ""
            runnerUpExerciseDetailLabel.text = ""
        }

        if let runnerUpScore = runnerUpScore {
            runnerUpScoreLabel.text = "\(Int(runnerUpScore))"
        } else {
            runnerUpScoreLabel.text = "--"
        }
    }

}

//
//  TestResultCell.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 01.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import TechniqueAnalysis

/// Table view cell for showing the results of testing an unlabeled data point
class TestResultCell: UITableViewCell {

    // MARK: - Properties

    /// Cell identifier
    static let identifier = "TestResultCell"
    @IBOutlet private weak var exerciseNameLabel: UILabel!
    @IBOutlet private weak var exerciseDetailLabel: UILabel!
    @IBOutlet private weak var correctOverallLabel: UILabel!
    @IBOutlet private weak var correctOverallIcon: UILabel!
    @IBOutlet private weak var scoreLabel: UILabel!

    @IBOutlet private weak var predictedExerciseNameLabel: UILabel!
    @IBOutlet private weak var predictedExerciseDetailLabel: UILabel!
    @IBOutlet private weak var runnerUpExerciseNameLabel: UILabel!
    @IBOutlet private weak var runnerUpExerciseDetailLabel: UILabel!
    @IBOutlet private weak var runnerUpScoreLabel: UILabel!
    @IBOutlet private weak var loadingSpinner: UIActivityIndicatorView!

    // MARK: - Exposed Functions

    /// Configures the cell and updates its UI
    ///
    /// - Parameter testResult: The `TestResult` object with information used to update UI
    func configure(with testResult: TestResult) {
        configureResults(testResult)
        configurePrediction(testResult.predictionMeta)
        configureRunnerUp(testResult.runnerUpMeta, runnerUpScore: testResult.runnerUpScore)
        configureLoadingSpinner(testResult.status)
    }

    // MARK: - Private Functions

    private func configureResults(_ testResult: TestResult) {
        exerciseNameLabel.text = "\(testResult.testMeta.exerciseName) " +
        "(\(testResult.testMeta.angle.rawValue.capitalized))"
        exerciseDetailLabel.text = testResult.testMeta.exerciseDetail

        if let correctOverall = testResult.predictedCorrectOverall {
            correctOverallLabel.text = "Correctly\nClassified"
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

    private func configureLoadingSpinner(_ status: TestResult.Status) {
        switch status {
        case .notStarted where loadingSpinner.isAnimating:
            loadingSpinner.stopAnimating()
        case .finished where loadingSpinner.isAnimating:
            loadingSpinner.stopAnimating()
        case .running where !loadingSpinner.isAnimating:
            loadingSpinner.startAnimating()
        default:
            break
        }
    }

}

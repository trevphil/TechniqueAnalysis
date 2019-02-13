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
    @IBOutlet private weak var filenameLabel: UILabel!
    @IBOutlet private weak var correctPredictionLabel: UILabel!
    @IBOutlet private weak var correctPredictionIcon: UILabel!
    @IBOutlet private weak var bestGuessScoreLabel: UILabel!
    @IBOutlet private weak var bestGuessExerciseName: UILabel!
    @IBOutlet private weak var bestGuessExerciseDetail: UILabel!
    @IBOutlet private weak var secondBestScoreLabel: UILabel!
    @IBOutlet private weak var secondBestExerciseName: UILabel!
    @IBOutlet private weak var secondBestExerciseDetail: UILabel!
    @IBOutlet private weak var loadingSpinner: UIActivityIndicatorView!

    // MARK: - Exposed Functions

    /// Configures the cell and updates its UI
    ///
    /// - Parameter testResult: The `TestResult` object with information used to update UI
    func configure(with testResult: TestResult) {
        configureResults(testResult)
        configurePrediction(testResult.bestGuessMeta)
        configureSecondBest(testResult.secondBestMeta, secondBestScore: testResult.secondBestScore)
        configureLoadingSpinner(testResult.status)
    }

    // MARK: - Private Functions

    private func configureResults(_ testResult: TestResult) {
        filenameLabel.text = testResult.filename

        if let correctOverall = testResult.predictedCorrectly {
            correctPredictionLabel.text = "Correctly\nClassified"
            correctPredictionIcon.text = correctOverall ? "✅" : "❌"
        } else {
            correctPredictionLabel.text = ""
            correctPredictionIcon.text = ""
        }

        if let score = testResult.bestGuessScore {
            bestGuessScoreLabel.text = "\(Int(score))"
        } else {
            bestGuessScoreLabel.text = "--"
        }
    }

    private func configurePrediction(_ predictionMeta: TAMeta?) {
        if let predictionMeta = predictionMeta {
            bestGuessExerciseName.text = "\(predictionMeta.exerciseName) " +
            "(\(predictionMeta.angle.rawValue.capitalized))"
            bestGuessExerciseDetail.text = predictionMeta.exerciseDetail
        } else {
            bestGuessExerciseName.text = ""
            bestGuessExerciseDetail.text = ""
        }
    }

    private func configureSecondBest(_ secondBestMeta: TAMeta?, secondBestScore: Double?) {
        if let secondBestMeta = secondBestMeta {
            secondBestExerciseName.text = "\(secondBestMeta.exerciseName) " +
            "(\(secondBestMeta.angle.rawValue.capitalized))"
            secondBestExerciseDetail.text = secondBestMeta.exerciseDetail
        } else {
            secondBestExerciseName.text = ""
            secondBestExerciseDetail.text = ""
        }

        if let secondBestScore = secondBestScore {
            secondBestScoreLabel.text = "\(Int(secondBestScore))"
        } else {
            secondBestScoreLabel.text = "--"
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

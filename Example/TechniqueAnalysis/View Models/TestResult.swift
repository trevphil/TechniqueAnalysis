//
//  TestResult.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 08.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import TechniqueAnalysis

/// Data structure with information about the results of a test case
class TestResult {

    /// The status of the test case
    ///
    /// - notStarted: The test case has not yet started
    /// - running: The test case is in progress (processing)
    /// - finished: The test case has finished and results are available
    enum Status {
        case notStarted, running, finished
    }

    // MARK: - Properties

    /// URL of the video used in the test case
    let url: URL
    /// Metadata extracted from the filename in the original URL
    let testMeta: TAMeta
    /// Metadata of the `TATimeseries` most closely matching that of the test case
    var predictionMeta: TAMeta?
    /// The score of the `TATimeseries` most closely matching that of the test case
    var predictionScore: Double?
    /// Metadata of the `TATimeseries` that came in second place for most closely matching the test case
    var runnerUpMeta: TAMeta?
    /// The score of the `TATimeseries` that came in second place for most closely matching the test case
    var runnerUpScore: Double?
    /// The status of the test case
    var status: Status = .notStarted

    /// `true` if the test case correctly predicted the *exercise name* of the unknown data, and `false` otherwise
    var predictedCorrectExercise: Bool? {
        guard let predictionMeta = predictionMeta else {
            return nil
        }

        return testMeta.exerciseName == predictionMeta.exerciseName
    }

    /// `true` if the test case correctly matched *exactly* the unknown data, and `false` otherwise
    var predictedCorrectOverall: Bool? {
        guard let predictionMeta = predictionMeta, let correctExercise = predictedCorrectExercise else {
            return nil
        }

        return correctExercise && testMeta.exerciseDetail == predictionMeta.exerciseDetail
    }

    // MARK: - Initialization

    /// Create a new instance of `TestResult`
    ///
    /// - Parameters:
    ///   - url: The URL of the video used for the test case
    ///   - testMeta: The metadata of the video referenced by `url`
    init(url: URL, testMeta: TAMeta) {
        self.url = url
        self.testMeta = testMeta
    }

}

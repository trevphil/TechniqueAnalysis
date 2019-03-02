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

    /// The `TATimeseries` with unknown data being tested
    var unknownSeries: TATimeseries?

    /// The best guess from the results of `TAKnnDtw`
    var bestPrediction: TAKnnDtw.Result?

    /// The second best guess from the results of `TAKnnDtw`
    var secondBest: TAKnnDtw.Result?

    /// The status of the test case
    var status: Status = .notStarted

    /// `true` if the test case correctly predicted the unknown data, and `false` otherwise
    var predictedCorrectly: Bool? {
        guard let bestGuessMeta = bestPrediction?.series.meta else {
            return nil
        }

        return testMeta.exerciseName == bestGuessMeta.exerciseName &&
            testMeta.exerciseDetail == bestGuessMeta.exerciseDetail
    }

    /// The name of the unknown video being tested
    var filename: String {
        return url.lastPathComponent
    }

    /// Metadata of the `TATimeseries` most closely matching that of the test case
    var bestGuessMeta: TAMeta? {
        return bestPrediction?.series.meta
    }

    /// Metadata of the `TATimeseries` that came in second place for most closely matching the test case
    var secondBestMeta: TAMeta? {
        return secondBest?.series.meta
    }

    /// Visualization of the Knn DTW cost matrix for the best-guess prediction of the unknown series
    lazy var bestCostMatrix: UIImage? = {
        return UIImage.image(from: bestPrediction?.matrix)
    }()

    /// Visualization of the Knn DTW cost matrix for the second best guess prediction of the unknown series
    lazy var secondBestCostMatrix: UIImage? = {
        return UIImage.image(from: secondBest?.matrix)
    }()

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

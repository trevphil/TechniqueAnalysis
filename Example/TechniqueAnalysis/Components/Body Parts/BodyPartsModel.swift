//
//  BodyPartsModel.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/17/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import TechniqueAnalysis

/// A view model which shows the movement of various body parts through time,
/// for some specific `TATimeseries` object
class BodyPartsModel {

    /// Enum mapping for various `TATimeseries` which can be queried from the model
    ///
    /// - unknown: Choose the unknown timeseries which is being tested
    /// - bestGuess: Choose the best guess for the unknown timeseries
    /// - secondBestGuess: Choose the second best guess for the unknown timeseries
    enum SeriesType {
        case unknown, bestGuess, secondBestGuess
    }

    // MARK: - Properties

    /// The model's title
    let title: String

    private let testResult: TestResult
    private let unknownSeries: TATimeseries

    /// The name of the exercise being examined
    var exerciseName: String {
        return unknownSeries.meta.exerciseName.uppercased()
    }

    /// The number of body parts which will be displayed
    var numBodyParts: Int {
        return TABodyPart.allCases.count
    }

    // MARK: - Initialization

    /// Create a new instance of `BodyPartsModel`
    ///
    /// - Parameters:
    ///   - testResult: The `TestResult` object which should be visualized
    ///   - unknownSeries: The unknown timeseries for the `TestResult`
    init(testResult: TestResult, unknownSeries: TATimeseries) {
        self.title = "Body Parts"
        self.testResult = testResult
        self.unknownSeries = unknownSeries
    }

    // MARK: - Exposed Functions

    /// Determine the point estimates over time for a given body part
    ///
    /// - Parameters:
    ///   - bodyPartIndex: The index of the body part (with respect to the
    ///                    ordered list of all body parts) to be used
    ///   - seriesType: The series from which the data should be derived (e.g. unknown
    ///                 series, best guess, or second best guess)
    /// - Returns: An array of `TAPointEstimate` objects which are ordered sequentially
    ///            through time. Each point estimate is for the same body part.
    func bodyPartOverTime(_ bodyPartIndex: Int, seriesType: SeriesType) -> [TAPointEstimate]? {
        guard let bodyPart = TABodyPart.allCases.element(atIndex: bodyPartIndex) else {
            return nil
        }

        let selectedSeries: TATimeseries?
        switch seriesType {
        case .unknown:
            selectedSeries = unknownSeries
        case .bestGuess:
            selectedSeries = testResult.bestPrediction?.series
        case .secondBestGuess:
            selectedSeries = testResult.secondBest?.series
        }
        guard let series = selectedSeries else {
            return nil
        }

        var pointEstimates = [TAPointEstimate]()
        var time = 0
        var currentSlice = try? series.timeSlice(forSample: time)

        while currentSlice != nil {
            if let point = currentSlice?.first(where: { $0.bodyPart == bodyPart }) {
                pointEstimates.append(point)
            }
            time += 1
            currentSlice = try? series.timeSlice(forSample: time)
        }

        return pointEstimates.isEmpty ? nil : pointEstimates
    }

}

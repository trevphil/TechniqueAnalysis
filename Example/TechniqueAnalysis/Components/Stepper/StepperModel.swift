//
//  StepperModel.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 15.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import TechniqueAnalysis

/// Model which helps visualize the change in body points over time
class StepperModel {

    // MARK: - Properties

    /// The model's title
    let title: String

    private let unknownSeries: TATimeseries
    private let knownSeries: TATimeseries

    /// The name of the exercise being compared
    var exerciseName: String {
        return unknownSeries.meta.exerciseName
    }

    // MARK: - Initialization

    init(unknownSeries: TATimeseries, knownSeries: TATimeseries) {
        self.title = "Stepper"
        self.unknownSeries = unknownSeries
        self.knownSeries = knownSeries
    }

    // MARK: - Exposed Functions

    func unknownSeriesSlice(atTime time: Int) -> TAPoseViewModel? {
        guard let unknown = try? unknownSeries.timeSlice(forSample: time) else {
            return nil
        }

        return TAPoseViewModel(bodyPoints: unknown, confidenceThreshold: Params.minConfidence)
    }

    func knownSeriesSlice(atTime time: Int) -> TAPoseViewModel? {
        guard let known = try? knownSeries.timeSlice(forSample: time) else {
            return nil
        }

        return TAPoseViewModel(bodyPoints: known, confidenceThreshold: Params.minConfidence)
    }

}

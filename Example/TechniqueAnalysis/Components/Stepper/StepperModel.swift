//
//  StepperModel.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 15.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import TechniqueAnalysis

/// A view model which allows the user to "step through time" to see the
/// motion of some unknown timeseries vs. the best guess comparison `TATimeseries`
class StepperModel {

    // MARK: - Properties

    /// The model's title
    let title: String

    private let unknownSeries: TATimeseries
    private let knownSeries: TATimeseries
    private let onShowBodyParts: (() -> Void)?

    /// The name of the exercise being compared
    var exerciseName: String {
        return unknownSeries.meta.exerciseName.uppercased()
    }

    // MARK: - Initialization

    /// Create a new instance of `StepperModel`
    ///
    /// - Parameters:
    ///   - unknownSeries: A `TATimeseries` which we are trying to predict
    ///   - knownSeries: A `TATimeseries` which is the best guess comparison for the unknown
    ///   - onShowBodyParts: A callback which is executed when the user wants to see specific
    ///                      isolated body parts and their movement through time
    init(unknownSeries: TATimeseries,
         knownSeries: TATimeseries,
         onShowBodyParts: (() -> Void)?) {
        self.title = "Stepper"
        self.unknownSeries = unknownSeries
        self.knownSeries = knownSeries
        self.onShowBodyParts = onShowBodyParts
    }

    // MARK: - Exposed Functions

    /// Call this function to let the model know that the user wants to see
    /// specific isolated body parts and their movement through time
    func showBodyParts() {
        onShowBodyParts?()
    }

    /// Creates a `TAPoseViewModel` object for the pose of the *unknown* series at some point in time
    ///
    /// - Parameter time: The time at which we want to determine the user's pose
    /// - Returns: A configured `TAPoseViewModel` for the unknown `TATimeseries`
    func unknownSeriesSlice(atTime time: Int) -> TAPoseViewModel? {
        guard let unknown = try? unknownSeries.timeSlice(forSample: time) else {
            return nil
        }

        return TAPoseViewModel(bodyPoints: unknown, confidenceThreshold: Params.minConfidence)
    }

    /// Creates a `TAPoseViewModel` object for the pose of the *known* series at some point in time
    ///
    /// - Parameter time: The time at which we want to determine the user's pose
    /// - Returns: A configured `TAPoseViewModel` for the known `TATimeseries`
    func knownSeriesSlice(atTime time: Int) -> TAPoseViewModel? {
        guard let known = try? knownSeries.timeSlice(forSample: time) else {
            return nil
        }

        return TAPoseViewModel(bodyPoints: known, confidenceThreshold: Params.minConfidence)
    }

}

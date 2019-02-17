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

    // MARK: - Properties

    /// The model's title
    let title: String

    private let timeseries: TATimeseries

    /// The name of the exercise being examined
    var exerciseName: String {
        return timeseries.meta.exerciseName.uppercased() + " (unknown video)"
    }

    /// The number of body parts which will be displayed
    var numBodyParts: Int {
        return TABodyPart.allCases.count
    }

    // MARK: - Initialization

    /// Create a new instance of `BodyPartsModel`
    ///
    /// - Parameter timeseries: The `TATimeseries` to use when configuring the object
    init(timeseries: TATimeseries) {
        self.timeseries = timeseries
        self.title = "Body Parts"
    }

    // MARK: - Exposed Functions

    /// Determine the point estimates over time for a given body part
    ///
    /// - Parameter bodyPartIndex: The index of the body part (with respect to the
    ///                            ordered list of all body parts) to be used
    /// - Returns: An array of `TAPointEstimate` objects which are ordered sequentially
    ///            through time. Each point estimate is for the same body part.
    func bodyPartOverTime(_ bodyPartIndex: Int) -> [TAPointEstimate]? {
        guard let bodyPart = TABodyPart.allCases.element(atIndex: bodyPartIndex) else {
            return nil
        }

        var pointEstimates = [TAPointEstimate]()
        var time = 0
        var currentSlice = try? timeseries.timeSlice(forSample: time)

        while currentSlice != nil {
            if let point = currentSlice?.first(where: { $0.bodyPart == bodyPart }) {
                pointEstimates.append(point)
            }
            time += 1
            currentSlice = try? timeseries.timeSlice(forSample: time)
        }

        return pointEstimates.isEmpty ? nil : pointEstimates
    }

}

//
//  TAPoseViewModel.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 12/11/18.
//

import Foundation
import CoreML

/// View model used in conjunction with `TAPoseView` to show a user's posture
public struct TAPoseViewModel {

    // MARK: - Properties

    private let confidenceThreshold: Double
    /// An array of `TAPointEstimate` objects, one for each body parts. These objects
    /// are used by `TAPoseView` while rendering content.
    public let bodyPoints: [TAPointEstimate]

    // MARK: - Initialization

    /// Creates a new `TAPoseViewModel` instance
    ///
    /// - Parameters:
    ///   - heatmap: The relevant data for the model. You can use the argument given from
    ///              `TAPoseEstimationDelegate` `visionRequestDidComplete(heatmap:)` to
    ///              initialize a new instance.
    ///   - confidenceThreshold: The minimum confidence allowed. Any point estimates which
    ///                          have a confidence below this threshold will not be rendered.
    /// - Note: Initialization fails if the given heatmap has an incompatible shape
    public init?(heatmap: MLMultiArray, confidenceThreshold: Double = 0.5) {
        guard let converted = TATimeseries.compress(heatmap) else {
            return nil
        }
        self.confidenceThreshold = confidenceThreshold
        self.bodyPoints = converted
    }

    /// Creates a new `TAPoseViewModel` instance
    ///
    /// - Parameters:
    ///   - bodyPoints: An array of point estimates, one for each body part
    ///   - confidenceThreshold: The minimum confidence allowed. Any point estimates which
    ///                          have a confidence below this threshold will not be rendered.
    public init(bodyPoints: [TAPointEstimate], confidenceThreshold: Double = 0.5) {
        self.confidenceThreshold = confidenceThreshold
        self.bodyPoints = bodyPoints.map { estimate in
            let shiftedPoint = CGPoint(x: estimate.point.x + 0.5, y: 1 - (estimate.point.y + 0.5))
            return TAPointEstimate(point: shiftedPoint,
                                   confidence: estimate.confidence,
                                   bodyPart: estimate.bodyPart)
        }
    }

    // MARK: - Exposed Functions

    func point(for bodyPart: TABodyPart) -> TAPointEstimate? {
        return bodyPoints.first(where: { $0.bodyPart == bodyPart && $0.confidence >= confidenceThreshold })
    }

}

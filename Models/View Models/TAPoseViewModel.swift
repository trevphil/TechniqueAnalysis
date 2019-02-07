//
//  TAPoseViewModel.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 12/11/18.
//

import Foundation
import CoreML

public struct TAPoseViewModel {

    // MARK: - Properties

    private let confidenceThreshold: Double
    public let bodyPoints: [TAPointEstimate]

    // MARK: - Initialization

    public init?(heatmap: MLMultiArray, confidenceThreshold: Double = 0.5) {
        guard let converted = TATimeseries.compress(heatmap) else {
            return nil
        }
        self.confidenceThreshold = confidenceThreshold
        self.bodyPoints = converted
    }

    public init(bodyPoints: [TAPointEstimate], confidenceThreshold: Double = 0.5) {
        self.confidenceThreshold = confidenceThreshold
        self.bodyPoints = bodyPoints
    }

    // MARK: - Exposed Functions

    func point(for bodyPart: TABodyPart) -> TAPointEstimate? {
        return bodyPoints.first(where: { $0.bodyPart == bodyPart && $0.confidence >= confidenceThreshold })
    }

}

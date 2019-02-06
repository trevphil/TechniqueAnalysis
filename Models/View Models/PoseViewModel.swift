//
//  PoseViewModel.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 12/11/18.
//

import Foundation
import CoreML

public struct PoseViewModel {

    // MARK: - Properties

    private let confidenceThreshold: Double
    public let bodyPoints: [PointEstimate]

    // MARK: - Initialization

    public init?(heatmap: MLMultiArray, confidenceThreshold: Double = 0.5) {
        guard let converted = CompressedTimeseries.compress(heatmap) else {
            return nil
        }
        self.confidenceThreshold = confidenceThreshold
        self.bodyPoints = converted
    }

    public init(bodyPoints: [PointEstimate], confidenceThreshold: Double = 0.5) {
        self.confidenceThreshold = confidenceThreshold
        self.bodyPoints = bodyPoints
    }

    // MARK: - Exposed Functions

    func point(for bodyPart: BodyPart) -> PointEstimate? {
        return bodyPoints.first(where: { $0.bodyPart == bodyPart && $0.confidence >= confidenceThreshold })
    }

}

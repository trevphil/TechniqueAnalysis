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

    private static let confidenceThreshold: Double = 0.5
    public let bodyPoints: [PointEstimate]

    // MARK: - Initialization

    public init?(heatmap: MLMultiArray) {
        guard let converted = PoseViewModel.convertedHeatmap(heatmap) else {
            return nil
        }
        self.bodyPoints = converted
    }

    // MARK: - Exposed Functions

    func point(for bodyPart: BodyPart, threshold: Double = PoseViewModel.confidenceThreshold) -> PointEstimate? {
        return bodyPoints.first(where: { $0.bodyPart == bodyPart && $0.confidence >= threshold })
    }

    // MARK: - Private Functions

    private static func convertedHeatmap(_ heatmap: MLMultiArray) -> [PointEstimate]? {
        guard heatmap.shape.count >= 3 else {
            print("ERROR: - Heatmap shape (\(heatmap.shape)) is invalid")
            return nil
        }

        let numBodyPoints = heatmap.shape[0].intValue
        let height = heatmap.shape[1].intValue
        let width = heatmap.shape[2].intValue
        let placeholder = PointEstimate(point: .zero, confidence: -1, bodyPart: nil)
        var bodyPoints: [PointEstimate] = Array(repeating: placeholder, count: numBodyPoints)

        for pointIndex in 0..<numBodyPoints {
            for row in 0..<height {
                for col in 0..<width {
                    let index = (pointIndex * height * width) + (row * width) + col
                    let confidence = heatmap[index].doubleValue
                    guard confidence > 0 else {
                        continue
                    }

                    let currentEstimate = bodyPoints.element(atIndex: pointIndex)
                    let shouldReplace = (currentEstimate?.confidence ?? -1) < confidence
                    if shouldReplace {
                        let point = CGPoint(x: CGFloat(col), y: CGFloat(row))
                        bodyPoints[pointIndex] = PointEstimate(point: point,
                                                               confidence: confidence,
                                                               bodyPart: BodyPart(rawValue: pointIndex))
                    }
                }
            }
        }

        return normalize(bodyPoints, maxWidth: width, maxHeight: height)
    }

    private static func normalize(_ points: [PointEstimate], maxWidth: Int, maxHeight: Int) -> [PointEstimate] {
        let result = points.map { point -> PointEstimate? in
            guard point.confidence >= 0 else {
                return nil
            }

            // Add 0.5 to align points "in between" 1-unit step size
            let newPoint = CGPoint(x: (point.point.x + 0.5) / CGFloat(maxWidth),
                                   y: (point.point.y + 0.5) / CGFloat(maxHeight))
            return PointEstimate(point: newPoint, confidence: point.confidence, bodyPart: point.bodyPart)
        }

        return result.compactMap { $0 }
    }

}

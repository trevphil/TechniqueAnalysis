//
//  TATimeseries.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 1/26/19.
//

import Foundation
import CoreML

public enum TATimeseriesError: Error {
    case invalidShapeError(String)
    case indexOutOfBoundsError(String)
}

public struct TATimeseries: Codable {

    // MARK: - Properties

    public let data: [[TAPointEstimate]]
    public let meta: TAMeta

    public var numSamples: Int {
        return data.count
    }

    public var reflected: TATimeseries? {
        guard let oppositeAngle = meta.angle.opposite else {
            return nil
        }

        let oppositeMeta = TAMeta(isLabeled: meta.isLabeled,
                                  exerciseName: meta.exerciseName,
                                  exerciseDetail: meta.exerciseDetail,
                                  angle: oppositeAngle)

        var reflections = [[TAPointEstimate]]()
        for sample in data {
            let flippedPoints: [TAPointEstimate] = sample.map { pointEstimate in
                let flippedPoint = CGPoint(x: 1.0 - pointEstimate.point.x, y: pointEstimate.point.y)
                return TAPointEstimate(point: flippedPoint,
                                     confidence: pointEstimate.confidence,
                                     bodyPart: pointEstimate.bodyPart)
            }
            reflections.append(flippedPoints)
        }

        return try? TATimeseries(data: reflections, meta: oppositeMeta)
    }

    // MARK: - Initialization

    public init(data: [MLMultiArray], meta: TAMeta) throws {
        let compressed = data.compactMap { TATimeseries.compress($0) }
        let validData = compressed.count > 0 && compressed.count == data.count

        guard validData else {
            let message = "Timeseries initialized with invalid MLMultiArrays"
            throw TATimeseriesError.invalidShapeError(message)
        }

        self.data = compressed
        self.meta = meta
    }

    public init(data: [[TAPointEstimate]], meta: TAMeta) throws {
        guard data.count > 0 else {
            let message = "Timeseries initialized with empty data"
            throw TATimeseriesError.invalidShapeError(message)
        }

        self.data = data
        self.meta = meta
    }

    // MARK: - Public Functions

    public func timeSlice(forSample index: Int) throws -> [TAPointEstimate] {
        guard let slice = data.element(atIndex: index) else {
            let message = "Index \(index) is not within the number of samples for the timeseries"
            throw TATimeseriesError.indexOutOfBoundsError(message)
        }

        return slice
    }

    // MARK: - Exposed Functions

    static func compress(_ heatmap: MLMultiArray) -> [TAPointEstimate]? {
        guard validHeatmap(heatmap, expectedShape: TAPoseEstimationModel.ModelType.cpm.outputShape) ||
            validHeatmap(heatmap, expectedShape: TAPoseEstimationModel.ModelType.hourglass.outputShape) else {
            return nil
        }

        let numBodyPoints = heatmap.shape[0].intValue
        let height = heatmap.shape[1].intValue
        let width = heatmap.shape[2].intValue
        let placeholder = TAPointEstimate(point: .zero, confidence: -1, bodyPart: nil)
        var bodyPoints: [TAPointEstimate] = Array(repeating: placeholder, count: numBodyPoints)

        for pointIndex in 0..<numBodyPoints {
            for row in 0..<height {
                for col in 0..<width {
                    let index = (pointIndex * height * width) + (row * width) + col
                    let confidence = heatmap[index].doubleValue
                    let currentEstimate = bodyPoints.element(atIndex: pointIndex)
                    let shouldReplace = (currentEstimate?.confidence ?? -1) < confidence
                    if shouldReplace {
                        let point = CGPoint(x: CGFloat(col), y: CGFloat(row))
                        bodyPoints[pointIndex] = TAPointEstimate(point: point,
                                                               confidence: confidence,
                                                               bodyPart: TABodyPart(rawValue: pointIndex))
                    }
                }
            }
        }

        return normalize(bodyPoints, maxWidth: width, maxHeight: height)
    }

    // MARK: - Private Functions

    private static func normalize(_ points: [TAPointEstimate], maxWidth: Int, maxHeight: Int) -> [TAPointEstimate] {
        return points.map { point -> TAPointEstimate in
            // Add 0.5 to align points "in between" 1-unit step size
            let newPoint = CGPoint(x: (point.point.x + 0.5) / CGFloat(maxWidth),
                                   y: (point.point.y + 0.5) / CGFloat(maxHeight))
            return TAPointEstimate(point: newPoint, confidence: point.confidence, bodyPart: point.bodyPart)
        }
    }

    private static func validHeatmap(_ heatmap: MLMultiArray, expectedShape: [Int]) -> Bool {
        return heatmap.shape.count == 3 && heatmap.shape.map({ $0.intValue }) == expectedShape
    }

}

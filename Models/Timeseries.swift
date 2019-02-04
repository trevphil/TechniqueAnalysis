//
//  Timeseries.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 1/26/19.
//

import Foundation
import CoreML

private func validHeatmap(_ heatmap: MLMultiArray, expectedShape: [Int]) -> Bool {
    return heatmap.shape.count == 3 && heatmap.shape.map({ $0.intValue }) == expectedShape
}

public enum TimeseriesError: Error {
    case invalidShapeError(String)
    case indexOutOfBoundsError(String)
}

public struct Timeseries {

    // MARK: - Properties

    public let data: [MLMultiArray]
    public let meta: Meta

    public var numSamples: Int {
        return data.count
    }

    // MARK: - Initialization

    public init(data: [MLMultiArray], meta: Meta) throws {
        let validData = data.count > 0 && data.map({ validHeatmap($0, expectedShape: [14, 96, 96]) })
            .reduce(true) { (previous, current) -> Bool in
                return previous && current
        }

        guard validData else {
            let message = "Timeseries initialized with invalid MLMultiArrays"
            throw TimeseriesError.invalidShapeError(message)
        }

        self.data = data
        self.meta = meta
    }

    // MARK: - Public Functions

    public func timeSlice(forSample index: Int) throws -> MLMultiArray {
        guard let slice = data.element(atIndex: index) else {
            let message = "Index \(index) is not within the number of samples for the timeseries"
            throw TimeseriesError.indexOutOfBoundsError(message)
        }

        return slice
    }

}

public struct CompressedTimeseries {

    // MARK: - Properties

    public let data: [[PointEstimate]]
    public let meta: Meta

    public var numSamples: Int {
        return data.count
    }

    // MARK: - Initialization

    public init(data: [MLMultiArray], meta: Meta) throws {
        let compressed = data.compactMap { CompressedTimeseries.compress($0) }
        let validData = compressed.count > 0 && compressed.count == data.count

        guard validData else {
            let message = "Timeseries initialized with invalid MLMultiArrays"
            throw TimeseriesError.invalidShapeError(message)
        }

        self.data = compressed
        self.meta = meta
    }

    // MARK: - Public Functions

    public func timeSlice(forSample index: Int) throws -> [PointEstimate] {
        guard let slice = data.element(atIndex: index) else {
            let message = "Index \(index) is not within the number of samples for the timeseries"
            throw TimeseriesError.indexOutOfBoundsError(message)
        }

        return slice
    }

    // MARK: - Exposed Functions

    static func compress(_ heatmap: MLMultiArray) -> [PointEstimate]? {
        guard validHeatmap(heatmap, expectedShape: [14, 96, 96]) else {
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

    // MARK: - Private Functions

    private static func normalize(_ points: [PointEstimate], maxWidth: Int, maxHeight: Int) -> [PointEstimate] {
        return points.map { point -> PointEstimate in
            // Add 0.5 to align points "in between" 1-unit step size
            let newPoint = CGPoint(x: (point.point.x + 0.5) / CGFloat(maxWidth),
                                   y: (point.point.y + 0.5) / CGFloat(maxHeight))
            return PointEstimate(point: newPoint, confidence: point.confidence, bodyPart: point.bodyPart)
        }
    }

}

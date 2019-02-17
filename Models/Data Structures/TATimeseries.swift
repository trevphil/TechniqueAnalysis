//
//  TATimeseries.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 1/26/19.
//

import Foundation
import CoreML

/// Error condition thrown by `TATimeseries`
public enum TATimeseriesError: Error {
    case invalidShapeError(String)
    case indexOutOfBoundsError(String)
}

/// The core unit of computation for algorithmic operations comparing various timeseries.
/// Each `TATimeseries` can be thought of as mapping to a video of a user performing some
/// exercise, and once the video has been processed, relevant data about body posture is *here*.
public struct TATimeseries: Codable {

    // MARK: - Properties

    /// The timeseries data, a 2D array where each outer index represents a sample point in time
    /// and gives an array of `TAPointEstimate` objects. Thus, each inner index is an array with
    /// data about the position and confidence level of various body parts at a point in time.
    public let data: [[TAPointEstimate]]

    /// Metadata about the timeseries. Useful for tracking if it is labeled or unlabeled data,
    /// as well as the exercise name, camera angle, etc.
    public let meta: TAMeta

    /// The number of time samples contained in this `TATimeseries` object
    public var numSamples: Int {
        return data.count
    }

    /// Attempts to generate a new timeseries reflected across the y-axis if the camera angle of
    /// the current timeseries is `left` or `right`
    ///
    /// - Note: This is useful, for example, because when constructing a labeled data set, you
    ///         need only get data for either `left` or `right` and then take the reflection to
    ///         get the opposite camera angle as well
    public var reflected: TATimeseries? {
        guard let oppositeAngle = meta.angle.oppositeSide else {
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

    /// Create a new `TATimeseries` object
    ///
    /// - Parameters:
    ///   - data: An array of `MLMultiArray` objects derived from CoreVision requests
    ///           using the CPM or Hourglass ML models, with data about a user's posture
    ///   - meta: Metadata describing the timeseries to be created
    /// - Throws: `TATimeseriesError` if the `MLMultiArray`s had an invalid shape
    public init(data: [MLMultiArray], meta: TAMeta) throws {
        let compressed = data.compactMap { TATimeseries.compress($0) }
        let fitted = TATimeseries.fit(compressed)
        let validData = fitted.count > 0 && fitted.count == data.count

        guard validData else {
            let message = "Timeseries initialized with invalid MLMultiArrays"
            throw TATimeseriesError.invalidShapeError(message)
        }

        self.data = fitted
        self.meta = meta
    }

    /// Create a new `TATimeseries` object
    ///
    /// - Parameters:
    ///   - data: A 2D array where each outer index is a point in time, and each inner array
    ///           is an array of `TAPointEstimate` objects for various body parts
    ///   - meta: Metadata describing the timeseries to be created
    /// - Throws: `TATimeseriesError` if `data` is empty
    public init(data: [[TAPointEstimate]], meta: TAMeta) throws {
        let fitted = TATimeseries.fit(data)
        guard fitted.count > 0 else {
            let message = "Timeseries initialized with empty data"
            throw TATimeseriesError.invalidShapeError(message)
        }

        self.data = fitted
        self.meta = meta
    }

    // MARK: - Public Functions

    /// Retrieves a "time slice" at a point in time of the predicted locations of a user's body points
    ///
    /// - Parameter index: The sample point in time
    /// - Returns: An array of `TAPointEstimate` objects, one for each body point predicted by ML
    /// - Throws: `TATimeseriesError` if the requested sample time is out of bounds
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

    private static func fit(_ data: [[TAPointEstimate]]) -> [[TAPointEstimate]] {

        // Flip order of 2D matrix so that outer index gives an array of `TAPointEstimate`
        // objects which all have the same body part (ordered sequentially through time)
        func tuple(for bodyPartIndex: Int) -> ([CGFloat], [CGFloat], [TAPointEstimate]) {
            let estimates = data.compactMap({ $0.element(atIndex: bodyPartIndex) })
            let xValues = estimates.map { $0.point.x }
            let yValues = estimates.map { $0.point.y }
            return (xValues, yValues, estimates)
        }

        let loess = TALoess()
        let bodyPartArrays: [[TAPointEstimate]] = (0..<TABodyPart.allCases.count).map { index in
            let tup = tuple(for: index)
            let xFitted = loess.fit(data: tup.0)
            let yFitted = loess.fit(data: tup.1)
            let bodyPartEstimates = tup.2
            return bodyPartEstimates.enumerated().compactMap { sampleIdx, estimate in
                guard let xVal = xFitted.element(atIndex: sampleIdx),
                    let yVal = yFitted.element(atIndex: sampleIdx) else {
                        return nil
                }

                return TAPointEstimate(point: CGPoint(x: xVal, y: yVal),
                                       confidence: estimate.confidence,
                                       bodyPart: estimate.bodyPart)
            }
        }

        // Flip order of 2D matrix again so that the outer index gives an array of `TAPointEstimate`
        // objects, with 1 element each per body part
        let numTimeSamples = bodyPartArrays.element(atIndex: 0)?.count ?? 0
        return (0..<numTimeSamples).map { timeIndex in
            return bodyPartArrays.compactMap { $0.element(atIndex: timeIndex) }
        }
    }

}

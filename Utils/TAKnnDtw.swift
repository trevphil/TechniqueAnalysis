//
//  TAKnnDtw.swift
//  TechniqueAnalysis
//
//  Created by Trevor on 05.02.19.
//

import Foundation

/// Error condition thrown by `TAKnnDtw`
public enum TAKnnDtwError: Error {
    case emptyArrayError
    case shapeMismatchError
    case lowConfidenceError
}

/// A wrapper struct for using the k-Nearest Neighbor (kNN)
/// Dynamic Time Warping (DTW) algorithm with configurable parameters
public struct TAKnnDtw {

    /// Data structure storing a result from the kNN DTW algorithm
    public struct Result {
        /// The "distance score" of an unknown series relative to the `series` property.
        /// A lower value implies a closer distance (and thus, closer match to the unknown).
        public let score: Double
        /// The `TATimeseries` which was compared to an unknown series and which the
        /// `score` and `matrix` parameters are referencing.
        public let series: TATimeseries

        /// Create a new instance of `Result`
        ///
        /// - Parameters:
        ///   - score: The "distance score" of an unknown series relative to the `series` property.
        ///            A lower value implies a closer distance (and thus, closer match to the unknown).
        ///   - series: The `TATimeseries` which was compared to an unknown series and which the
        ///             `score` and `matrix` parameters are referencing.
        public init(score: Double, series: TATimeseries) {
            self.score = score
            self.series = series
        }
    }

    // MARK: - Properties

    /// The warping window used by the algorithm. Smaller values imply a closer fit
    /// between the timeseries being compared and will speed up runtime. Smaller values
    /// may also actually improve algorithm accuracy (up to a point, otherwise accuracy
    /// begins to degrade quite rapidly).
    public let warpingWindow: Int
    
    /// The minimum average confidence allowed for a body part in a `TATimeseries`. If the average
    /// confidence (sampled over time) for the body part falls short of this threshold, the body
    /// part will not be included in the kNN DTW comparison.
    public let minConfidence: Double

    // MARK: - Initialization

    /// Create a new instance of the kNN DTW algorithm
    ///
    /// - Parameters:
    ///   - warpingWindow: The warping window used by the algorithm
    ///   - minConfidence: The minimum average confidence allowed for a body part in a `TATimeseries`
    public init(warpingWindow: Int, minConfidence: Double) {
        self.warpingWindow = warpingWindow
        self.minConfidence = minConfidence
    }

    // MARK: - Public Functions

    /// Determine the distances between some unknown timeseries and an array of known items
    ///
    /// - Parameters:
    ///   - unknownItem: The `TATimeseries` object which will be compared with `knownItems`
    ///   - knownItems: An array of labeled, known data (`TATimeseries` objects)
    ///   - relevantBodyParts: A list of body parts which should be considered when computing the distances
    ///                        between timeseries. All other body parts will be ignored. By omitting this
    ///                        parameter, all body parts will be considered.
    /// - Returns: Returns an array of `Result` objects, each of which maps to an item from the original
    ///            `knownItems` parameter.
    ///            The returned array is sorted from smallest to greatest score. Lower score implies closer distance.
    /// - Warning: This function will likely take non-trivial time to execute (depending on the number of items
    ///            passed in `knownItems`), so you probably want to execute this off of the main queue.
    public func nearestNeighbors(unknownItem: TATimeseries,
                                 knownItems: [TATimeseries],
                                 relevantBodyParts: [TABodyPart] = TABodyPart.allCases) -> [Result] {
        var rankings = [Result]()
        
        for known in knownItems {
            do {
                let score = try distance(timeseriesA: unknownItem,
                                         timeseriesB: known,
                                         relevantBodyParts: relevantBodyParts)
                rankings.append(Result(score: score, series: known))
            } catch {
                print("Error while comparing timeseries: \(error)")
            }
        }

        return rankings.sorted(by: { $0.score < $1.score })
    }

    // MARK: - Private Functions

    private func distance(timeseriesA: TATimeseries,
                          timeseriesB: TATimeseries,
                          relevantBodyParts: [TABodyPart]) throws -> Double {

        let raw = relevantBodyParts.map { $0.rawValue }
        let avgConfidencesA = averageConfidences(timeseriesA)
            .enumerated().compactMap({ raw.contains($0) ? $1 : nil })
        let avgConfidencesB = averageConfidences(timeseriesB)
            .enumerated().compactMap({ raw.contains($0) ? $1 : nil })

        guard avgConfidencesA.count == avgConfidencesB.count else {
            throw TAKnnDtwError.shapeMismatchError
        }

        let distances: [Double] = try relevantBodyParts.map { bodyPart in
            let pointsA = timeseriesA.bodyPartOverTime(bodyPart)
            let pointsB = timeseriesB.bodyPartOverTime(bodyPart)
            return try distance(pointEstimatesA: pointsA, pointEstimatesB: pointsB)
        }

        guard distances.count == avgConfidencesA.count else {
            throw TAKnnDtwError.shapeMismatchError
        }

        let filtered = distances
            .enumerated()
            .compactMap({ avgConfidencesA[$0] >= minConfidence && avgConfidencesB[$0] >= minConfidence ? $1 : nil })
            .reduce(0, +)

        guard filtered != 0 else {
            // All of the relevant body parts had an average confidence below the threshold,
            // so no relevant data was able to be extracted
            throw TAKnnDtwError.lowConfidenceError
        }
        return filtered
    }

    private func distance(pointEstimatesA: [TAPointEstimate],
                          pointEstimatesB: [TAPointEstimate]) throws -> Double {
        let numRows = pointEstimatesA.count
        let numCols = pointEstimatesB.count
        let sampleCol = Array(repeating: Double.greatestFiniteMagnitude, count: numCols)
        var cost = Array(repeating: sampleCol, count: numRows)

        guard let firstA = pointEstimatesA.element(atIndex: 0),
            let firstB = pointEstimatesB.element(atIndex: 0) else {
                throw TAKnnDtwError.emptyArrayError
        }

        cost[0][0] = distance(pointA: firstA, pointB: firstB)

        for rowIndex in 1..<numRows {
            let pointA = pointEstimatesA[rowIndex]
            let dist = distance(pointA: pointA, pointB: firstB)
            cost[rowIndex][0] = cost[rowIndex - 1][0] + dist
        }

        for colIndex in 1..<numCols {
            let pointB = pointEstimatesB[colIndex]
            let dist = distance(pointA: firstA, pointB: pointB)
            cost[0][colIndex] = cost[0][colIndex - 1] + dist
        }

        for row in 1..<numRows {
            for col in max(1, row - warpingWindow)..<min(numCols, row + warpingWindow) {
                let choices = [
                    cost[row - 1][col - 1],
                    cost[row][col - 1],
                    cost[row - 1][col]
                ]
                let pointA = pointEstimatesA[row]
                let pointB = pointEstimatesB[col]
                let dist = distance(pointA: pointA, pointB: pointB)
                cost[row][col] = (choices.min() ?? 0) + dist
            }
        }

        return cost.last?.last ?? Double.greatestFiniteMagnitude
    }

    private func distance(pointA: TAPointEstimate, pointB: TAPointEstimate) -> Double {
        let xDistSquared = pow(pointB.point.x - pointA.point.x, 2)
        let yDistSquared = pow(pointB.point.y - pointA.point.y, 2)
        return Double(sqrt(xDistSquared + yDistSquared))
    }

    private func averageConfidences(_ timeseries: TATimeseries) -> [Double] {
        return TABodyPart.allCases.map {
            let points = timeseries.bodyPartOverTime($0)
            let confidenceSum = points.map({ $0.confidence }).reduce(0, +)
            return confidenceSum / Double(points.count)
        }
    }

}

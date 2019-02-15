//
//  TAKnnDtw.swift
//  TechniqueAnalysis
//
//  Created by Trevor on 05.02.19.
//

import Foundation

/// Error condition thrown by `TAKnnDtw`
public enum TAKnnDtwError: Error {
    case shapeMismatchError
}

/// A wrapper struct for using the k-Nearest Neighbor (kNN)
/// Dynamic Time Warping (DTW) algorithm with configurable parameters
public struct TAKnnDtw {

    // MARK: - Properties

    /// The warping window used by the algorithm. Smaller values imply a closer fit
    /// between the timeseries being compared and will speed up runtime. Smaller values
    /// may also actually improve algorithm accuracy (up to a point, otherwise accuracy
    /// begins to degrade quite rapidly).
    public let warpingWindow: Int
    
    /// The minimum confidence allowed for two `TAPointEstimate` objects being compared
    /// by the algorithm. If either point falls short of the threshold, the comparison
    /// is discarded.
    public let minConfidence: Double

    // MARK: - Initialization

    /// Create a new instance of the kNN DTW algorithm
    ///
    /// - Parameters:
    ///   - warpingWindow: The warping window used by the algorithm
    ///   - minConfidence: The minimum confidence allowed for two `TAPointEstimate` objects being compared by the algorithm.
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
    /// - Returns: Returns an array containing tuples where each tuple maps to an item from the original
    ///            `knownItems` parameter plus its score with respect to "distance" from the unknown series.
    ///            The returned array is sorted from smallest to greatest score. Lower score implies closer distance.
    /// - Warning: This function will likely take non-trivial time to execute (depending on the number of items
    ///            passed in `knownItems`), so you probably want to execute this off of the main queue.
    public func nearestNeighbors(unknownItem: TATimeseries,
                                 knownItems: [TATimeseries],
                                 relevantBodyParts: [TABodyPart] = TABodyPart.allCases)
        -> [(score: Double, series: TATimeseries, matrix: [[Double]])] {
        let bodyPartsRaw = relevantBodyParts.map { $0.rawValue }
        var rankings = [(score: Double, series: TATimeseries, matrix: [[Double]])]()
        
        for known in knownItems {
            do {
                let result = try distance(timeseriesA: unknownItem, timeseriesB: known, relevantBodyParts: bodyPartsRaw)
                rankings.append((result.score, known, result.matrix))
            } catch {
                print("Error while comparing timeseries: \(error)")
            }
        }

        return rankings.sorted(by: { $0.score < $1.score })
    }

    // MARK: - Private Functions

    private func distance(timeseriesA: TATimeseries,
                          timeseriesB: TATimeseries,
                          relevantBodyParts: [Int]) throws -> (score: Double, matrix: [[Double]]) {
        let numRows = timeseriesA.numSamples
        let numCols = timeseriesB.numSamples
        let sampleCol = Array(repeating: Double.greatestFiniteMagnitude, count: numCols)
        var cost = Array(repeating: sampleCol, count: numRows)

        let firstSliceA = try timeseriesA.timeSlice(forSample: 0)
        let firstSliceB = try timeseriesB.timeSlice(forSample: 0)
        cost[0][0] = try distance(sliceA: firstSliceA, sliceB: firstSliceB, relevantBodyParts: relevantBodyParts)

        for rowIndex in 1..<numRows {
            let sliceA = try timeseriesA.timeSlice(forSample: rowIndex)
            let dist = try distance(sliceA: sliceA, sliceB: firstSliceB, relevantBodyParts: relevantBodyParts)
            cost[rowIndex][0] = cost[rowIndex - 1][0] + dist
        }

        for colIndex in 1..<numCols {
            let sliceB = try timeseriesB.timeSlice(forSample: colIndex)
            let dist = try distance(sliceA: firstSliceA, sliceB: sliceB, relevantBodyParts: relevantBodyParts)
            cost[0][colIndex] = cost[0][colIndex - 1] + dist
        }

        for row in 1..<numRows {
            for col in max(1, row - warpingWindow)..<min(numCols, row + warpingWindow) {
                let choices = [
                    cost[row - 1][col - 1],
                    cost[row][col - 1],
                    cost[row - 1][col]
                ]
                let sliceA = try timeseriesA.timeSlice(forSample: row)
                let sliceB = try timeseriesB.timeSlice(forSample: col)
                let dist = try distance(sliceA: sliceA, sliceB: sliceB, relevantBodyParts: relevantBodyParts)
                cost[row][col] = (choices.min() ?? 0) + dist
            }
        }

        return (cost.last?.last ?? Double.greatestFiniteMagnitude, cost)
    }

    private func distance(sliceA: [TAPointEstimate],
                          sliceB: [TAPointEstimate],
                          relevantBodyParts: [Int]) throws -> Double {
        guard sliceA.count == sliceB.count else {
            throw TAKnnDtwError.shapeMismatchError
        }

        let numBodyPoints = sliceA.count
        var distances = [Double]()
        for bodyPoint in 0..<numBodyPoints {
            guard relevantBodyParts.contains(bodyPoint) else {
                continue
            }

            let pointA = sliceA[bodyPoint]
            let pointB = sliceB[bodyPoint]
            let dist = distance(pointA: pointA, pointB: pointB)
            distances.append(dist)
        }

        let validNums = distances.filter { !$0.isNaN }
        let nanFill = validNums.max() ?? 1.0
        distances = distances.map { $0.isNaN ? nanFill : $0 }
        return distances.reduce(0, +)
    }

    private func distance(pointA: TAPointEstimate, pointB: TAPointEstimate) -> Double {
        let euclideanDistance = Double(sqrt(pow(pointB.point.x - pointA.point.x, 2) +
            pow(pointB.point.y - pointA.point.y, 2)))
        return pointA.confidence >= minConfidence && pointB.confidence >= minConfidence ?
            euclideanDistance : Double.nan
    }

}

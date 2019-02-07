//
//  TAKnnDtw.swift
//  TechniqueAnalysis
//
//  Created by Trevor on 05.02.19.
//

import Foundation

public enum TAKnnDtwError: Error {
    case shapeMismatchError
}

public struct TAKnnDtw {

    // MARK: - Properties

    public let warpingWindow: Int
    public let minConfidence: Double

    // MARK: - Initialization

    public init(warpingWindow: Int, minConfidence: Double) {
        self.warpingWindow = warpingWindow
        self.minConfidence = minConfidence
    }

    // MARK: - Public Functions

    public func nearestNeighbor(unknownItem: TATimeseries,
                                knownItems: [TATimeseries]) -> (score: Double, timeseries: TATimeseries)? {
        var bestScore = Double.greatestFiniteMagnitude
        var closestSeries: TATimeseries?

        for known in knownItems {
            do {
                let score = try distance(timeseriesA: unknownItem, timeseriesB: known)
                if score < bestScore {
                    bestScore = score
                    closestSeries = known
                }
            } catch {
                print("Error while comparing timeseries: \(error)")
            }
        }

        if let closest = closestSeries {
            return (bestScore, closest)
        } else {
            return nil
        }
    }

    // MARK: - Private Functions

    private func distance(timeseriesA: TATimeseries, timeseriesB: TATimeseries) throws -> Double {
        let numRows = timeseriesA.numSamples
        let numCols = timeseriesB.numSamples
        let sampleCol = Array(repeating: Double.greatestFiniteMagnitude, count: numCols)
        var cost = Array(repeating: sampleCol, count: numRows)

        let firstSliceA = try timeseriesA.timeSlice(forSample: 0)
        let firstSliceB = try timeseriesB.timeSlice(forSample: 0)
        cost[0][0] = try distance(sliceA: firstSliceA, sliceB: firstSliceB)

        for rowIndex in 1..<numRows {
            let sliceA = try timeseriesA.timeSlice(forSample: rowIndex)
            let dist = try distance(sliceA: sliceA, sliceB: firstSliceB)
            cost[rowIndex][0] = cost[rowIndex - 1][0] + dist
        }

        for colIndex in 1..<numCols {
            let sliceB = try timeseriesB.timeSlice(forSample: colIndex)
            let dist = try distance(sliceA: firstSliceA, sliceB: sliceB)
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
                let dist = try distance(sliceA: sliceA, sliceB: sliceB)
                cost[row][col] = (choices.min() ?? 0) + dist
            }
        }

        return cost.last?.last ?? Double.greatestFiniteMagnitude
    }

    private func distance(sliceA: [TAPointEstimate], sliceB: [TAPointEstimate]) throws -> Double {
        guard sliceA.count == sliceB.count else {
            throw TAKnnDtwError.shapeMismatchError
        }

        let numBodyPoints = sliceA.count
        var distances = Array(repeating: 0.0, count: numBodyPoints)
        for bodyPoint in 0..<numBodyPoints {
            let pointA = sliceA[bodyPoint]
            let pointB = sliceB[bodyPoint]
            let dist = distance(pointA: pointA, pointB: pointB)
            distances.append(dist)
        }

        let validNums = distances.filter { !$0.isNaN }
        let nanFill = validNums.max() ?? Double.greatestFiniteMagnitude
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

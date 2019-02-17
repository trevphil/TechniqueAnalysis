//
//  TALoess.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 2/17/19.
//

import Foundation

struct TALoess {

    // Explanatory variable = index of the data in the array (assumed to be "time units")
    // Dependent variable = value of some element at an index

    // MARK: - Properties

    let bandwidthPercent: CGFloat = 0.35 // recommended between 0.25-0.50

    // MARK: - Exposed Functions

    func fit(data: [CGFloat]) -> [CGFloat] {
        var fittedData = [CGFloat]()

        for point in 0..<data.count {
            let bounds = dataSubset(around: point, totalDataPoints: data.count)
            guard bounds.lower <= bounds.upper else { continue }
            
            var xValues = [CGFloat]()
            var yValues = [CGFloat]()
            var weights = [CGFloat]()

            for sample in bounds.lower...bounds.upper {
                xValues.append(CGFloat(sample))
                yValues.append(data[sample])
                // let sampleWeight = weight(for: sample, relativeTo: point, bounds: bounds)
                // TODO: - weights.append(sampleWeight)
                weights.append(1.0)
            }

            let linReg = weightedLinReg(xValues, yValues, weights)
            let estimate = linReg(CGFloat(point))
            fittedData.append(estimate)
        }

        return fittedData
    }

    // MARK: - Private Functions

    private func dataSubset(around index: Int, totalDataPoints: Int) -> (lower: Int, upper: Int) {
        let bandwidth = Int(ceil(CGFloat(totalDataPoints) * bandwidthPercent))
        let minIndex = max(0, index - bandwidth / 2)
        let remaining = bandwidth - (index - minIndex)
        let maxIndex = min(totalDataPoints - 1, index + remaining)
        return (minIndex, maxIndex - 1)
    }

    private func weight(for neighborIndex: Int,
                        relativeTo referenceIndex: Int,
                        bounds: (lower: Int, upper: Int)) -> CGFloat {
        // Tri-cube weight function:
        //
        // The weight for a specific point in any localized subset of data is obtained by evaluating
        // the weight function at the distance between that point and the point of estimation,
        // after scaling the distance so that the maximum absolute distance over all of the points
        // in the subset of data is exactly one.
        //
        // https://www.itl.nist.gov/div898/handbook/pmd/section1/pmd144.htm#tcwf

        let absoluteMaxDist = CGFloat(max(abs(referenceIndex - bounds.lower),
                                          abs(bounds.upper - referenceIndex)))
        let scaledDistance = CGFloat(abs(neighborIndex - referenceIndex)) / absoluteMaxDist
        return scaledDistance >= 1 ? 0 : pow(1.0 - pow(scaledDistance, 3), 3)
    }

    private func weightedLinReg(_ xValues: [CGFloat],
                                _ yValues: [CGFloat],
                                _ weights: [CGFloat]) -> (CGFloat) -> CGFloat {

        func average(_ input: [CGFloat]) -> CGFloat {
            return input.reduce(0, +) / CGFloat(input.count)
        }

        func multiply(_ first: [CGFloat], _ second: [CGFloat]) -> [CGFloat] {
            return zip(first, second).map(*)
        }

        let covarianceXY = average(multiply(yValues, xValues)) - average(xValues) * average(yValues)
        let varianceX = average(multiply(xValues, xValues)) - pow(average(xValues), 2)
        let slope = covarianceXY / varianceX
        let intercept = average(yValues) - slope * average(xValues)
        return { xValue in intercept + slope * xValue }
    }

}

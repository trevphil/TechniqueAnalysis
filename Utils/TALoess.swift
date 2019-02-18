//
//  TALoess.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 2/17/19.
//

import Foundation

/// A utility for fitting a smoothed curve between two variables, using a procedure called *LOESS*
/// (LOcally wEighted Scatter-plot Smoother). The implementation here uses a polynomial of degree
/// one for regression (i.e., locally weighted linear regression).
///
/// Each input point is mapped to an output point by taking nearby points and weighting them based
/// on how close they are to the current point being considered. With these neighbor points and their
/// respective weights, we perform a weighted linear regression and evaluate the line of best fit
/// at the current point being considered. This is the smoothed estimate we use as as output point.
struct TALoess {

    // MARK: - Properties

    private let bandwidthPercent: CGFloat

    // MARK: - Initialization

    /// Create a new instance of `TALoess`
    ///
    /// - Parameter bandwidthPercent: This is the percentage of total data points which will be used
    ///                               as a subset when we decide which points to use for performing
    ///                               a weighted linear regression on a particular point. As a rule
    ///                               of thumb, this value should generally be between `0.25-0.50`.
    /// - Note: For example, say there are 100 data points, we are considering point 50, and
    ///         `bandwidthPercent = 0.30`. Then points 35-65 will be used to perform a weighted linear
    ///         regression on point 50.
    init(bandwidthPercent: CGFloat) {
        self.bandwidthPercent = bandwidthPercent
    }

    // MARK: - Exposed Functions

    /// Fit a data series using the LOESS algorithm. The explanatory variable is
    /// assumed to be the index of each element in the array, with the dependent
    /// variable being the value of the element at that index.
    ///
    /// - Parameter data: The data which should be smoothed
    /// - Returns: Returns the input data mapped to output values using LOESS
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
                let sampleWeight = weight(for: sample, relativeTo: point, bounds: bounds)
                weights.append(sampleWeight)
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
        // The formulas for slope and intercept are derived by solving the minimization of
        // sum( Wi * (Yi - (alpha + beta * Xi))^2 )
        // for alpha and beta, where Xi, Yi, and Wi are the values of the arrays at index `i`
        //
        // It is solved by taking the partial derivates of the sum(...) function with respect
        // to alpha and beta, and setting these partial derivates equal to zero. With this system
        // of two equations, we can solve for alpha and beta in terms of arrays X, Y, and W

        func multiply(_ first: [CGFloat], _ second: [CGFloat]) -> [CGFloat] {
            return zip(first, second).map(*)
        }

        let sumW = weights.reduce(0, +)
        let sumWX = multiply(weights, xValues).reduce(0, +)
        let sumWY = multiply(weights, yValues).reduce(0, +)
        let sumWX2 = multiply(weights, multiply(xValues, xValues)).reduce(0, +)
        let sumWXY = multiply(multiply(weights, xValues), yValues).reduce(0, +)

        let slopeNumerator = (sumWX * sumWY) - (sumW * sumWXY)
        let slopeDenominator = (sumWX * sumWX) - (sumW * sumWX2)

        let slope = slopeNumerator / slopeDenominator
        let intercept = (sumWY - (slope * sumWX)) / sumW
        return { xValue in intercept + slope * xValue }
    }

}

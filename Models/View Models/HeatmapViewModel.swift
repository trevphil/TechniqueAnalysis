//
//  HeatmapViewModel.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 12/11/18.
//

import Foundation
import CoreML

public struct HeatmapViewModel {

    // MARK: - Properties

    let heatmap: [[Double]]

    // MARK: - Initialization

    public init?(heatmap: MLMultiArray) {
        guard let converted = HeatmapViewModel.convertedHeatmap(heatmap) else {
            return nil
        }

        self.heatmap = converted
    }

    // MARK: - Private Functions

    private static func convertedHeatmap(_ heatmap: MLMultiArray) -> [[Double]]? {
        guard let numBodyParts = heatmap.shape.element(atIndex: 0)?.intValue,
            let height = heatmap.shape.element(atIndex: 1)?.intValue,
            let width = heatmap.shape.element(atIndex: 2)?.intValue else {
                print("Error: heatmap should have at least 3 dimensions")
                return nil
        }

        var converted = Array(repeating: Array(repeating: 0.0, count: width), count: height)
        for pointIndex in 0..<numBodyParts {
            for row in 0..<height {
                for col in 0..<width {
                    let index = (pointIndex * height * width) + (row * width) + col
                    let confidence = heatmap[index].doubleValue
                    guard confidence > 0 else {
                        continue
                    }
                    converted[col][row] += confidence
                }
            }
        }

        // Bound values between 0 and 1
        return converted.map { row in
            return row.map { max(0, min($0, 1.0)) }
        }
    }

}

//
//  UIImage+Additions.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 15.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {

    /// Generate a visualization of a cost matrix from kNN DTW
    ///
    /// - Parameter matrix: The matrix to visualize
    /// - Returns: An image representation of the cost matrix, colored by matrix values
    static func image(from matrix: [[Double]]?) -> UIImage? {
        guard let matrix = matrix else {
            return nil
        }

        return MatrixView(matrix: matrix, scale: 3.0).asImage()
    }

}

private class MatrixView: UIView {

    // MARK: - Properties

    private let matrix: [[Double]]
    private let numRows: Int
    private let numCols: Int
    private let scale: CGFloat
    private let maxValue: Double = 1000

    // MARK: - Initialization

    init(matrix: [[Double]], scale: Double) {
        self.matrix = matrix
        self.scale = CGFloat(scale)
        self.numRows = matrix.count
        self.numCols = matrix[0].count
        let frame = CGRect(x: 0, y: 0, width: Double(numRows) * scale, height: Double(numCols) * scale)
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func draw(_ rect: CGRect) {
        for row in 0..<numRows {
            for col in 0..<numCols {
                let cost = self.matrix[row][col]
                let itemFill = color(for: cost)
                itemFill.setFill()
                UIColor.clear.setStroke()
                let itemFrame = CGRect(x: CGFloat(row) * scale,
                                       y: CGFloat(col) * scale,
                                       width: scale,
                                       height: scale)
                let path = UIBezierPath(rect: itemFrame)
                path.fill()
            }
        }
    }

    // MARK: - Exposed Functions

    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }

    // MARK: - Private Functions

    private func color(for cost: Double) -> UIColor {
        let mappedCost = CGFloat(min(maxValue, cost) / maxValue)
        return UIColor(hue: mappedCost, saturation: 0.5, brightness: 0.5, alpha: 1)
    }

}

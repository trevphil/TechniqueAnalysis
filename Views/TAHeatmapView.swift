//
//  TAHeatmapView.swift
//  TechniqueAnalysis
//
//  Created by Trevor on 04.12.18.
//

import UIKit
import CoreML

/// View showing a heatmap of a user's posture and pose based on probabilities
/// (confidence levels) that a body point is at a particular 2D coordinate
public class TAHeatmapView: UIView {

    // MARK: - Properties

    private var model: TAHeatmapViewModel

    // MARK: - Initialization

    /// Create a new instance of `TAHeatmapView`
    ///
    /// - Parameter model: The model supplying data when the view is rendered
    public init(model: TAHeatmapViewModel) {
        self.model = model
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override public func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        context.clear(rect)
        let size = bounds.size
        let heatmapWidth = model.heatmap.count
        let heatmapHeight = model.heatmap.first?.count ?? 0
        let width = size.width / CGFloat(heatmapWidth)
        let height = size.height / CGFloat(heatmapHeight)

        for col in 0..<heatmapWidth {
            for row in 0..<heatmapHeight {
                let value = model.heatmap[row][col]
                let alpha = CGFloat(value)
                guard alpha > 0 else {
                    continue
                }

                let bezierBox = CGRect(x: CGFloat(row) * width,
                                       y: CGFloat(col) * height,
                                       width: width,
                                       height: height)
                let color = UIColor(red: 1, green: 0, blue: 0, alpha: alpha)
                let bezier = UIBezierPath(rect: bezierBox)
                color.set()
                bezier.stroke()
            }
        }
    }

    // MARK: - Public Functions

    /// Configure the view with a new model
    ///
    /// - Parameter model: The model supplying data when the view is rendered
    public func configure(with model: TAHeatmapViewModel) {
        self.model = model
        setNeedsDisplay()
    }
    
}

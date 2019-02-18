//
//  BodyPartTimeView.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/17/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import TechniqueAnalysis

/// A custom view which graphs the change in x- and y-position of a body part over time
class BodyPartTimeView: UIView {

    // MARK: - Properties

    private var samples: [TAPointEstimate]? {
        didSet {
            setNeedsDisplay()
        }
    }
    private weak var confidenceLabel: UILabel?

    private var xSeries: [CGPoint] {
        guard let samples = samples, !samples.isEmpty else {
            return []
        }

        let timeStep = bounds.width / CGFloat(samples.count)
        let heightScalar = bounds.height / 2.0 * 0.9
        return normalized(samples.map({ $0.point.x })).enumerated().map { (idx, value) in
            return CGPoint(x: CGFloat(idx) * timeStep, y: value * heightScalar + 2.0)
        }
    }

    private var ySeries: [CGPoint] {
        guard let samples = samples, !samples.isEmpty else {
            return []
        }

        let timeStep = bounds.width / CGFloat(samples.count)
        let heightScalar = bounds.height / 2.0 * 0.9
        return normalized(samples.map({ $0.point.y })).enumerated().map { (idx, value) in
            return CGPoint(x: CGFloat(idx) * timeStep,
                           y: value * heightScalar + bounds.height / 2.0)
        }
    }

    private var averageConfidence: Double {
        guard let samples = samples, !samples.isEmpty else {
            return -1
        }

        let count = Double(samples.count)
        var total: Double = 0
        for sample in samples { total += sample.confidence }
        return Double(Int(total / count * 1000.0)) / 1000.0
    }

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = false
    }

    override func draw(_ rect: CGRect) {
        // Draw x-axis data
        let xSeries = self.xSeries
        for (idx, current) in xSeries.enumerated() {
            if idx == 0 { continue }

            let previous = xSeries[idx - 1]
            let line = UIBezierPath()
            line.move(to: previous)
            line.addLine(to: current)
            line.close()

            UIColor.red.setStroke()
            line.stroke()
        }

        // Draw y-axis data
        let ySeries = self.ySeries
        for (idx, current) in ySeries.enumerated() {
            if idx == 0 { continue }

            let previous = ySeries[idx - 1]
            let line = UIBezierPath()
            line.move(to: previous)
            line.addLine(to: current)
            line.close()

            UIColor.blue.setStroke()
            line.stroke()
        }
    }

    // MARK: - Exposed Functions

    /// Configure the view with an ordered list of point estimates for a body part
    ///
    /// - Parameter samples: A time-ordered list of `TAPointEstimate`s for a single body part
    func configure(with samples: [TAPointEstimate]) {
        self.samples = samples
        configureConfidenceLabel()
    }

    // MARK: - Private Functions

    private func normalized(_ points: [CGFloat]) -> [CGFloat] {
        let minPoint = points.min() ?? 0
        let maxPoint = points.max() ?? 1e-5
        let pointRange = maxPoint - minPoint
        return points.map { ($0 - minPoint) / pointRange }
    }

    private func configureConfidenceLabel() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .strokeColor: UIColor.black
        ]
        let text = "Avg. confidence = \(averageConfidence)"

        if let label = confidenceLabel {
            label.attributedText = NSAttributedString(string: text, attributes: attributes)
            return
        }

        let label = UILabel()
        label.attributedText = NSAttributedString(string: text, attributes: attributes)
        label.sizeToFit()
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.rightAnchor.constraint(equalTo: rightAnchor, constant: -8).isActive = true
        label.topAnchor.constraint(equalTo: topAnchor, constant: 4).isActive = true
        self.confidenceLabel = label
    }

}

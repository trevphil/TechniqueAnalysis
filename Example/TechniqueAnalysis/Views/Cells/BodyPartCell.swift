//
//  BodyPartCell.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/17/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import TechniqueAnalysis

/// Table view cell for visualizing a body part's movement over time
class BodyPartCell: UITableViewCell {

    // MARK: - Properties

    /// Cell identifier
    static let identifier = "BodyPartCell"

    private lazy var xGraph: Grapher! = {
        let xGraph = Grapher(amplitude: xGraphContainer.frame.height * 0.9)
        xGraphContainer.addSubview(xGraph)
        xGraph.translatesAutoresizingMaskIntoConstraints = false
        xGraph.leftAnchor.constraint(equalTo: xGraphContainer.leftAnchor).isActive = true
        xGraph.rightAnchor.constraint(equalTo: xGraphContainer.rightAnchor).isActive = true
        xGraph.topAnchor.constraint(equalTo: xGraphContainer.topAnchor).isActive = true
        xGraph.bottomAnchor.constraint(equalTo: xGraphContainer.bottomAnchor).isActive = true
        xGraph.configure(with: xSamples)
        xGraph.backgroundColor = .white
        return xGraph
    }()

    private lazy var yGraph: Grapher! = {
        let yGraph = Grapher(amplitude: yGraphContainer.frame.height * 0.9)
        yGraphContainer.addSubview(yGraph)
        yGraph.translatesAutoresizingMaskIntoConstraints = false
        yGraph.leftAnchor.constraint(equalTo: yGraphContainer.leftAnchor).isActive = true
        yGraph.rightAnchor.constraint(equalTo: yGraphContainer.rightAnchor).isActive = true
        yGraph.topAnchor.constraint(equalTo: yGraphContainer.topAnchor).isActive = true
        yGraph.bottomAnchor.constraint(equalTo: yGraphContainer.bottomAnchor).isActive = true
        yGraph.configure(with: ySamples)
        yGraph.backgroundColor = .white
        return yGraph
    }()

    @IBOutlet private weak var bodyPartNameLabel: UILabel!
    @IBOutlet private weak var xGraphContainer: UIView!
    @IBOutlet private weak var yGraphContainer: UIView!
    @IBOutlet private weak var legendStackView: UIStackView?

    private var labels = [String]()
    private var samples: [[TAPointEstimate]]?

    private var xSamples: [[CGFloat]] {
        return samples?.map({ sample in
            return sample.map { $0.point.x }
        }) ?? []
    }

    private var ySamples: [[CGFloat]] {
        return samples?.map({ sample in
            return sample.map { $0.point.y }
        }) ?? []
    }

    private var averageConfidences: [Double] {
        return samples?.map({ sample in
            return sample.map({ $0.confidence }).reduce(0, +) / Double(sample.count)
        }) ?? []
    }

    // MARK: - Exposed Functions

    /// Configure the cell based on the movement of a body part, over time
    ///
    /// - Parameters:
    ///   - unknown: Samples of a *single* body part, taken over time (for unknown series)
    ///   - bestGuess: Samples of a *single* body part, taken over time (for best guess for unknown)
    ///   - secondBest: Samples of a *single* body part, taken over time (for 2nd best guess for unknown)
    func configure(with unknown: [TAPointEstimate],
                   bestGuess: [TAPointEstimate],
                   secondBest: [TAPointEstimate]) {
        let firstSample = unknown.element(atIndex: 0)?.bodyPart
        bodyPartNameLabel.text = firstSample?.asString ?? "(none)"
        configure(with: [unknown, bestGuess, secondBest],
                  labels: ["Unknown", "Best Guess", "2nd Best"])
    }

    // MARK: - Private Functions

    private func configure(with samples: [[TAPointEstimate]], labels: [String]) {
        self.samples = samples
        self.labels = labels

        xGraph?.configure(with: xSamples)
        yGraph?.configure(with: ySamples)
        updateLegend()
    }

    private func updateLegend() {
        legendStackView?.subviews.forEach { $0.removeFromSuperview() }
        let confidences = averageConfidences

        guard labels.count == confidences.count else {
            return
        }

        for (idx, labelString) in labels.enumerated() {
            let label = UILabel()
            label.numberOfLines = 0
            label.textColor = xGraph?.color(for: idx)
            let confidence = round(confidences[idx] * 1000.0) / 1000.0
            label.text = "\(labelString)\navg_conf = \(confidence)"
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.5
            legendStackView?.addArrangedSubview(label)
        }
    }

}

private class Grapher: UIView {

    // MARK: - Properties

    private var data = [[CGFloat]]() {
        didSet {
            setNeedsDisplay()
        }
    }

    private let amplitude: CGFloat
    private let colors: [UIColor] = [.red, .blue, .green, .purple, .black]

    // MARK: - Initialization

    init(amplitude: CGFloat) {
        self.amplitude = amplitude

        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func draw(_ rect: CGRect) {
        for (idx, series) in data.enumerated() {
            drawSeries(series, color: color(for: idx))
        }
    }

    // MARK: - Exposed Functions

    func configure(with data: [[CGFloat]]) {
        self.data = data
    }

    func color(for index: Int) -> UIColor {
        return colors[index % colors.count]
    }

    // MARK: - Helpers

    private func drawSeries(_ series: [CGFloat], color: UIColor) {
        for index in 1..<series.count {
            let current = point(for: index, in: series)
            let previous = point(for: index - 1, in: series)

            let line = UIBezierPath()
            line.move(to: previous)
            line.addLine(to: current)
            line.close()

            color.setStroke()
            line.stroke()
        }
    }

    private func point(for index: Int, in series: [CGFloat]) -> CGPoint {
        let current = series[index % series.count]
        let range = dataRange(for: series)
        let xPoint = (CGFloat(index) / CGFloat(series.count)) * frame.width
        let minItem = series.min() ?? 0
        let yScaled = ( (current - minItem) / range) * min(amplitude, frame.height * 0.9)
        let yPoint = frame.height - yScaled
        return CGPoint(x: xPoint, y: yPoint)
    }

    private func dataRange(for series: [CGFloat]) -> CGFloat {
        let minData = series.min() ?? 0
        let maxData = series.max() ?? 1e-5
        return maxData - minData
    }
}

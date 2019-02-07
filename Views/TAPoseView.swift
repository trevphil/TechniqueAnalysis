//
//  TAPoseView.swift
//  TechniqueAnalysis
//
//  Created by Trevor on 04.12.18.
//

import UIKit

public protocol TAPoseViewDelegate: class {
    func color(for bodyPart: TABodyPart) -> UIColor?
    func string(for bodyPart: TABodyPart) -> String?
}

public class TAPoseView: UIView {
    
    // MARK: - Properties

    private weak var delegate: TAPoseViewDelegate?
    private var views = [UIView]()
    private var model: TAPoseViewModel
    private let jointLineColor: CGColor

    // MARK: - Initialization

    public init(model: TAPoseViewModel, delegate: TAPoseViewDelegate?, jointLineColor: UIColor) {
        self.model = model
        self.delegate = delegate
        self.jointLineColor = jointLineColor.cgColor
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    
    override public func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            context.clear(rect)
            
            guard TABodyPart.allCases.count == model.bodyPoints.count else {
                return
            }
            
            let size = bounds.size
            TABodyPart.joints.forEach { (firstPart, secondPart) in
                if let pointOne = model.point(for: firstPart), let pointTwo = model.point(for: secondPart) {
                    let scaledPointOne = CGPoint(x: pointOne.point.x * size.width, y: pointOne.point.y * size.height)
                    let scaledPointTwo = CGPoint(x: pointTwo.point.x * size.width, y: pointTwo.point.y * size.height)
                    drawLine(context: context, from: scaledPointOne, to: scaledPointTwo, color: jointLineColor)
                }
            }
        }
    }

    // MARK: - Public Functions

    public func configure(with model: TAPoseViewModel) {
        self.model = model
        setNeedsDisplay()
        drawKeypoints(with: model.bodyPoints)
    }

    public func setupOutputComponent() {
        for view in views {
            view.removeFromSuperview()
        }

        views = TABodyPart.allCases.map { bodyPart in
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: 4))
            view.backgroundColor = delegate?.color(for: bodyPart) ?? .white
            view.clipsToBounds = false
            let label = UILabel(frame: CGRect(x: 7, y: -3, width: 100, height: 8))
            label.text = delegate?.string(for: bodyPart) ?? ""
            label.textColor = delegate?.color(for: bodyPart) ?? .white
            label.font = UIFont.preferredFont(forTextStyle: .caption2)
            view.addSubview(label)
            addSubview(view)
            return view
        }
    }

    // MARK: - Private Functions
    
    private func drawLine(context: CGContext, from first: CGPoint, to second: CGPoint, color: CGColor) {
        context.setStrokeColor(color)
        context.setLineWidth(3.0)
        context.move(to: first)
        context.addLine(to: second)
        context.strokePath()
    }
    
    private func drawKeypoints(with pointEstimates: [TAPointEstimate]) {
        guard let imageFrame = views.first?.superview?.frame else {
            return
        }

        let minAlpha = CGFloat(0.4)
        let maxAlpha = CGFloat(1.0)
        let minC = Double(0.1)
        let maxC = Double(0.6)
        
        for (index, estimate) in pointEstimates.enumerated() {
            guard let view = views.element(atIndex: index) else {
                break
            }
            
            view.center = CGPoint(x: estimate.point.x * imageFrame.width, y: estimate.point.y * imageFrame.height)
            let cRate = (estimate.confidence - minC) / (maxC - minC)
            view.alpha = (maxAlpha - minAlpha) * CGFloat(cRate) + minAlpha
        }
    }
    
}

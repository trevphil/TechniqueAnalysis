//
//  StepperController.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 15.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import TechniqueAnalysis

class StepperController: UIViewController {

    // MARK: - Properties

    @IBOutlet private weak var poseViewContainer: UIView!
    @IBOutlet private weak var exerciseNameLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var unknownColorView: UIView!
    @IBOutlet private weak var unknownLabel: UILabel!
    @IBOutlet private weak var knownColorView: UIView!
    @IBOutlet private weak var knownLabel: UILabel!
    private var poseViewUnknown: TAPoseView?
    private var poseViewKnown: TAPoseView?
    private let model: StepperModel
    private var timeIndex: Int = 0 {
        didSet {
            timeLabel.text = "t = \(timeIndex)"
        }
    }

    // MARK: - Initialization

    /// Create a new instance of `StepperController`
    ///
    /// - Parameter model: The model used to configure the instance
    init(model: StepperModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
        self.title = model.title
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let unknown = model.unknownSeriesSlice(atTime: timeIndex),
            let known = model.knownSeriesSlice(atTime: timeIndex) else {
                return
        }

        exerciseNameLabel.text = model.exerciseName
        setupPoseViews(unknownPoseModel: unknown, knownPoseModel: known)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedScreen))
        view.addGestureRecognizer(tapGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let poseViewUnknown = poseViewUnknown {
            poseViewContainer.bringSubviewToFront(poseViewUnknown)
        }
        if let poseViewKnown = poseViewKnown {
            poseViewContainer.bringSubviewToFront(poseViewKnown)
        }
    }

    // MARK: - Private Functions

    private func setupPoseViews(unknownPoseModel: TAPoseViewModel,
                                knownPoseModel: TAPoseViewModel) {
        let unknownColor = UIColor.red
        let unknown = TAPoseView(model: unknownPoseModel, delegate: self, jointLineColor: unknownColor)
        poseViewContainer.addSubview(unknown)
        unknown.frame = poseViewContainer.bounds
        unknown.setupOutputComponent()
        unknown.backgroundColor = .clear
        unknownColorView.backgroundColor = unknownColor
        unknownLabel.text = "Unknown"

        let knownColor = UIColor.blue
        let known = TAPoseView(model: knownPoseModel, delegate: self, jointLineColor: knownColor)
        poseViewContainer.addSubview(known)
        known.frame = poseViewContainer.bounds
        known.setupOutputComponent()
        known.backgroundColor = .clear
        knownColorView.backgroundColor = knownColor
        knownLabel.text = "Best Guess"

        self.poseViewUnknown = unknown
        self.poseViewKnown = known
    }

    @objc private func tappedScreen() {
        timeIndex += 1

        guard let unknown = model.unknownSeriesSlice(atTime: timeIndex),
            let known = model.knownSeriesSlice(atTime: timeIndex) else {
                timeIndex = 0
                return
        }

        poseViewUnknown?.configure(with: unknown)
        poseViewKnown?.configure(with: known)
    }

}

extension StepperController: TAPoseViewDelegate {

    func color(for bodyPart: TABodyPart) -> UIColor? {
        return bodyPart.color
    }

    func string(for bodyPart: TABodyPart) -> String? {
        return bodyPart.asString
    }

}

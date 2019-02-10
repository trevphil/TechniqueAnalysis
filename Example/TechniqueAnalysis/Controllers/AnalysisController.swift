//
//  AnalysisController.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/8/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import AVKit

/// Controller which processes an unlabeled video and gives
/// a best-guess on the closest labeled data point
class AnalysisController: UIViewController {

    // MARK: - Properties

    private let model: AnalysisModel
    private let avPlayerController = AVPlayerViewController()
    @IBOutlet private weak var exerciseNameLabel: UILabel!
    @IBOutlet private weak var formSuggestionLabel: UILabel!
    @IBOutlet private weak var loadingSpinner: UIActivityIndicatorView!
    @IBOutlet private weak var videoPreviewContainer: UIView!

    // MARK: - Initialization

    /// Create a new instance of `AnalysisController`
    ///
    /// - Parameter model: The model used to configure the instance
    init(model: AnalysisModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
        self.title = model.title
        self.model.delegate = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        exerciseNameLabel.text = model.exerciseName
        formSuggestionLabel.text = "Processing Video..."
        configureVideoPreview()
        model.analyzeVideo()
    }

    deinit {
        model.deleteVideo()
    }

    // MARK: - Private Functions

    private func configureVideoPreview() {
        let avPlayer = AVPlayer(url: model.videoURL)
        avPlayerController.player = avPlayer
        addChild(avPlayerController)
        videoPreviewContainer.addSubview(avPlayerController.view)
        avPlayerController.view.frame = videoPreviewContainer.bounds
    }

}

extension AnalysisController: AnalysisModelDelegate {

    func didAnalyze(with result: TestResult) {
        loadingSpinner.isHidden = true
        formSuggestionLabel.text = result.predictionMeta?.exerciseDetail ?? "(No Prediction)"
    }

}

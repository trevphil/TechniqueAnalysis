//
//  HeatmapController.swift
//  TechniqueAnalysis
//
//  Created by Trevor on 04.12.18.
//

import UIKit
import CoreML
import TechniqueAnalysis

class HeatmapController: UIViewController {

    // MARK: - Properties

    @IBOutlet private weak var videoPreviewContainer: UIView!
    private var heatmapView: HeatmapView?

    private let model: PoseEstimationModel?

    // MARK: - Initialization

    init() {
        self.model = PoseEstimationModel(type: .cpm)
        super.init(nibName: nil, bundle: nil)
        self.model?.delegate = self
        self.title = "Heatmap"
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model?.setupCameraPreview(withinView: videoPreviewContainer)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        model?.tearDownCameraPreview()
    }

    // MARK: - Private Functions

    private func setupHeatmapView(with heatmapModel: HeatmapViewModel) {
        let hmView = HeatmapView(model: heatmapModel)
        view.addSubview(hmView)
        hmView.translatesAutoresizingMaskIntoConstraints = false
        hmView.leftAnchor.constraint(equalTo: videoPreviewContainer.leftAnchor).isActive = true
        hmView.rightAnchor.constraint(equalTo: videoPreviewContainer.rightAnchor).isActive = true
        hmView.topAnchor.constraint(equalTo: videoPreviewContainer.topAnchor).isActive = true
        hmView.bottomAnchor.constraint(equalTo: videoPreviewContainer.bottomAnchor).isActive = true
        hmView.backgroundColor = .clear
        self.heatmapView = hmView
    }

}

extension HeatmapController: PoseEstimationDelegate {

    func visionRequestDidComplete(heatmap: MLMultiArray) {
        if let heatmapModel = HeatmapViewModel(heatmap: heatmap) {
            if let heatmapView = heatmapView {
                heatmapView.configure(with: heatmapModel)
            } else {
                setupHeatmapView(with: heatmapModel)
            }
        }
    }

    func visionRequestDidFail(error: Error?) {
        print("ERROR: - Vision request failed. Error=\(error?.localizedDescription ?? "(no message)")")
    }

    func didSamplePerformance(inferenceTime: Double, executionTime: Double, fps: Int) {
    }

}

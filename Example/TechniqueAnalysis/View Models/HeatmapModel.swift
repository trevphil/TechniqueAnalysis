//
//  HeatmapModel.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 07.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import CoreML
import TechniqueAnalysis

/// Delegate object which responds to events from `HeatmapModel`
protocol HeatmapModelDelegate: class {

    /// Alert the delegate that it should update its `TAHeatmapView` with a new model
    ///
    /// - Parameter heatmapViewModel: The model that should be used to update the `TAHeatmapView`
    func updateHeatmapView(with heatmapViewModel: TAHeatmapViewModel)

}

/// Model which helps visualize a heatmap of the predicted posture/pose of an image
class HeatmapModel {

    // MARK: - Properties

    private let poseEstimationModel: TAPoseEstimationModel?
    /// A delegate object responding to this model's events
    weak var delegate: HeatmapModelDelegate?
    /// The model's title
    let title: String

    // MARK: - Initialization

    init() {
        self.title = "Heatmap"
        self.poseEstimationModel = TAPoseEstimationModel(type: Params.modelType)
        self.poseEstimationModel?.delegate = self
    }

    // MARK: - Exposed Functions

    /// Creates a live stream video preview using the device’s camera and processes
    /// the video feed in real time to determine data about a user’s posture
    ///
    /// - Parameter view: The `UIView` in which the video preview should appear
    func setupCameraPreview(withinView view: UIView) {
        poseEstimationModel?.setupCameraPreview(withinView: view)
    }

    /// Remove and destroy any video preview sessions created by `setupCameraPreview(withinView:)`
    func tearDownCameraPreview() {
        poseEstimationModel?.tearDownCameraPreview()
    }

}

extension HeatmapModel: TAPoseEstimationDelegate {

    func visionRequestDidComplete(heatmap: MLMultiArray) {
        guard let heatmapModel = TAHeatmapViewModel(heatmap: heatmap) else {
            return
        }

        delegate?.updateHeatmapView(with: heatmapModel)
    }

    func visionRequestDidFail(error: Error?) {
        print("ERROR: - Vision request failed. Error=\(error?.localizedDescription ?? "(no message)")")
    }

    func didSamplePerformance(inferenceTime: Double, executionTime: Double, fps: Int) {
    }

}

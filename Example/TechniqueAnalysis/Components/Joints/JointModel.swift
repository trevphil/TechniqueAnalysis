//
//  JointModel.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 07.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import CoreML
import TechniqueAnalysis

/// Delegate object which responds to events from `JointModel`
protocol JointModelDelegate: class {

    /// Alert the delegate that it should update its `TAPoseView` with a new model
    ///
    /// - Parameter poseViewModel: The model that should be used to update the `TAPoseView`
    func updatePoseView(with poseViewModel: TAPoseViewModel)

    /// Alert the delegate that new algorithm performance data is available
    ///
    /// - Parameters:
    ///   - inferenceTime: The amount of time (in sec) it took for CoreVision and CoreML to
    ///                    process an input image into meaningful data about body posture
    ///   - executionTime: The total time (in sec) it took from inputting an image to CoreVision
    ///                    and CoreML to processing the output
    ///   - fps: The frames per second that are being processed
    func didSamplePerformance(inferenceTime: Double, executionTime: Double, fps: Int)

}

/// Model which helps visualize a user's body points and joints in real time
class JointModel {

    // MARK: - Properties

    private let poseEstimationModel: TAPoseEstimationModel?
    /// A delegate object responding to this model's events
    weak var delegate: JointModelDelegate?
    /// The model's title
    let title: String
    /// Array of `TAPointEstimate` objects which can be shown in a table view
    private(set) var tableData = [TAPointEstimate]()

    // MARK: - Initialization

    init() {
        self.title = "Joints"
        self.poseEstimationModel = TAPoseEstimationModel(type: Params.modelType)
        self.poseEstimationModel?.delegate = self
    }

    // MARK: - Private Functions

    private func updateData(with bodyPoints: [TAPointEstimate]) {
        tableData = bodyPoints.sorted(by: {
            ($0.bodyPart?.rawValue ?? 0) < ($1.bodyPart?.rawValue ?? 1)
        })
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

    /// Updates the frame of the video preview
    ///
    /// - Parameter frame: The desired frame of the video preview
    func updateVideoPreviewFrame(_ frame: CGRect) {
        poseEstimationModel?.videoPreviewLayer?.frame = frame
    }

}

extension JointModel: TAPoseEstimationDelegate {

    func visionRequestDidComplete(heatmap: MLMultiArray) {
        guard let poseModel = TAPoseViewModel(heatmap: heatmap) else {
            return
        }

        updateData(with: poseModel.bodyPoints)
        delegate?.updatePoseView(with: poseModel)
    }

    func visionRequestDidFail(error: Error?) {
        print("ERROR: - Vision request failed. Error=\(error?.localizedDescription ?? "(no message)")")
    }

    func didSamplePerformance(inferenceTime: Double, executionTime: Double, fps: Int) {
        delegate?.didSamplePerformance(inferenceTime: inferenceTime, executionTime: executionTime, fps: fps)
    }

}

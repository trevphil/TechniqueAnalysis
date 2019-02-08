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

protocol JointModelDelegate: class {
    func updatePoseView(with poseViewModel: TAPoseViewModel)
    func didSamplePerformance(inferenceTime: Double, executionTime: Double, fps: Int)
}

class JointModel {

    // MARK: - Properties

    private let poseEstimationModel: TAPoseEstimationModel?
    weak var delegate: JointModelDelegate?
    let title: String
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

    func setupCameraPreview(withinView view: UIView) {
        poseEstimationModel?.setupCameraPreview(withinView: view)
    }

    func tearDownCameraPreview() {
        poseEstimationModel?.tearDownCameraPreview()
    }

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

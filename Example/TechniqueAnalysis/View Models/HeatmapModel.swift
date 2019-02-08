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

protocol HeatmapModelDelegate: class {
    func updateHeatmapView(with heatmapViewModel: TAHeatmapViewModel)
}

class HeatmapModel {

    // MARK: - Properties

    private let poseEstimationModel: TAPoseEstimationModel?
    weak var delegate: HeatmapModelDelegate?
    let title: String

    // MARK: - Initialization

    init() {
        self.title = "Heatmap"
        self.poseEstimationModel = TAPoseEstimationModel(type: Params.modelType)
        self.poseEstimationModel?.delegate = self
    }

    // MARK: - Exposed Functions

    func setupCameraPreview(withinView view: UIView) {
        poseEstimationModel?.setupCameraPreview(withinView: view)
    }

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

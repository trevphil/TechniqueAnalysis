//
//  AnalysisController.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 29.01.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import AVKit

class AnalysisController: UIViewController {

    // MARK: - Properties

    private let model: AnalysisModel
    @IBOutlet private weak var camPreview: UIView!

    // MARK: - Initialization

    init(model: AnalysisModel) {
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
        model.setupAndStartSession()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupCameraPreview()
    }

    func setupCameraPreview() {
        let previewLayer = AVCaptureVideoPreviewLayer(session: model.captureSession)
        previewLayer.frame = camPreview.bounds
        previewLayer.videoGravity = .resizeAspectFill
        camPreview.layer.addSublayer(previewLayer)
    }

    // MARK: - Actions

    @IBAction private func startCapture() {
        model.startRecording()
    }

}

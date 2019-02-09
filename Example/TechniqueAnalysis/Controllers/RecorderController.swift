//
//  RecorderController.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 29.01.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import AVKit

class RecorderController: UIViewController {

    // MARK: - Properties

    private let model: RecorderModel
    private let onVideoRecorded: ((URL) -> Void)
    private var didSetupCameraPreview = false
    @IBOutlet private weak var camPreview: UIView!
    @IBOutlet private weak var playButton: UILabel!
    @IBOutlet private weak var stopButton: UILabel!
    @IBOutlet private weak var invisibleToggleButton: UIButton!

    // MARK: - Initialization

    init(model: RecorderModel,
         onVideoRecorded: @escaping ((URL) -> Void)) {
        self.model = model
        self.onVideoRecorded = onVideoRecorded
        super.init(nibName: nil, bundle: nil)
        self.title = model.title
        model.delegate = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.setupAndStartSession()
        playButton.isHidden = false
        stopButton.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupCameraPreview()
    }

    deinit {
        model.stopSession()
    }

    // MARK: - Private Functions

    private func setupCameraPreview() {
        guard !didSetupCameraPreview else {
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: model.captureSession)
        previewLayer.frame = camPreview.bounds
        previewLayer.videoGravity = .resizeAspectFill
        camPreview.layer.addSublayer(previewLayer)
        view.bringSubviewToFront(playButton)
        view.bringSubviewToFront(stopButton)
        view.bringSubviewToFront(invisibleToggleButton)
        didSetupCameraPreview = true
    }

    // MARK: - Actions

    @IBAction private func toggleCapture() {
        model.toggleRecording()
    }

}

extension RecorderController: RecorderModelDelegate {

    func didStartRecording() {
        playButton.isHidden = true
        stopButton.isHidden = false
    }

    func didStopRecording() {
        playButton.isHidden = false
        stopButton.isHidden = true
    }

    func didSaveVideo(url: URL) {
        onVideoRecorded(url)
    }

}

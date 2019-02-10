//
//  RecorderModel.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 07.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import AVKit

/// Delegate object which responds to events from `RecorderModel`
protocol RecorderModelDelegate: class {

    /// Alert the delegate that the device has started recording
    func didStartRecording()

    /// Alert the delegate that the device has stopped recording
    func didStopRecording()

    /// Alert the delegate that the model has saved a user-recorded video
    ///
    /// - Parameter url: The URL where the video was saved
    func didSaveVideo(url: URL)

}

/// Model which helps configure the iOS camera device in order to record a user performing an exercise
class RecorderModel: NSObject {

    // MARK: - Properties

    /// The model's title
    let title: String
    /// The `AVCaptureSession` configured by the view model
    let captureSession = AVCaptureSession()
    /// A delegate object responding to this model's events
    weak var delegate: RecorderModelDelegate?
    private let videoOutput = AVCaptureMovieFileOutput()
    private var activeInput: AVCaptureDeviceInput?
    private var outputURL: URL?

    private var videoQueue: DispatchQueue {
        return DispatchQueue.main
    }

    // MARK: - Initialization

    override init() {
        self.title = "Record"
    }

    // MARK: - Exposed Functions

    /// Setup an `AVCaptureSession` and begin recording
    func setupAndStartSession() {
        guard let camera = AVCaptureDevice.default(for: .video),
        let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }

        captureSession.sessionPreset = .high

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
            activeInput = input
        }

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        startSession()
    }

    /// Stop any ongoing `AVCaptureSession`s
    func stopSession() {
        guard captureSession.isRunning else {
            return
        }

        videoQueue.async {
            self.stopRecording()
            self.captureSession.stopRunning()
        }
    }

    /// Switch state of recording. If currently recording, will stop recording.
    /// If currently _not_ recording, will begin recording.
    func toggleRecording() {
        guard !videoOutput.isRecording else {
            stopRecording()
            return
        }

        guard let connection = videoOutput.connection(with: .video),
            let device = activeInput?.device,
            let output = tempURL() else {
                return
        }

        if connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = .auto
        }

        if connection.isVideoOrientationSupported {
            connection.videoOrientation = currentVideoOrientation()
        }

        if device.isSmoothAutoFocusSupported {
            do {
                try device.lockForConfiguration()
                device.isSmoothAutoFocusEnabled = false
                device.unlockForConfiguration()
            } catch {
                print("Error setting configuration: \(error)")
            }
        }

        self.outputURL = output
        videoOutput.startRecording(to: output, recordingDelegate: self)
        delegate?.didStartRecording()
    }

    // MARK: - Private Functions

    private func startSession() {
        guard !captureSession.isRunning else {
            return
        }

        videoQueue.async {
            self.captureSession.startRunning()
        }
    }

    private func stopRecording() {
        guard videoOutput.isRecording else {
            return
        }

        videoOutput.stopRecording()
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didStopRecording()
        }
    }

    private func tempURL() -> URL? {
        let temp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return temp.appendingPathComponent("\(UUID().uuidString).mp4", isDirectory: false)
    }

    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation

        switch UIDevice.current.orientation {
        case .portrait:
            orientation = AVCaptureVideoOrientation.portrait
        case .landscapeRight:
            orientation = AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown:
            orientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            orientation = AVCaptureVideoOrientation.landscapeRight
        }

        return orientation
    }

}

extension RecorderModel: AVCaptureFileOutputRecordingDelegate {

    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        if let error = error {
            print("Error recording video: \(error.localizedDescription)")
        } else {
            delegate?.didSaveVideo(url: outputFileURL)
        }
    }

}

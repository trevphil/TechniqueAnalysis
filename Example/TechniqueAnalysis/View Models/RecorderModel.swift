//
//  RecorderModel.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 07.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import AVKit

protocol RecorderModelDelegate: class {
    func didStartRecording()
    func didStopRecording()
    func didSaveVideo(url: URL)
}

class RecorderModel: NSObject {

    // MARK: - Properties

    let title: String
    let captureSession = AVCaptureSession()
    weak var delegate: RecorderModelDelegate?
    private let videoOutput = AVCaptureMovieFileOutput()
    private var activeInput: AVCaptureDeviceInput?
    private var outputURL: URL?

    private var videoQueue: DispatchQueue {
        return DispatchQueue.main
    }

    // MARK: - Initialization

    override init() {
        self.title = "Analysis"
    }

    // MARK: - Exposed Functions

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

    func stopSession() {
        guard captureSession.isRunning else {
            return
        }

        videoQueue.async {
            self.stopRecording()
            self.captureSession.stopRunning()
        }
    }

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

        if connection.isVideoOrientationSupported {
            connection.videoOrientation = currentVideoOrientation()
        }

        if connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = .auto
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

    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation

        switch UIDevice.current.orientation {
        case .portrait:
            orientation = .portrait
        case .landscapeRight:
            orientation = .landscapeLeft
        case .portraitUpsideDown:
            orientation = .portraitUpsideDown
        default:
            orientation = .landscapeRight
        }

        return orientation
    }

    private func tempURL() -> URL? {
        let temp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return temp.appendingPathComponent("\(UUID().uuidString).mp4", isDirectory: false)
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

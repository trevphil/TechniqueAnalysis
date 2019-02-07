//
//  TAVideoCapture.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 12/10/18.
//

import UIKit
import AVFoundation
import CoreVideo

protocol TAVideoCaptureDelegate: class {
    func videoCapture(_ capture: TAVideoCapture,
                      didCaptureFrame frame: CVPixelBuffer?,
                      timestamp: CMTime)
}

class TAVideoCapture: NSObject {

    // MARK: - Properties

    weak var delegate: TAVideoCaptureDelegate?
    private(set) var previewLayer: AVCaptureVideoPreviewLayer?
    private let fps: Int32

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "pose-estimation.camera-queue")
    private var lastTimestamp = CMTime()

    // MARK: - Initialization

    init(fps: Int32) {
        self.fps = fps
        super.init()
    }

    // MARK: - Exposed Functions

    func setup(sessionPreset: AVCaptureSession.Preset = .vga640x480,
               completion: @escaping ((Bool) -> Void)) {
        setupCamera(sessionPreset: sessionPreset, completion: completion)
    }

    func start() {
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }

    func stop() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    // MARK: - Private Functions

    private func configureVideoInput(sessionPreset: AVCaptureSession.Preset) -> Bool {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = sessionPreset
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                          for: .video,
                                                          position: .back) else {
                                                            print("ERROR: - No video devices available")
                                                            return false
        }

        guard let videoInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("ERROR: - Unable to create AVCaptureDeviceInput")
            return false
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }

        return true
    }

    private func configureVideoOutput() {
        let settings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
        videoOutput.videoSettings = settings
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        // We want the buffers to be in portrait orientation otherwise they are
        // rotated by 90 degrees. Need to set this after addOutput()
        videoOutput.connection(with: AVMediaType.video)?.videoOrientation = .portrait
    }

    private func setupCamera(sessionPreset: AVCaptureSession.Preset,
                             completion: @escaping ((Bool) -> Void)) {
        guard configureVideoInput(sessionPreset: sessionPreset) else {
            print("ERROR: - Unable to configure video input for capture session")
            completion(false)
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspect
        previewLayer.connection?.videoOrientation = .portrait
        self.previewLayer = previewLayer

        configureVideoOutput()
        captureSession.commitConfiguration()
        completion(true)
    }

}

extension TAVideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        // Because lowering the capture device's FPS looks ugly in the preview,
        // we capture at full speed but only call the delegate at its desired framerate
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let timeDelta = timestamp - lastTimestamp
        if timeDelta >= CMTimeMake(value: 1, timescale: fps) {
            lastTimestamp = timestamp
            let imgBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            delegate?.videoCapture(self, didCaptureFrame: imgBuffer, timestamp: timestamp)
        }
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didDrop sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
    }

}

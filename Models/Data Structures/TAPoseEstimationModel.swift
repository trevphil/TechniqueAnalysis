//
//  TAPoseEstimationModel.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 12/11/18.
//

import Vision
import CoreMedia

/// Delegate object responding to events from a `TAPoseEstimationModel` instance
public protocol TAPoseEstimationDelegate: class {

    /// Called on the main queue when a vision request has completed
    ///
    /// - Parameter heatmap: The output from one of the embedded CoreML models, with information
    ///                      about body part locations and their respective confidence levels
    func visionRequestDidComplete(heatmap: MLMultiArray)

    /// Called on the main queue when a vision request has completed unsuccessfully
    ///
    /// - Parameter error: The error which occurred
    func visionRequestDidFail(error: Error?)

    /// Called on the main queue when time-based performance data regarding ML pose estimation is available
    ///
    /// - Parameters:
    ///   - inferenceTime: The amount of time (in sec) it took for CoreVision and CoreML to
    ///                    process an input image into meaningful data about body posture
    ///   - executionTime: The total time (in sec) it took from inputting an image to CoreVision
    ///                    and CoreML to processing the output
    ///   - fps: The frames per second that are being processed
    func didSamplePerformance(inferenceTime: Double, executionTime: Double, fps: Int)

}

/// Model used to set up a video capture session (live stream feed from device camera)
/// and execute CoreVision and CoreML requests on the capture session to estimate a user's posture
public class TAPoseEstimationModel {

    // MARK: - Core ML Model

    private typealias CPMEstimationModel = cpm_model
    private typealias HourglassEstimationModel = hourglass_model

    /// The CoreML model type
    /// - cpm: Pre-trained model with underlying training from Convolutional Pose Machine algorithm
    /// - hourglass: Pre-trained model with underlying training from Stacked Hourglass algorithm
    public enum ModelType {
        case cpm, hourglass

        var outputShape: [Int] {
            switch self {
            case .cpm:
                return [14, 96, 96]
            case .hourglass:
                return [14, 48, 48]
            }
        }
    }

    // MARK: - Properties

    /// Delegate object responding to events from the `TAPoseEstimationModel` instance
    public weak var delegate: TAPoseEstimationDelegate?
    private var videoCapture: TAVideoCapture
    private let performanceTool = TAPerformanceTool()
    private var request: VNCoreMLRequest?
    private var visionModel: VNCoreMLModel!

    /// A `CALayer` showing a live stream from the device camera,
    /// if `setupCameraPreview(withinView:)` has been called
    public var videoPreviewLayer: CALayer? {
        return videoCapture.previewLayer
    }

    // MARK: - Initialization

    /// Create a new instance of `TAPoseEstimationModel`
    ///
    /// - Parameter type: The underlying ML model type to be used for video session processing
    /// - Note: Initialization fails if the underlying ML model cannot be initialized
    public init?(type: ModelType) {
        self.videoCapture = TAVideoCapture(fps: 30)

        switch type {
        case .cpm:
            visionModel = configuredCPMModel()
        case .hourglass:
            visionModel = configuredHourglassModel()
        }

        guard let visionModel = visionModel else {
            return nil
        }

        self.performanceTool.delegate = self
        self.videoCapture.delegate = self
        self.configureRequest(with: visionModel)
    }

    // MARK: - Public Functions

    /// Creates a live stream video preview using the device's camera and
    /// processes the video feed in real time to determine data about a user's posture
    ///
    /// - Parameter view: The `UIView` in which the video preview should appear
    public func setupCameraPreview(withinView view: UIView) {
        videoCapture.setup(sessionPreset: .vga640x480) { [weak self] success in
            guard success else {
                return
            }

            if let previewLayer = self?.videoCapture.previewLayer {
                view.layer.addSublayer(previewLayer)
                self?.videoCapture.previewLayer?.frame = view.bounds
            }

            self?.videoCapture.start()
        }
    }

    /// Remove and destroy any video preview sessions created by `setupCameraPreview(withinView:)`
    public func tearDownCameraPreview() {
        videoCapture.stop()
        videoCapture.previewLayer?.removeFromSuperlayer()
    }

    // MARK: - Exposed Functions

    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
        guard let request = request else {
            return
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }

    func predictUsingVision(cgImage: CGImage,
                            onSuccess: @escaping ((MLMultiArray) -> ()),
                            onFailure: @escaping ((Error?) -> ())) {
        let completion: VNRequestCompletionHandler = { (request, error) in
            if let observations = request.results as? [VNCoreMLFeatureValueObservation],
                let heatmap = observations.first?.featureValue.multiArrayValue {
                onSuccess(heatmap)
            } else {
                onFailure(error)
            }
        }
        let request = VNCoreMLRequest(model: visionModel, completionHandler: completion)
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }

    // MARK: - Private Functions

    private func visionRequestDidComplete(request: VNRequest, error: Error?) {
        performanceTool.endInference()
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
            let heatmap = observations.first?.featureValue.multiArrayValue {
            performanceTool.stop()
            DispatchQueue.main.async {
                self.delegate?.visionRequestDidComplete(heatmap: heatmap)
            }
        } else {
            DispatchQueue.main.async {
                self.delegate?.visionRequestDidFail(error: error)
            }
            performanceTool.stop()
        }
    }

    private func configuredCPMModel() -> VNCoreMLModel? {
        do {
            let mlModel: MLModel
            if #available(iOS 12.0, *) {
                let config = MLModelConfiguration()
                config.computeUnits = .all
                mlModel = try CPMEstimationModel(contentsOf: CPMEstimationModel.urlOfModelInThisBundle,
                                                 configuration: config).model
            } else {
                mlModel = try CPMEstimationModel(contentsOf: CPMEstimationModel.urlOfModelInThisBundle).model
            }
            return try VNCoreMLModel(for: mlModel)
        } catch {
            print("ERROR: - Unable to create CoreML model, \(error.localizedDescription)")
            return nil
        }
    }

    private func configuredHourglassModel() -> VNCoreMLModel? {
        do {
            let url = HourglassEstimationModel.urlOfModelInThisBundle
            let mlModel: MLModel
            if #available(iOS 12.0, *) {
                let config = MLModelConfiguration()
                config.computeUnits = .all
                mlModel = try HourglassEstimationModel(contentsOf: url, configuration: config).model
            } else {
                mlModel = try HourglassEstimationModel(contentsOf: url).model
            }
            return try VNCoreMLModel(for: mlModel)
        } catch {
            print("ERROR: - Unable to create CoreML model, \(error.localizedDescription)")
            return nil
        }
    }

    private func configureRequest(with visionModel: VNCoreMLModel) {
        let request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
        request.imageCropAndScaleOption = .scaleFill
        self.request = request
    }

}

extension TAPoseEstimationModel: TAVideoCaptureDelegate {

    func videoCapture(_ capture: TAVideoCapture,
                      didCaptureFrame frame: CVPixelBuffer?,
                      timestamp: CMTime) {
        if let pixelBuffer = frame {
            performanceTool.start()
            predictUsingVision(pixelBuffer: pixelBuffer)
        }
    }

}

extension TAPoseEstimationModel: TAPerformanceToolDelegate {

    func updateSample(inferenceTime: Double, executionTime: Double, fps: Int) {
        DispatchQueue.main.async {
            self.delegate?.didSamplePerformance(inferenceTime: inferenceTime,
                                                executionTime: executionTime,
                                                fps: fps)
        }
    }

}

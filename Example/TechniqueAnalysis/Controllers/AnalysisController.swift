//
//  AnalysisController.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 29.01.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import AVKit
import CoreML
import TechniqueAnalysis

class AnalysisController: UIViewController {

    // MARK: - Properties

    private var player: AVPlayer?
    private let avpController: AVPlayerViewController
    @IBOutlet private weak var videoViewContainer: UIView!
    @IBOutlet private weak var poseViewContainer: UIView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet private weak var infoLabel: UILabel?
    private var heatmapView: HeatmapView?
    private var didSetupHeatmapView = false

    // Array of `Timeseries` objects derived from a sample video
    private var timeseriesArray = [Timeseries]()
    /// The index of timeseries from `timeseriesArray` to be shown in a heatmap
    private let selectedTimeseries: Int = 0
    /// The "time slice" within the selected timeseries which is currently being shown
    private var sampleIndex: Int = 0
    /// Timer to continuously update the heatmap with various time slices
    private var timer: Timer?

    private var sampleVideoURL: URL? {
        return Bundle.main.url(forResource: "bw-squat-correct_side1", withExtension: "mov")
    }

    private lazy var sampleMeta: Timeseries.Meta = {
        return Timeseries.Meta(isLabeled: true,
                               exerciseName: "Bodyweight Squat",
                               exerciseDetail: "correct",
                               angle: .right)
    }()

    // MARK: - Initialization

    init() {
        avpController = AVPlayerViewController()
        super.init(nibName: nil, bundle: nil)
        self.title = "Analysis"

        setupVideoProcessor()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSampleVideo()
        setupHeatmapView()
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Private Functions

    private func setupVideoProcessor() {
        guard let url = sampleVideoURL else {
            print("URL resource not available!")
            return
        }

        let processor: VideoProcessor
        do {
            processor = try VideoProcessor(sampleLength: 5, insetPercent: 0.1, fps: 25, modelType: .cpm)
        } catch {
            print("Error while initializing VideoProcessor: \(error.localizedDescription)")
            return
        }

        processor.makeTimeseries(videoURL: url,
                                 meta: sampleMeta,
                                 onFinish: { [weak self] timeseriesArray in
                                    DispatchQueue.main.async {
                                        self?.finishedProcessing(results: timeseriesArray)
                                    }
            },
                                 onFailure: { errors in
                                    print("Video Processor finished with errors:")
                                    for error in errors {
                                        print("\t\(error.localizedDescription)")
                                    }
        })
    }

    private func finishedProcessing(results timeseriesArray: [Timeseries]) {
        self.timeseriesArray = timeseriesArray

        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            if let strongSelf = self,
                let timeseries = strongSelf.timeseriesArray.element(atIndex: strongSelf.selectedTimeseries) {
                strongSelf.updateHeatmapView(with: timeseries)
                strongSelf.sampleIndex = (strongSelf.sampleIndex + 1) % timeseries.numSamples
            }
        }

        setupHeatmapView()
    }

    private func setupHeatmapView() {
        guard !didSetupHeatmapView,
            let timeseries = timeseriesArray.element(atIndex: selectedTimeseries),
            poseViewContainer != nil else {
            return
        }

        activityIndicator?.stopAnimating()
        activityIndicator?.removeFromSuperview()
        infoLabel?.removeFromSuperview()

        do {
            let slice = try timeseries.timeSlice(forSample: sampleIndex)

            guard let model = HeatmapViewModel(heatmap: slice) else {
                print("Unable to initialize PoseViewModel from timeseries slice")
                return
            }

            let heatmapView = HeatmapView(model: model)
            poseViewContainer.addSubview(heatmapView)
            heatmapView.translatesAutoresizingMaskIntoConstraints = false
            heatmapView.leftAnchor.constraint(equalTo: poseViewContainer.leftAnchor).isActive = true
            heatmapView.rightAnchor.constraint(equalTo: poseViewContainer.rightAnchor).isActive = true
            heatmapView.topAnchor.constraint(equalTo: poseViewContainer.topAnchor).isActive = true
            heatmapView.bottomAnchor.constraint(equalTo: poseViewContainer.bottomAnchor).isActive = true
            self.heatmapView = heatmapView
            self.didSetupHeatmapView = true
        } catch {
            print(error)
        }
    }

    private func setupSampleVideo() {
        guard let path = sampleVideoURL else {
            return
        }

        player = AVPlayer(url: path)
        avpController.player = player
        avpController.view.frame = videoViewContainer.bounds
        addChild(avpController)
        videoViewContainer.addSubview(avpController.view)
    }

    private func updateHeatmapView(with timeseries: Timeseries) {
        guard let slice = try? timeseries.timeSlice(forSample: sampleIndex),
            let model = HeatmapViewModel(heatmap: slice) else {
                return
        }

        heatmapView?.configure(with: model)
    }

}

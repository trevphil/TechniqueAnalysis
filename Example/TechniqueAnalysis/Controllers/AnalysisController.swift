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
    private var sampleVideoURL: URL?

    @IBOutlet private weak var videoViewContainer: UIView!
    @IBOutlet private weak var poseViewContainer: UIView!
    @IBOutlet private weak var videoSelectionContainer: UIView!
    @IBOutlet private weak var videoSelectionContainerHeight: NSLayoutConstraint!
    private var videoSectionCollapsed = true
    @IBOutlet private weak var selectVideoButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet private weak var infoLabel: UILabel?
    private var heatmapView: HeatmapView?

    // Array of `Timeseries` objects derived from a sample video
    private var timeseriesArray = [Timeseries]()
    /// The index of timeseries from `timeseriesArray` to be shown in a heatmap
    private var selectedTimeseries: Int {
        let desired = 0
        return min(desired, timeseriesArray.count - 1)
    }
    /// The "time slice" within the selected timeseries which is currently being shown
    private var sampleIndex: Int = 0
    /// Timer to continuously update the heatmap with various time slices
    private var timer: Timer?

    // MARK: - Initialization

    init() {
        avpController = AVPlayerViewController()
        super.init(nibName: nil, bundle: nil)
        self.title = "Analysis"

        // setupVideoProcessor()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        addVideoSelectionController()
        videoSelectionContainerHeight.constant = 0
        videoSectionCollapsed = true
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Actions

    @IBAction private func selectVideo(_ sender: Any) {
        let animationDuration: TimeInterval = 0.5
        let maxContainerHeight: CGFloat = 250

        func collapse() {
            videoSelectionContainerHeight.constant = 0
            UIView.animate(withDuration: animationDuration, animations: { [weak self] in
                self?.view.layoutIfNeeded()
                },
                           completion: { [weak self] _ in
                            self?.selectVideoButton.setTitle("Show Video Selection", for: .normal)
                            self?.videoSectionCollapsed = true
            })
        }

        func expand() {
            videoSelectionContainerHeight.constant = maxContainerHeight
            UIView.animate(withDuration: animationDuration, animations: { [weak self] in
                self?.view.layoutIfNeeded()
                },
                           completion: { [weak self] _ in
                            self?.selectVideoButton.setTitle("Hide Video Selection", for: .normal)
                            self?.videoSectionCollapsed = false
            })
        }

        videoSectionCollapsed ? expand() : collapse()
    }

    // MARK: - Private Functions

    private func addVideoSelectionController() {
        let controller = VideoSelectionController()
        addChild(controller)
        videoSelectionContainer.addSubview(controller.view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.leftAnchor.constraint(equalTo: videoSelectionContainer.leftAnchor).isActive = true
        controller.view.rightAnchor.constraint(equalTo: videoSelectionContainer.rightAnchor).isActive = true
        controller.view.topAnchor.constraint(equalTo: videoSelectionContainer.topAnchor).isActive = true
        controller.view.bottomAnchor.constraint(equalTo: videoSelectionContainer.bottomAnchor).isActive = true
    }

/*
    private func setupVideoProcessor() {
        guard let url = sampleVideoURL else {
            print("URL resource not available!")
            return
        }

        let processor: VideoProcessor
        do {
            processor = try VideoProcessor(sampleLength: 5, insetPercent: 0.1, fps: 25, modelType: .cpm)
        } catch {
            print("Error while initializing VideoProcessor: \(error)")
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
                                        print("\t\(error)")
                                    }
        })
    }
*/
    private func finishedProcessing(results timeseriesArray: [Timeseries]) {
        self.timeseriesArray = timeseriesArray

        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            if let strongSelf = self,
                let timeseries = strongSelf.timeseriesArray.element(atIndex: strongSelf.selectedTimeseries) {
                strongSelf.updateHeatmapView(with: timeseries)
                strongSelf.sampleIndex = (strongSelf.sampleIndex + 1) % timeseries.numSamples
            }
        }

        // setupHeatmapView()
    }
/*
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
            activityIndicator?.removeFromSuperview()
            infoLabel?.text = "Video not found"
            return
        }

        player = AVPlayer(url: path)
        avpController.player = player
        avpController.view.frame = videoViewContainer.bounds
        addChild(avpController)
        videoViewContainer.addSubview(avpController.view)
    }
*/
    private func updateHeatmapView(with timeseries: Timeseries) {
        guard let slice = try? timeseries.timeSlice(forSample: sampleIndex),
            let model = HeatmapViewModel(heatmap: slice) else {
                return
        }

        heatmapView?.configure(with: model)
    }

}

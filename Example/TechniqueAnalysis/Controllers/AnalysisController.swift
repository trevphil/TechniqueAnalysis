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

    private let avpController: AVPlayerViewController
    private let processor: TAVideoProcessor?
    @IBOutlet private weak var videoViewContainer: UIView!
    @IBOutlet private weak var poseViewContainer: UIView!
    @IBOutlet private weak var processingCacheView: UIView?
    @IBOutlet private weak var videoSelectionContainer: UIView!
    @IBOutlet private weak var videoSelectionContainerHeight: NSLayoutConstraint!
    private var videoSectionCollapsed = true
    @IBOutlet private weak var selectVideoButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var infoLabel: UILabel!
    @IBOutlet private weak var bestGuessLabel: UILabel!
    @IBOutlet private weak var processingCacheStatus: UILabel?
    private weak var poseView: TAPoseView?

    // Array of `CompressedTimeseries` objects derived from a sample video
    private var timeseriesArray = [TATimeseries]()

    /// The index of timeseries from `timeseriesArray` to be shown in a heatmap
    private var selectedTimeseries: Int {
        let desired = 0
        return min(desired, timeseriesArray.count - 1)
    }

    /// The "time slice" within the selected timeseries which is currently being shown
    private var sampleIndex: Int = 0

    /// Timer to continuously update the heatmap with various time slices
    private var timer: Timer?

    /// Worker queue for running the Knn DTW algorithm
    private let algoQueue = DispatchQueue(label: "KnnDTW")

    // MARK: - Initialization

    init() {
        self.avpController = AVPlayerViewController()
        do {
            self.processor = try TAVideoProcessor(sampleLength: 5, insetPercent: 0.1, fps: 25, modelType: .cpm)
        } catch {
            print("Error while initializing TAVideoProcessor: \(error)")
            self.processor = nil
        }

        super.init(nibName: nil, bundle: nil)
        self.title = "Analysis"
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(avpController)
        videoViewContainer.addSubview(avpController.view)
        avpController.view.translatesAutoresizingMaskIntoConstraints = false
        avpController.view.leftAnchor.constraint(equalTo: videoViewContainer.leftAnchor).isActive = true
        avpController.view.rightAnchor.constraint(equalTo: videoViewContainer.rightAnchor).isActive = true
        avpController.view.topAnchor.constraint(equalTo: videoViewContainer.topAnchor).isActive = true
        avpController.view.bottomAnchor.constraint(equalTo: videoViewContainer.bottomAnchor).isActive = true

        addVideoSelectionController()
        videoSelectionContainerHeight?.constant = 0
        videoSectionCollapsed = true

        activityIndicator.isHidden = true
        infoLabel.text = "Select\na Video"
        bestGuessLabel.text = ""
        processingCacheStatus?.text = "Processing Labeled Data"
        processLabeledData()
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Actions

    @IBAction private func toggleVideoSelection(_ sender: UIButton?) {
        let animationDuration: TimeInterval = 0.5
        let maxContainerHeight: CGFloat = 250

        func collapse() {
            videoSelectionContainerHeight?.constant = 0
            UIView.animate(withDuration: animationDuration,
                           animations: { [weak self] in
                            self?.view.layoutIfNeeded()
                },
                           completion: { [weak self] _ in
                            self?.selectVideoButton?.setTitle("Show Video Selection", for: .normal)
                            self?.videoSectionCollapsed = true
            })
        }

        func expand() {
            videoSelectionContainerHeight?.constant = maxContainerHeight
            UIView.animate(withDuration: animationDuration,
                           animations: { [weak self] in
                            self?.view.layoutIfNeeded()
                },
                           completion: { [weak self] _ in
                            self?.selectVideoButton?.setTitle("Hide Video Selection", for: .normal)
                            self?.videoSectionCollapsed = false
            })
        }

        videoSectionCollapsed ? expand() : collapse()
    }

    // MARK: - Private Functions

    private func processLabeledData() {
        CacheManager.shared.processUncachedLabeledVideos(onItemProcessed: { [weak self] (current, total) in
            DispatchQueue.main.async {
                self?.processingCacheStatus?.text = "Processing Labeled Data (\(current)/\(total))"
            }
            },
                                                         onFinish: { [weak self] in
                                                            DispatchQueue.main.async {
                                                                self?.processingCacheView?.removeFromSuperview()
                                                            }
            },
                                                         onError: { errorMessage in
                                                            print(errorMessage)
        })
    }

    private func addVideoSelectionController() {
        let controller = VideoSelectionController(onVideoSelected: { (url, meta) in
            self.poseView?.removeFromSuperview()
            self.activityIndicator.isHidden = false
            self.infoLabel.isHidden = false
            self.infoLabel.text = "Processing\nVideo"
            self.toggleVideoSelection(nil)
            self.showVideoPreview(videoURL: url)
            self.processVideo(videoURL: url, meta: meta)
        })

        addChild(controller)
        videoSelectionContainer.addSubview(controller.view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.leftAnchor.constraint(equalTo: videoSelectionContainer.leftAnchor).isActive = true
        controller.view.rightAnchor.constraint(equalTo: videoSelectionContainer.rightAnchor).isActive = true
        controller.view.topAnchor.constraint(equalTo: videoSelectionContainer.topAnchor).isActive = true
        controller.view.bottomAnchor.constraint(equalTo: videoSelectionContainer.bottomAnchor).isActive = true
    }

    private func processVideo(videoURL: URL, meta: TAMeta) {
        bestGuessLabel.text = ""
        processor?.makeCompressedTimeseries(videoURL: videoURL,
                                            meta: meta,
                                            onFinish: { [weak self] compressedTimeseries in
                                                DispatchQueue.main.async {
                                                    self?.finishedProcessing(results: compressedTimeseries)
                                                }
            },
                                            onFailure: { errors in
                                                print("Video Processor finished with errors:")
                                                for error in errors {
                                                    print("\t\(error)")
                                                }
        })
    }

    private func finishedProcessing(results compressedTimeseries: [TATimeseries]) {
        self.timeseriesArray = compressedTimeseries

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            if let strongSelf = self,
                let timeseries = strongSelf.timeseriesArray.element(atIndex: strongSelf.selectedTimeseries) {
                strongSelf.updatePoseView(with: timeseries)
                strongSelf.sampleIndex = (strongSelf.sampleIndex + 1) % timeseries.numSamples
            }
        }

        if let series = compressedTimeseries.element(atIndex: selectedTimeseries) {
            bestGuessLabel.text = "Predicting..."
            let algo = TAKnnDtw(warpingWindow: 100, minConfidence: 0.2)
            algoQueue.async {
                let newText: String
                if let result = algo.nearestNeighbor(unknownItem: series, knownItems: CacheManager.shared.cached) {
                    newText = "Prediction: \(result.timeseries.meta.exerciseName), " +
                        "\(result.timeseries.meta.exerciseDetail), " +
                        "\(result.timeseries.meta.angle.rawValue.capitalized) (score=\(Int(result.score)))"
                } else {
                    newText = "No Prediction Available"
                }
                DispatchQueue.main.async {
                    self.bestGuessLabel.text = newText
                }
            }
        } else {
            bestGuessLabel.text = ""
        }

        configurePoseView()
    }

    private func configurePoseView() {
        guard let timeseries = timeseriesArray.element(atIndex: selectedTimeseries),
            poseViewContainer != nil else {
            return
        }

        activityIndicator.isHidden = true
        infoLabel.isHidden = true
        poseView?.removeFromSuperview()

        do {
            let slice = try timeseries.timeSlice(forSample: sampleIndex)
            let model = TAPoseViewModel(bodyPoints: slice, confidenceThreshold: 0.2)
            let poseView = TAPoseView(model: model, delegate: nil, jointLineColor: .red)

            poseViewContainer.addSubview(poseView)
            poseView.translatesAutoresizingMaskIntoConstraints = false
            poseView.leftAnchor.constraint(equalTo: poseViewContainer.leftAnchor).isActive = true
            poseView.rightAnchor.constraint(equalTo: poseViewContainer.rightAnchor).isActive = true
            poseView.topAnchor.constraint(equalTo: poseViewContainer.topAnchor).isActive = true
            poseView.bottomAnchor.constraint(equalTo: poseViewContainer.bottomAnchor).isActive = true
            self.poseView = poseView
        } catch {
            print(error)
        }
    }

    private func showVideoPreview(videoURL: URL) {
        let player = AVPlayer(url: videoURL)
        avpController.player = player
    }

    private func updatePoseView(with timeseries: TATimeseries) {
        guard let slice = try? timeseries.timeSlice(forSample: sampleIndex) else {
            return
        }

        let model = TAPoseViewModel(bodyPoints: slice, confidenceThreshold: 0.2)
        poseView?.configure(with: model)
    }

}

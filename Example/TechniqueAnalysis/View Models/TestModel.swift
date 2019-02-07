//
//  TestModel.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 07.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import TechniqueAnalysis

protocol TestModelDelegate: class {
    func didProcessLabeledData(_ index: Int, outOf total: Int)
    func didPredictUnlabeledData(atIndex index: Int, correctExercise: Bool, correctOverall: Bool, score: Double)
}

class TestModel {

    // MARK: - Properties

    let title: String
    private let selectedTimeseries = 0
    private let processor: TAVideoProcessor?
    private var labeledSeries: [TATimeseries]?
    private var currentlyTesting = 0
    private(set) var testableItems: [(url: URL, meta: TAMeta)]
    weak var delegate: TestModelDelegate?

    /// Worker queue for running the Knn DTW algorithm
    private let algoQueue = DispatchQueue(label: "KnnDTW")
    /// Algorithm instance
    private let algo = TAKnnDtw(warpingWindow: 100, minConfidence: 0.2)

    // MARK: - Initialization

    init() {
        self.title = "Tests"
        self.testableItems = VideoManager.shared.unlabeledVideos
        do {
            self.processor = try TAVideoProcessor(sampleLength: 5, insetPercent: 0.1, fps: 25, modelType: .cpm)
        } catch {
            print("Error while initializing TAVideoProcessor: \(error)")
            self.processor = nil
        }
    }

    // MARK: - Private Functions

    private func processLabeledData() {
        CacheManager.shared.processUncachedLabeledVideos(onItemProcessed: { [weak self] (current, total) in
            DispatchQueue.main.async {
                self?.delegate?.didProcessLabeledData(current, outOf: total)
            }
            },
                                                         onFinish: { [weak self] in
                                                            self?.beginTesting()
            },
                                                         onError: { errorMessage in
                                                            print(errorMessage)
        })
    }

    private func beginTesting() {
        labeledSeries = CacheManager.shared.cached
        testNext()
    }

    private func testNext() {
        let testIndex = currentlyTesting
        guard let nextUp = testableItems.element(atIndex: testIndex) else {
            return
        }

        processor?.makeCompressedTimeseries(videoURL: nextUp.url,
                                            meta: nextUp.meta,
                                            onFinish: { [weak self] timeseries in
                                                if let strongSelf = self,
                                                    let series = timeseries.element(atIndex: strongSelf.selectedTimeseries) {
                                                    strongSelf.compare(series, forIndex: testIndex)
                                                    strongSelf.currentlyTesting += 1
                                                    strongSelf.testNext()
                                                }
            },
                                            onFailure: { errors in
                                                print("Video Processor finished with errors:")
                                                for error in errors {
                                                    print("\t\(error)")
                                                }
        })
    }

    private func compare(_ unknown: TATimeseries, forIndex testIndex: Int) {
        guard let known = labeledSeries else {
            return
        }

        algoQueue.async { [weak self] in
            if let result = self?.algo.nearestNeighbor(unknownItem: unknown, knownItems: known) {
                let correctExercise = unknown.meta.exerciseName == result.timeseries.meta.exerciseName
                let correctOverall = correctExercise &&
                    unknown.meta.exerciseDetail == result.timeseries.meta.exerciseDetail &&
                    unknown.meta.angle == result.timeseries.meta.angle
                DispatchQueue.main.async {
                    self?.delegate?.didPredictUnlabeledData(atIndex: testIndex,
                                                            correctExercise: correctExercise,
                                                            correctOverall: correctOverall,
                                                            score: result.score)
                }

            }
        }
    }

}

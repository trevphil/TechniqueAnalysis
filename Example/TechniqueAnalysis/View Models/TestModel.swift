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
    func didBeginTesting()
    func didProcessLabeledData(_ index: Int, outOf total: Int)
    func didUpdateTestCase(atIndex index: Int)
}

class TestModel {

    // MARK: - Properties

    let title: String
    private let selectedTimeseries = 0
    private let processor: TAVideoProcessor?
    private var labeledSeries: [TATimeseries]?
    private var testCaseIndex = 0
    private(set) var testCases: [TestResult]
    weak var delegate: TestModelDelegate?

    /// Worker queue for running the Knn DTW algorithm
    private let algoQueue = DispatchQueue(label: "KnnDTW")
    /// Algorithm instance
    private let algo = TAKnnDtw(warpingWindow: 100, minConfidence: 0.2)

    // MARK: - Initialization

    init() {
        self.title = "Tests"

        self.testCases = VideoManager.shared.unlabeledVideos.map {
            TestResult(url: $0.url, testMeta: $0.meta)
        }

        do {
            self.processor = try TAVideoProcessor(sampleLength: 5, insetPercent: 0.1, fps: 25, modelType: .cpm)
        } catch {
            print("Error while initializing TAVideoProcessor: \(error)")
            self.processor = nil
        }
    }

    // MARK: - Exposed Functions

    func beginTesting() {
        CacheManager.shared.processUncachedLabeledVideos(onItemProcessed: { [weak self] (current, total) in
            DispatchQueue.main.async {
                self?.delegate?.didProcessLabeledData(current, outOf: total)
            }
            },
                                                         onFinish: { [weak self] in
                                                            self?.labeledSeries = CacheManager.shared.cached
                                                            self?.testNext()
                                                            DispatchQueue.main.async {
                                                                self?.delegate?.didBeginTesting()
                                                            }
            },
                                                         onError: { errorMessage in
                                                            print(errorMessage)
        })
    }

    // MARK: - Private Functions

    private func testNext() {
        let testIndex = testCaseIndex
        guard let testCase = testCases.element(atIndex: testIndex) else {
            return
        }

        processor?.makeTimeseries(videoURL: testCase.url,
                                  meta: testCase.testMeta,
                                  onFinish: { [weak self] timeseries in
                                    if let strongSelf = self,
                                        let series = timeseries.element(atIndex: strongSelf.selectedTimeseries) {
                                        strongSelf.compare(series, forIndex: testIndex)
                                        strongSelf.testCaseIndex += 1
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

        let testIndex = testCaseIndex

        algoQueue.async { [weak self] in
            if let result = self?.algo.nearestNeighbor(unknownItem: unknown, knownItems: known) {
                self?.testCases.element(atIndex: testIndex)?.predictionScore = result.score
                self?.testCases.element(atIndex: testIndex)?.predictionMeta = result.timeseries.meta
                DispatchQueue.main.async {
                    self?.delegate?.didUpdateTestCase(atIndex: testIndex)
                }

            }
        }
    }

}

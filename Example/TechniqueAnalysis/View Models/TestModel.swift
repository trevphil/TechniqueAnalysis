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
    func didUpdateTestCase(atIndex index: Int)
}

class TestModel {

    struct TestCase {
        let url: URL
        let meta: TAMeta
        let predictionScore: Double?
        let predictedCorrectExercise: Bool?
        let predictedCorrectOverall: Bool?
    }

    // MARK: - Properties

    let title: String
    private let selectedTimeseries = 0
    private let processor: TAVideoProcessor?
    private var labeledSeries: [TATimeseries]?
    private var testCaseIndex = 0
    private(set) var testCases: [TestCase]
    weak var delegate: TestModelDelegate?

    /// Worker queue for running the Knn DTW algorithm
    private let algoQueue = DispatchQueue(label: "KnnDTW")
    /// Algorithm instance
    private let algo = TAKnnDtw(warpingWindow: 100, minConfidence: 0.2)

    // MARK: - Initialization

    init() {
        self.title = "Tests"

        self.testCases = VideoManager.shared.unlabeledVideos.map {
            TestCase(url: $0.url,
                     meta: $0.meta,
                     predictionScore: nil,
                     predictedCorrectExercise: nil,
                     predictedCorrectOverall: nil)
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
                                  meta: testCase.meta,
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
            if let result = self?.algo.nearestNeighbor(unknownItem: unknown, knownItems: known),
                let currentTest = self?.testCases.element(atIndex: testIndex) {
                let correctExercise = unknown.meta.exerciseName == result.timeseries.meta.exerciseName
                let correctOverall = correctExercise &&
                    unknown.meta.exerciseDetail == result.timeseries.meta.exerciseDetail &&
                    unknown.meta.angle == result.timeseries.meta.angle
                let updatedTest = TestCase(url: currentTest.url,
                                           meta: currentTest.meta,
                                           predictionScore: result.score,
                                           predictedCorrectExercise: correctExercise,
                                           predictedCorrectOverall: correctOverall)
                self?.testCases[testIndex] = updatedTest
                DispatchQueue.main.async {
                    self?.delegate?.didUpdateTestCase(atIndex: testIndex)
                }

            }
        }
    }

}

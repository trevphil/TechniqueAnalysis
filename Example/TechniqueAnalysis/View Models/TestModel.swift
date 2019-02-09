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
    func didProcess(_ itemIndex: Int, outOf total: Int)
    func didBeginTestingCase(atIndex index: Int)
    func didFinishTestingCase(atIndex index: Int)
}

class TestModel {

    // MARK: - Properties

    let title: String
    private let printStats: Bool
    private let selectedTimeseries = 0
    private let processor: TAVideoProcessor?
    private var labeledSeries: [TATimeseries]?
    private var exerciseFilter: String?
    private var testCaseIndex = 0
    private(set) var testCases: [TestResult]
    weak var delegate: TestModelDelegate?
    private var processingFinishedObserver: NSObjectProtocol?
    private var itemProcessedObserver: NSObjectProtocol?

    var shouldWaitForProcessing: Bool {
        return !CacheManager.shared.processingFinished
    }

    /// Worker queue for running the Knn DTW algorithm
    private let algoQueue = DispatchQueue(label: "KnnDTW")
    /// Algorithm instance
    private let algo = TAKnnDtw(warpingWindow: Params.warpingWindow,
                                minConfidence: Params.minConfidence)

    // MARK: - Initialization

    init(testCases: [TestResult], printStats: Bool, exerciseFilter: String? = nil) {
        self.title = "Tests"
        self.printStats = printStats
        self.exerciseFilter = exerciseFilter
        self.testCases = testCases

        do {
            self.processor = try TAVideoProcessor(sampleLength: Params.clipLength,
                                                  insetPercent: Params.insetPercent,
                                                  fps: Params.fps,
                                                  modelType: Params.modelType)
        } catch {
            print("Error while initializing TAVideoProcessor: \(error)")
            self.processor = nil
        }

        subscribeToCacheNotifications()
    }

    deinit {
        unsubscribeFromCacheNotifications()
    }

    // MARK: - Exposed Functions

    func beginTesting() {
        if shouldWaitForProcessing {
            CacheManager.shared.processLabeledVideos()
        } else {
            self.labeledSeries = CacheManager.shared.cached
            self.testNext()
            self.delegate?.didBeginTesting()
        }
    }

    // MARK: - Private Functions

    private func testNext() {
        let testIndex = testCaseIndex
        guard let testCase = testCases.element(atIndex: testIndex) else {
            printTestStatistics()
            return
        }

        testCase.status = .running
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didBeginTestingCase(atIndex: testIndex)
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
        guard var known = labeledSeries else {
            return
        }

        if let filter = exerciseFilter {
            known = known.filter { $0.meta.exerciseName == filter }
        }

        let testIndex = testCaseIndex

        algoQueue.async { [weak self] in
            if let results = self?.algo.nearestNeighbors(unknownItem: unknown, knownItems: known) {
                self?.testCases.element(atIndex: testIndex)?.predictionScore = results.element(atIndex: 0)?.score
                self?.testCases.element(atIndex: testIndex)?.predictionMeta = results.element(atIndex: 0)?.series.meta
                self?.testCases.element(atIndex: testIndex)?.runnerUpScore = results.element(atIndex: 1)?.score
                self?.testCases.element(atIndex: testIndex)?.runnerUpMeta = results.element(atIndex: 1)?.series.meta
                self?.testCases.element(atIndex: testIndex)?.status = .finished
                DispatchQueue.main.async {
                    self?.delegate?.didFinishTestingCase(atIndex: testIndex)
                }
            }
        }
    }

    private func printTestStatistics() {
        guard printStats else {
            return
        }

        let correctExercises = Double(testCases.filter({ $0.predictedCorrectExercise == true }).count)
        let correctOverall = Double(testCases.filter({ $0.predictedCorrectOverall == true }).count)
        let total = Double(testCases.count)
        print("\n-------------- FINISHED TESTING (\(Int(total)) total) --------------")
        print("\(Int(round(correctExercises / total * 100.0)))% classified into correct exercise.")
        print("\(Int(round(correctOverall / total * 100.0)))% classified perfectly.")
        print("Params: \(Params.debugDescription)\n")
    }

    private func subscribeToCacheNotifications() {
        if processingFinishedObserver == nil {
            let processingFinished = CacheManager.CacheNotification.processingFinished.name
            processingFinishedObserver = NotificationCenter.default
                .addObserver(forName: processingFinished,
                             object: nil,
                             queue: .main) { _ in
                                self.labeledSeries = CacheManager.shared.cached
                                self.testNext()
                                self.delegate?.didBeginTesting()
            }
        }

        if itemProcessedObserver == nil {
            let processedItem = CacheManager.CacheNotification.processedItem.name
            itemProcessedObserver = NotificationCenter.default
                .addObserver(forName: processedItem,
                             object: nil,
                             queue: .main) { notification in
                                guard let current = notification.userInfo?["current"] as? Int,
                                    let total = notification.userInfo?["total"] as? Int else {
                                        return
                                }
                                self.delegate?.didProcess(current, outOf: total)
            }
        }
    }

    private func unsubscribeFromCacheNotifications() {
        if let processingFinishedObserver = processingFinishedObserver {
            NotificationCenter.default.removeObserver(processingFinishedObserver)
        }
        if let itemProcessedObserver = itemProcessedObserver {
            NotificationCenter.default.removeObserver(itemProcessedObserver)
        }
    }

}

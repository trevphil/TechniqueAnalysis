//
//  TestModel.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 07.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import TechniqueAnalysis

/// Delegate object which responds to events from `TestModel`
protocol TestModelDelegate: class {

    /// Notify the delegate on the main queue that testing began
    func didBeginTesting()

    /// Notify the delegate on the main queue that an item was processed from the labeled dataset
    ///
    /// - Parameters:
    ///   - itemIndex: The index of the item which was processed
    ///   - total: The total number of items being processed
    func didProcess(_ itemIndex: Int, outOf total: Int)

    /// Notify the delegate on the main queue that a test case has started
    ///
    /// - Parameter index: The index of the test case which was started
    func didBeginTestingCase(atIndex index: Int)

    /// Notify the delegate on the main queue that a test case has finished
    ///
    /// - Parameter index: The index of the test case which was finished
    func didFinishTestingCase(atIndex index: Int)

}

/// Model class which runs tests on unlabeled data points (videos) against the labeled dataset
class TestModel {

    // MARK: - Properties

    /// The model's title
    let title: String
    private let printStats: Bool
    private let onTestCaseSelected: ((TATimeseries, TATimeseries) -> Void)?
    private let selectedTimeseries = 0
    private let processor: TAVideoProcessor?
    private var labeledSeries: [TATimeseries]?
    private var testCaseIndex = 0
    /// An array of test cases which can be used to configure UI components
    private(set) var testCases: [TestResult]
    /// A delegate object responding to this model's events
    weak var delegate: TestModelDelegate?

    private var processingFinishedObserver: NSObjectProtocol?
    private var itemProcessedObserver: NSObjectProtocol?

    /// `true` if processing of the labeled dataset has not finished, and `false` otherwise
    var shouldWaitForProcessing: Bool {
        return !CacheManager.shared.processingFinished
    }

    /// Worker queue for running the Knn DTW algorithm
    private let algoQueue = DispatchQueue(label: "KnnDTW")
    /// Algorithm instance
    private let algo = TAKnnDtw(warpingWindow: Params.warpingWindow,
                                minConfidence: Params.minConfidence)

    // MARK: - Initialization

    /// Create a new instance of `TestModel`
    ///
    /// - Parameters:
    ///   - testCases: The test cases that the model should use when testing
    ///   - printStats: `true` if the model should print total statistics on failure and
    ///                 success rates at the end of testing, and `false` if it should be quiet
    ///   - onTestCaseSelected: A code block called when the user has selected a test case for
    ///                         closer inspection. The first `TATimeseries` in the closure is
    ///                         an unknown series, and the second `TATimeseries` is the most
    ///                         closely matching labeled timeseries from the dataset.
    init(testCases: [TestResult],
         printStats: Bool,
         onTestCaseSelected: ((TATimeseries, TATimeseries) -> Void)?) {
        self.title = "Tests"
        self.printStats = printStats
        self.testCases = testCases
        self.onTestCaseSelected = onTestCaseSelected

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

    /// Start testing. If the import of the labeled dataset has not finished,
    /// the model will first wait for this to finish before testing. Otherwise,
    /// testing will begin immediately.
    func beginTesting() {
        if shouldWaitForProcessing {
            CacheManager.shared.processLabeledVideos()
        } else {
            self.labeledSeries = CacheManager.shared.cached
            self.testNext()
            self.delegate?.didBeginTesting()
        }
    }

    /// Call this function to notify the model that a test case has been selected
    ///
    /// - Parameters:
    ///   - index: The index of the timeseries that was selected
    func didSelect(atIndex index: Int) {
        guard let testResult = testCases.element(atIndex: index),
            testResult.status == .finished,
            let unknown = testResult.unknownSeries,
            let known = testResult.bestGuess else {
                return
        }

        onTestCaseSelected?(unknown, known)
    }

    // MARK: - Private Functions

    private func testNext() {
        let testIndex = testCaseIndex
        guard let testCase = testCases.element(atIndex: testIndex) else {
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
                                        testCase.unknownSeries = series
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

        known = known.filter { $0.meta.exerciseName == unknown.meta.exerciseName }

        algoQueue.async { [weak self] in
            if let results = self?.algo.nearestNeighbors(unknownItem: unknown,
                                                         knownItems: known,
                                                         relevantBodyParts: unknown.bodyParts),
                let testCase = self?.testCases.element(atIndex: testIndex) {
                testCase.bestGuessScore = results.element(atIndex: 0)?.score
                testCase.bestGuess = results.element(atIndex: 0)?.series
                testCase.secondBestScore = results.element(atIndex: 1)?.score
                testCase.secondBest = results.element(atIndex: 1)?.series
                testCase.status = .finished
                StatisticsLogger.printRankings(unknown: unknown,
                                               rankings: results.map { ($0.0, $0.1) },
                                               upTo: 5)
                if testIndex == (self?.testCases.count ?? 0) - 1 {
                    self?.printTestStatistics()
                }
                DispatchQueue.main.async {
                    testCase.bestCostMatrix = UIImage.image(from: results.element(atIndex: 0)?.matrix)
                    testCase.secondBestCostMatrix = UIImage.image(from: results.element(atIndex: 1)?.matrix)
                    self?.delegate?.didFinishTestingCase(atIndex: testIndex)
                }
            }
        }
    }

    private func printTestStatistics() {
        guard printStats else {
            return
        }

        let logger = StatisticsLogger(testResults: testCases, labeledSeries: labeledSeries ?? [])
        logger.printResults()
        logger.simulateAndPrintRandomSelection()
        logger.simulateAndPrintMostCommon()
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

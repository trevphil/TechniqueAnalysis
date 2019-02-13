//
//  StatisticsLogger.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 13.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import TechniqueAnalysis

/// Utility class for printing results of a test session
class StatisticsLogger {

    // MARK: - Properties

    private let testResults: [TestResult]
    private let labeledSeries: [TATimeseries]

    private lazy var labeledMeta: [TAMeta] = {
        return labeledSeries.map { $0.meta }
    }()

    private var randomSelectionResults: [TestResult] {
        var fakeResults = [TestResult]()
        for result in testResults {
            let fakeResult = TestResult(url: result.url, testMeta: result.testMeta)
            fakeResult.bestGuessMeta = randomItem(for: result.testMeta.exerciseName)
            fakeResults.append(fakeResult)
        }
        return fakeResults
    }

    private var mostCommonResults: [TestResult] {
        var fakeResults = [TestResult]()
        for result in testResults {
            let fakeResult = TestResult(url: result.url, testMeta: result.testMeta)
            fakeResult.bestGuessMeta = mostCommonType(for: result.testMeta.exerciseName)
            fakeResults.append(fakeResult)
        }
        return fakeResults
    }

    // MARK: - Initialization

    /// Create a new instance of `StatisticsLogger`
    ///
    /// - Parameters:
    ///   - testResults: The results from a test that should be logged
    ///   - labeledSeries: The labeled dataset used for comparisons during testing
    init(testResults: [TestResult], labeledSeries: [TATimeseries]) {
        self.testResults = testResults
        self.labeledSeries = labeledSeries
    }

    // MARK: - Exposed Functions

    /// Print results of the test session given when this instance was initialized
    func printResults() {
        let results = testResults
        let correct = results.filter({ $0.predictedCorrectly == true })
        let correctScores = correct.compactMap({ $0.bestGuessScore }).map({ Int($0) }).sorted()
        let minScoreCorrect = correct.compactMap({ $0.bestGuessScore }).min() ?? Double.nan
        let maxScoreCorrect = correct.compactMap({ $0.bestGuessScore }).max() ?? Double.nan
        let incorrect = results.filter({ $0.predictedCorrectly == false })
        let incorrectScores = incorrect.compactMap({ $0.bestGuessScore }).map({ Int($0) }).sorted()
        let minScoreIncorrect = incorrect.compactMap({ $0.bestGuessScore }).min() ?? Double.nan
        let maxScoreIncorrect = incorrect.compactMap({ $0.bestGuessScore }).max() ?? Double.nan
        let total = Double(results.count)
        print("\n-------------- RESULTS (\(Int(total)) total test cases) --------------")
        print("\(Int(round(Double(correct.count) / total * 100.0)))% classified perfectly.\n")
        print("For items classified perfectly, min_distance=\(Int(minScoreCorrect)) " +
            "and max_distance=\(Int(maxScoreCorrect))\n\tdistances=\(correctScores)\n")
        print("For items classified NOT perfectly, min_distance=\(Int(minScoreIncorrect)) " +
            "and max_distance=\(Int(maxScoreIncorrect))\n\tdistances=\(incorrectScores)\n")
        print("Params: \(Params.debugDescription)\n")
    }

    /// Simulate the test session as though a random element from the labeled dataset
    /// was chosen as the "best guess" match for each test case
    func simulateAndPrintRandomSelection() {
        guard !labeledSeries.isEmpty else {
            return
        }

        let results = randomSelectionResults
        let header = "\n-------------- RESULTS FROM RANDOM SELECTION (\(results.count) total test cases) --------------"
        printGenericResults(results, headerMessage: header)
    }

    /// Simulate the test session under the assumption that for each test case (which has a known exercise name),
    /// we choose the item from the labeled dataset with the *same* exercise name that has an *exercise variation*
    /// which occurs most frequently
    func simulateAndPrintMostCommon() {
        guard !labeledSeries.isEmpty else {
            return
        }

        let results = mostCommonResults
        let header = "\n----------- RESULTS FROM MOST COMMON SELECTION (\(results.count) total test cases) -----------"
        printGenericResults(results, headerMessage: header)
    }

    // MARK: - Private Functions

    private func printGenericResults(_ results: [TestResult], headerMessage: String) {
        let total = Double(results.count)
        let correct = results.filter({ $0.predictedCorrectly == true })
        print(headerMessage)
        print("\(Int(round(Double(correct.count) / total * 100.0)))% classified perfectly.\n")
    }

    private func randomItem(for exerciseName: String) -> TAMeta? {
        let relevantMeta = labeledMeta.filter { $0.exerciseName == exerciseName }
        return relevantMeta.randomElement()
    }

    private func mostCommonType(for exerciseName: String) -> TAMeta? {
        let relevantMeta = labeledMeta.filter { $0.exerciseName == exerciseName }

        var frequencies = [String: Int]()
        for meta in relevantMeta {
            frequencies[meta.exerciseDetail] = (frequencies[meta.exerciseDetail] ?? 0) + 1
        }

        guard let mostCommonDetail = frequencies.max(by: { $0.1 < $1.1 })?.key else {
            return nil
        }

        return relevantMeta.first(where: { $0.exerciseDetail == mostCommonDetail })
    }

}

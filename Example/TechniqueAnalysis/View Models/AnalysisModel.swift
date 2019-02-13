//
//  AnalysisModel.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/8/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import TechniqueAnalysis

/// Delegate object which responds to events from `AnalysisModel`
protocol AnalysisModelDelegate: class {

    /// Called when video analysis has finished
    ///
    /// - Parameter result: The result of the video analysis
    func didAnalyze(with result: TestResult)

}

/// Model for technique analysis from a user-recorded video. Internally, it reuses `TestModel`.
class AnalysisModel {

    // MARK: - Properties

    private let tester: TestModel
    /// The model's title
    let title: String
    /// The name of the exercise being analyzed
    let exerciseName: String
    /// The video URL of the exercise being analyzed
    let videoURL: URL
    /// A delegate object responding to this model's events
    weak var delegate: AnalysisModelDelegate?

    // MARK: - Initialization

    /// Create a new instance of `AnalysisModel`
    ///
    /// - Parameters:
    ///   - exerciseName: The name of the exercise being analyzed
    ///   - videoURL: The video URL of the exercise being analyzed
    init(exerciseName: String, videoURL: URL) {
        self.title = "Analyze"
        self.exerciseName = exerciseName
        self.videoURL = videoURL
        let meta = TAMeta(isLabeled: false,
                          exerciseName: exerciseName,
                          exerciseDetail: nil,
                          angle: .unknown)
        let testCase = TestResult(url: videoURL, testMeta: meta)
        self.tester = TestModel(testCases: [testCase], printStats: false)
        self.tester.delegate = self
    }

    // MARK: - Exposed Functions

    /// Begin analyzing the input video
    func analyzeVideo() {
        tester.beginTesting()
    }

    /// Delete the video that was analyzed
    func deleteVideo() {
        _ = try? FileManager.default.removeItem(at: videoURL)
    }

}

extension AnalysisModel: TestModelDelegate {

    func didBeginTesting() {}

    func didProcess(_ itemIndex: Int, outOf total: Int) {}

    func didBeginTestingCase(atIndex index: Int) {}

    func didFinishTestingCase(atIndex index: Int) {
        guard let result = tester.testCases.element(atIndex: 0) else {
            return
        }

        delegate?.didAnalyze(with: result)
    }

}

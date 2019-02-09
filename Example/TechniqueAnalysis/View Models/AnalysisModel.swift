//
//  AnalysisModel.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/8/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import TechniqueAnalysis

protocol AnalysisModelDelegate: class {
    func didAnalyze(with result: TestResult)
}

class AnalysisModel {

    // MARK: - Properties

    let title: String
    let exerciseName: String
    let videoURL: URL
    private let tester: TestModel
    weak var delegate: AnalysisModelDelegate?

    // MARK: - Initialization

    init(exerciseName: String, videoURL: URL) {
        self.title = "Analyze"
        self.exerciseName = exerciseName
        self.videoURL = videoURL
        let meta = TAMeta(isLabeled: false,
                          exerciseName: exerciseName,
                          exerciseDetail: nil,
                          angle: .unknown)
        let testCase = TestResult(url: videoURL, testMeta: meta)
        self.tester = TestModel(testCases: [testCase],
                                printStats: false,
                                exerciseFilter: exerciseName)
        self.tester.delegate = self
    }

    // MARK: - Exposed Functions

    func analyzeVideo() {
        tester.beginTesting()
    }

    func deleteVideo() {
        _ = try? FileManager.default.removeItem(at: videoURL)
    }

}

extension AnalysisModel: TestModelDelegate {

    func didBeginTesting() {}

    func didProcess(_ itemIndex: Int, outOf total: Int) {}

    func didUpdateTestCase(atIndex index: Int) {
        guard let result = tester.testCases.element(atIndex: 0) else {
            return
        }

        delegate?.didAnalyze(with: result)
    }

}

//
//  TestResult.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 08.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import TechniqueAnalysis

class TestResult {

    enum Status {
        case notStarted, running, finished
    }

    // MARK: - Properties

    let url: URL
    let testMeta: TAMeta
    var predictionMeta: TAMeta?
    var predictionScore: Double?
    var runnerUpMeta: TAMeta?
    var runnerUpScore: Double?
    var status: Status = .notStarted

    var predictedCorrectExercise: Bool? {
        guard let predictionMeta = predictionMeta else {
            return nil
        }

        return testMeta.exerciseName == predictionMeta.exerciseName
    }

    var predictedCorrectOverall: Bool? {
        guard let predictionMeta = predictionMeta, let correctExercise = predictedCorrectExercise else {
            return nil
        }

        return correctExercise &&
            testMeta.exerciseDetail == predictionMeta.exerciseDetail &&
            testMeta.angle == predictionMeta.angle
    }

    // MARK: - Initialization

    init(url: URL, testMeta: TAMeta) {
        self.url = url
        self.testMeta = testMeta
    }

}

//
//  AnalysisCoordinator.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/8/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class AnalysisCoordinator {

    // MARK: - Properties

    private let navController: UINavigationController
    private var exerciseName: String?
    private var videoURL: URL?

    // MARK: - Initialization

    init() {
        navController = UINavigationController()
        navController.navigationBar.barTintColor = .black
        navController.navigationBar.barStyle = .blackOpaque
    }

    // MARK: - Exposed Functions

    func start() -> UIViewController {
        let model = ExerciseSelectionModel()
        navController.title = "Analysis"
        let exerciseSelection = ExerciseSelectionController(model: model) { exercise in
            self.exerciseName = exercise
            self.showVideoRecorder()
        }
        navController.setViewControllers([exerciseSelection], animated: false)
        return navController
    }

    // MARK: - Private Functions

    private func showVideoRecorder() {
        let recorder = RecorderController(model: RecorderModel()) { videoURL in
            self.videoURL = videoURL
            self.showAnalysis()
        }
        navController.pushViewController(recorder, animated: true)
    }

    private func showAnalysis() {
        guard let exerciseName = exerciseName,
            let url = videoURL else {
                return
        }

        let model = AnalysisModel(exerciseName: exerciseName, videoURL: url)
        let analysis = AnalysisController(model: model)
        navController.pushViewController(analysis, animated: true)
    }

}

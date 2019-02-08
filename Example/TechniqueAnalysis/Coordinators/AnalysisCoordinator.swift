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
    private var exerciseSelectionController: ExerciseSelectionController?
    private var recorderController: RecorderController?
    private var analysisController: AnalysisController?
    private var exerciseType: String?
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
        navController.title = model.title

        let exerciseSelection = ExerciseSelectionController(model: model) { exercise in
            self.exerciseType = exercise
            self.showVideoRecorder()
        }
        self.exerciseSelectionController = exerciseSelection

        navController.setViewControllers([exerciseSelection], animated: false)
        return navController
    }

    // MARK: - Private Functions

    private func showVideoRecorder() {
        if let recorder = recorderController {
            navController.pushViewController(recorder, animated: true)
            return
        }

        let recorder = RecorderController(model: RecorderModel()) { videoURL in
            self.videoURL = videoURL
            self.showAnalysis()
        }
        self.recorderController = recorder
        navController.pushViewController(recorder, animated: true)
    }

    private func showAnalysis() {
        if let analysis = analysisController {
            navController.pushViewController(analysis, animated: true)
            return
        }

        guard let exerciseType = exerciseType,
            let url = videoURL else {
                return
        }

        let model = AnalysisModel(exerciseType: exerciseType, videoURL: url)
        let analysis = AnalysisController(model: model)
        self.analysisController = analysis
        navController.pushViewController(analysis, animated: true)
    }

}

//
//  TestCoordinator.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 15.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

/// Coordinates flow when testing sample videos
class TestCoordinator {

    // MARK: - Properties

    private let navController: UINavigationController

    // MARK: - Initialization

    init() {
        navController = UINavigationController()
        navController.navigationBar.barTintColor = .black
        navController.navigationBar.barStyle = .blackOpaque
    }

    // MARK: - Exposed Functions

    /// Start the flow
    ///
    /// - Returns: The "root" view controller of the flow
    func start() -> UIViewController {
        let testCases = VideoManager.unlabeledVideos.map {
            TestResult(url: $0.url, testMeta: $0.meta)
        }

        let model = TestModel(testCases: testCases, printStats: true) { unknown, known in
            let stepper = StepperModel(unknownSeries: unknown, knownSeries: known)
            let stepperController = StepperController(model: stepper)
            self.navController.pushViewController(stepperController, animated: true)
        }

        navController.title = model.title
        let testController = TestController(model: model)
        navController.setViewControllers([testController], animated: false)
        return navController
    }

}

//
//  RootController.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 12/11/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

/// Root controller which manages child view controllers
class RootController: UITabBarController {

    // MARK: - Properties

    let model: RootModel

    // MARK: - Initialization

    /// Create a new instance of `RootController`
    ///
    /// - Parameter model: The model used to configure the instance
    init(model: RootModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureControllers()
        configureTabBar()
    }

    // MARK: - Private Functions

    private func configureControllers() {
        viewControllers = generateControllers()
        reloadInputViews()
        selectedIndex = model.initiallySelected
    }

    private func configureTabBar() {
        guard let items = tabBar.items else {
            return
        }

        for (idx, tab) in items.enumerated() {
            if let icon = model.string(for: idx)?.asImage?.withRenderingMode(.alwaysTemplate) {
                tab.image = icon
            }
        }
    }

    private func generateControllers() -> [UIViewController] {
        return model.viewModelTypes.map { type in
            switch type {
            case .heatmap(let heatmapModel):
                return HeatmapController(model: heatmapModel)
            case .joint(let jointModel):
                return JointController(model: jointModel)
            case .analysis:
                return AnalysisCoordinator().start()
            case .test(let testModel):
                return TestController(model: testModel)
            }
        }
    }

}

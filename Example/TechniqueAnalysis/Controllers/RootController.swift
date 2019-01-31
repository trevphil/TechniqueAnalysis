//
//  RootController.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 12/11/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

class RootController: UITabBarController {

    // MARK: - Initialization

    init() {
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
        let heatmapController = HeatmapController()
        let jointController = JointController()
        let analysisController = AnalysisController()
        viewControllers = [heatmapController, jointController, analysisController]
        reloadInputViews()
        selectedIndex = 0
    }

    private func configureTabBar() {
        if let heatmapTab = tabBar.items?[0], let fire = "🔥".asImage?.withRenderingMode(.alwaysTemplate) {
            heatmapTab.image = fire
        }
        if let jointTab = tabBar.items?[1], let arm = "💪".asImage?.withRenderingMode(.alwaysTemplate) {
            jointTab.image = arm
        }
        if let analysisTab = tabBar.items?[2], let video = "🎥".asImage?.withRenderingMode(.alwaysTemplate) {
            analysisTab.image = video
        }
    }

}

fileprivate extension String {

    var asImage: UIImage? {
        let size = CGSize(width: 35, height: 30)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.clear.set()
        let rect = CGRect(origin: .zero, size: size)
        UIRectFill(CGRect(origin: .zero, size: size))
        (self as NSString).draw(in: rect, withAttributes: [.font: UIFont.systemFont(ofSize: 30)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

}

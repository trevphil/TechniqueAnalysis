//
//  RootController.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 12/11/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import TechniqueAnalysis

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

        do {
            let processor = try VideoProcessor(sampleLength: 3, insetPercent: 0.1, fps: 20, modelType: .cpm)
            guard let url = Bundle.main.url(forResource: "pull-up-correct_front", withExtension: "mov") else {
                print("Resource not found!")
                return
            }

            let meta = Timeseries.Meta(isLabeled: true,
                                       exerciseName: "pull-ups",
                                       exerciseDetail: "correct-form",
                                       angle: .front)
            processor.makeTimeseries(videoURL: url,
                                     meta: meta,
                                     onFinish: { timeseries in
                                        print(timeseries)
            },
                                     onFailure: { error in
                                        print(error)
            })
        } catch {
            print(error)
        }
    }

    // MARK: - Private Functions

    private func configureControllers() {
        let heatmapController = HeatmapController()
        let jointController = JointController()
        viewControllers = [heatmapController, jointController]
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

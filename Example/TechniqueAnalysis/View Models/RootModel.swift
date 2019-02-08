//
//  RootModel.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 07.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

enum ModelType {
    case heatmap(HeatmapModel)
    case joint(JointModel)
    case analysis
    case test(TestModel)
}

struct RootModel {

    // MARK: - Properties

    private let tabIcons = ["🔥", "💪", "🎥", "✔️"]
    let initiallySelected = 0
    let viewModelTypes: [ModelType] = [
        .heatmap(HeatmapModel()),
        .joint(JointModel()),
        .analysis,
        .test(TestModel(testCases: VideoManager.shared.unlabeledVideos.map {
            TestResult(url: $0.url, testMeta: $0.meta)
        }, printStats: true))
    ]

    // MARK: - Exposed Functions

    func string(for tabIndex: Int) -> String? {
        return tabIcons.element(atIndex: tabIndex)
    }

}

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
    case analysis(AnalysisModel)
    case test(TestModel)
}

struct RootModel {

    // MARK: - Properties

    let initiallySelected = 0
    let viewModelTypes: [ModelType] = [
        .heatmap(HeatmapModel()),
        .joint(JointModel()),
        .analysis(AnalysisModel()),
        .test(TestModel())
    ]
    private let tabIcons = ["🔥", "💪", "🎥", "✔️"]

    // MARK: - Exposed Functions

    func string(for tabIndex: Int) -> String? {
        return tabIcons.element(atIndex: tabIndex)
    }

}

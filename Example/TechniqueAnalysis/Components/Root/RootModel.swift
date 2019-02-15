//
//  RootModel.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 07.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

/// Enum wrapper for various child models that the `RootModel` can have
enum ModelType {
    case heatmap(HeatmapModel)
    case joint(JointModel)
    case analysis
    case test
}

/// Model which determines the order of child view controllers and their respective models
struct RootModel {

    // MARK: - Properties

    private let tabIcons = ["🔥", "💪", "🎥", "✔️"]
    /// The initially selected view controller in the tab bar
    let initiallySelected = 0
    /// Array of `ModelType` objects, which also contains model objects wrapped inside
    let viewModelTypes: [ModelType]

    // MARK: - Initialization

    init() {
        viewModelTypes = [
            .heatmap(HeatmapModel()),
            .joint(JointModel()),
            .analysis,
            .test
        ]
    }

    // MARK: - Exposed Functions

    /// The string (which will be converted to an image) for a particular tab
    ///
    /// - Parameter tabIndex: The tab that the caller wants to know the string for
    /// - Returns: The string for the give tab index, or `nil` if out of bounds
    func string(for tabIndex: Int) -> String? {
        return tabIcons.element(atIndex: tabIndex)
    }

}

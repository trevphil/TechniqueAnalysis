//
//  RootCoordinator.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 12/11/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

/// Coordinates the "top-most" level of application flow
struct RootCoordinator {

    /// Start the flow
    ///
    /// - Returns: The "root" view controller of the flow
    func start() -> UIViewController {
        return RootController(model: RootModel())
    }

}

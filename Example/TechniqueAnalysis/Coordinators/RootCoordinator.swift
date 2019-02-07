//
//  RootCoordinator.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 12/11/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

struct RootCoordinator {

    func start() -> UIViewController? {
        return RootController(model: RootModel())
    }

}

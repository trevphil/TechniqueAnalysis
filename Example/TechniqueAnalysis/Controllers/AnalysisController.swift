//
//  AnalysisController.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/8/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class AnalysisController: UIViewController {

    // MARK: - Properties

    private let model: AnalysisModel

    // MARK: - Initialization

    init(model: AnalysisModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

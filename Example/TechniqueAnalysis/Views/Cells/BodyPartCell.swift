//
//  BodyPartCell.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/17/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import TechniqueAnalysis

/// Table view cell for visualizing a body part's movement over time
class BodyPartCell: UITableViewCell {

    // MARK: - Properties

    /// Cell identifier
    static let identifier = "BodyPartCell"

    @IBOutlet private weak var bodyPartNameLabel: UILabel!
    @IBOutlet private weak var timeseriesView: BodyPartTimeView!

    // MARK: - Exposed Functions

    /// Configure the cell based on the movement of a body part, over time
    ///
    /// - Parameter samples: Samples of point of a *single* body part, taken over time
    func configure(with samples: [TAPointEstimate]) {
        let firstSample = samples.element(atIndex: 0)?.bodyPart
        bodyPartNameLabel.text = firstSample?.asString ?? "(none)"
        timeseriesView.configure(with: samples)
    }

}

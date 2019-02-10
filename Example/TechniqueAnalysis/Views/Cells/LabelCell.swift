//
//  LabelCell.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 12/11/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

/// Table view cell for showing information about a body part's predicted location
class LabelCell: UITableViewCell {

    // MARK: - Properties

    /// Cell identifier
    static let identifier = "LabelCell"
    @IBOutlet private weak var primaryLabel: UILabel!
    @IBOutlet private weak var secondaryLabel: UILabel!

    // MARK: - Exposed Functions

    /// Configure a cell and update its UI
    ///
    /// - Parameters:
    ///   - mainText: The main text of the cell (e.g. "Head", "Left Hand")
    ///   - subText: Details about the cell, such as confidence level of a body part
    func configure(mainText: String, subText: String) {
        primaryLabel.text = mainText
        secondaryLabel.text = subText
    }

}

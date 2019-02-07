//
//  LabelCell.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 12/11/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

class LabelCell: UITableViewCell {

    // MARK: - Properties

    static let identifier = "LabelCell"
    @IBOutlet private weak var primaryLabel: UILabel!
    @IBOutlet private weak var secondaryLabel: UILabel!

    // MARK: - Exposed Functions

    func configure(mainText: String, subText: String) {
        primaryLabel.text = mainText
        secondaryLabel.text = subText
    }

}

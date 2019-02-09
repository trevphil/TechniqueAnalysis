//
//  ExerciseCell.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/8/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class ExerciseCell: UITableViewCell {

    // MARK: - Properties

    static let identifier = "ExerciseCell"
    @IBOutlet private weak var exerciseLabel: UILabel!
    @IBOutlet private weak var roundedContainer: UIView!

    // MARK: - Exposed Functions

    func configure(with exerciseName: String) {
        exerciseLabel.text = exerciseName
        roundedContainer.layer.cornerRadius = 5
    }

}

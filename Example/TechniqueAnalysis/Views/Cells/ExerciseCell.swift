//
//  ExerciseCell.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/8/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

/// Table view cell for selecting an exercise to videotape and analyze
class ExerciseCell: UITableViewCell {

    // MARK: - Properties

    /// Cell identifier
    static let identifier = "ExerciseCell"
    @IBOutlet private weak var exerciseLabel: UILabel!
    @IBOutlet private weak var roundedContainer: UIView!

    // MARK: - Exposed Functions

    /// Configure the cell based on an exercise name
    ///
    /// - Parameter exerciseName: The exercise name to use when updating UI
    func configure(with exerciseName: String) {
        exerciseLabel.text = exerciseName
        roundedContainer.layer.cornerRadius = 5
    }

}

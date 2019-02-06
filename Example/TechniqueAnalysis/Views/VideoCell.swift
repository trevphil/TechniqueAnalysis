//
//  VideoCell.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 01.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class VideoCell: UITableViewCell {

    // MARK: - Properties

    static let identifier = "VideoCell"
    @IBOutlet private weak var exerciseNameLabel: UILabel!
    @IBOutlet private weak var exerciseDetailLabel: UILabel!
    @IBOutlet private weak var cameraAngleLabel: UILabel!

    // MARK: - Exposed Functions

    func configure(exerciseName: String,
                   exerciseDetail: String,
                   cameraAngle: String) {
        exerciseNameLabel.text = exerciseName
        exerciseDetailLabel.text = exerciseDetail
        cameraAngleLabel.text = cameraAngle
    }

}

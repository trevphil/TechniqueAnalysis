//
//  TATimeseries+Additions.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 14.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import TechniqueAnalysis

extension TATimeseries {

    var bodyParts: [TABodyPart] {
        switch meta.exerciseName {
        case "Push Up":
            return [.top, .leftHip, .rightHip, .leftShoulder, .rightShoulder]
        case "Pull Up":
            return [.top, .neck, .leftWrist, .rightWrist]
        case "Bw Squat":
            return [.leftHip, .leftKnee, .rightHip, .rightKnee]
        default:
            return TABodyPart.allCases
        }
    }

}
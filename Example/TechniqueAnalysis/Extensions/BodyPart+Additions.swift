//
//  BodyPart+Additions.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 12/11/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import TechniqueAnalysis

extension BodyPart {

    static let jointLineColor = UIColor(red: 87.0/255.0, green: 1.0, blue: 211.0/255.0, alpha: 0.5)

    var color: UIColor {
        switch self {
        case .top:
            return .red
        case .neck:
            return .green
        case .rightShoulder:
            return .blue
        case .rightElbow:
            return .cyan
        case .rightWrist:
            return .white
        case .leftShoulder:
            return .yellow
        case .leftElbow:
            return .magenta
        case .leftWrist:
            return .orange
        case .rightHip:
            return .purple
        case .rightKnee:
            return .brown
        case .rightAnkle:
            return .black
        case .leftHip:
            return .darkGray
        case .leftKnee:
            return .lightGray
        case .leftAnkle:
            return .gray
        }
    }

    var asString: String {
        switch self {
        case .top:
            return "Top"
        case .neck:
            return "Neck"
        case .rightShoulder:
            return "Right Shoulder"
        case .rightElbow:
            return "Right Elbow"
        case .rightWrist:
            return "Right Wrist"
        case .leftShoulder:
            return "Left Shoulder"
        case .leftElbow:
            return "Left Elbow"
        case .leftWrist:
            return "Left Wrist"
        case .rightHip:
            return "Right Hip"
        case .rightKnee:
            return "Right Knee"
        case .rightAnkle:
            return "Right Ankle"
        case .leftHip:
            return "Left Hip"
        case .leftKnee:
            return "Left Knee"
        case .leftAnkle:
            return "Left Ankle"
        }
    }

}

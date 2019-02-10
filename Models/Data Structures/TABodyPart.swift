//
//  TABodyPart.swift
//  TechniqueAnalysis
//
//  Created by Trevor on 04.12.18.
//

import Foundation

/// Body parts which are tracked/predicted by the embedded pose estimation ML models
public enum TABodyPart: Int, CaseIterable, Codable {

    case top
    case neck
    case rightShoulder
    case rightElbow
    case rightWrist
    case leftShoulder
    case leftElbow
    case leftWrist
    case rightHip
    case rightKnee
    case rightAnkle
    case leftHip
    case leftKnee
    case leftAnkle

    /// Tuples indicating which body parts "connect" together at joint locations
    public static var joints: [(TABodyPart, TABodyPart)] {
        return [
            (.top, .neck),
            (.neck, .rightShoulder),
            (.rightShoulder, .rightElbow),
            (.rightElbow, .rightWrist),
            (.neck, .rightHip),
            (.rightHip, .rightKnee),
            (.rightKnee, .rightAnkle),
            (.neck, .leftShoulder),
            (.leftShoulder, .leftElbow),
            (.leftElbow, .leftWrist),
            (.neck, .leftHip),
            (.leftHip, .leftKnee),
            (.leftKnee, .leftAnkle)
        ]
    }

}

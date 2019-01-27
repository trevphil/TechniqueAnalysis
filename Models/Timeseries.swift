//
//  Timeseries.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 1/26/19.
//

import Foundation
import CoreML

public struct Timeseries {

    public enum CameraAngle {
        case front, back, left, right
    }

    public struct Meta {
        public let uuid = UUID()
        public let isLabeled: Bool
        public let exerciseName: String
        public let exerciseDetail: String
        public let angle: CameraAngle

        public init(isLabeled: Bool, exerciseName: String, exerciseDetail: String, angle: CameraAngle) {
            self.isLabeled = isLabeled
            self.exerciseName = exerciseName
            self.exerciseDetail = exerciseDetail
            self.angle = angle
        }
    }

    public let data: MLMultiArray
    public let meta: Meta

    public init(data: MLMultiArray, meta: Meta) {
        self.data = data
        self.meta = meta
    }

}

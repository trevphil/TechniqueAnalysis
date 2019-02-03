//
//  Timeseries.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 1/26/19.
//

import Foundation
import CoreML

public enum TimeseriesError: Error {
    case invalidShapeError(String)
    case indexOutOfBoundsError(String)
}

// TODO: - Consider making a compressed version of this where each item in `data`
// is a MLMultiArray of shape 14x1x1
public struct Timeseries {

    public enum CameraAngle: String {
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
        
        public var description: String {
            return "<Meta: labeled=\(isLabeled); name=\(exerciseName); " +
            "detail=\(exerciseDetail); angle=\(angle.rawValue); uuid=\(uuid)>"
        }
    }

    public let data: [MLMultiArray]
    public let meta: Meta

    public var numSamples: Int {
        return data.count
    }

    public init(data: [MLMultiArray], meta: Meta) throws {
        guard data.count > 0 && data.filter({ $0.shape.count != 3 }).count == 0 else {
            let message = "Timeseries initialized with invalid MLMultiArrays"
            throw TimeseriesError.invalidShapeError(message)
        }

        self.data = data
        self.meta = meta
    }

    public func timeSlice(forSample index: Int) throws -> MLMultiArray {
        guard let slice = data.element(atIndex: index) else {
            let message = "Index \(index) is not within the number of samples for the timeseries"
            throw TimeseriesError.indexOutOfBoundsError(message)
        }

        return slice
    }

}

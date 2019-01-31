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
    case multiArrayError(String)
}

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
    private let shape: [Int]

    public var numSamples: Int {
        return shape[0]
    }

    public init(data: MLMultiArray, meta: Meta) throws {
        guard data.shape.count == 4 else {
            let message = "Timeseries initialized with a MLMultiArray of shape \(data.intShape)"
            throw TimeseriesError.invalidShapeError(message)
        }

        self.data = data
        self.meta = meta
        self.shape = data.intShape
    }

    public func timeSlice(forSample index: Int) throws -> MLMultiArray {
        guard index >= 0 && index < numSamples else {
            let message = "Index \(index) is not within the number of samples for the timeseries"
            throw TimeseriesError.indexOutOfBoundsError(message)
        }

        let offset = data.strides[0].intValue * index
        let shape = Array(data.shape[1...])
        let strides = Array(data.strides[1...])
        let pointer = UnsafeMutableRawPointer(data.dataPointer + offset)

        do {
            return try MLMultiArray(dataPointer: pointer,
                                    shape: shape,
                                    dataType: data.dataType,
                                    strides: strides,
                                    deallocator: nil)
        } catch {
            throw TimeseriesError.multiArrayError("Unable to initialize MLMultiArray at address \(pointer)")
        }
    }

}

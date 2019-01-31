//
//  MLMultiArray+Additions.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 1/29/19.
//

import CoreML

extension MLMultiArray {

    /// Number of bytes from the start of one element in the multi-array to the start of the next element
    var unitStride: Int {
        switch dataType {
        case .double:
            return MemoryLayout<Double>.stride
        case .float32:
            return MemoryLayout<Float32>.stride
        case .int32:
            return MemoryLayout<Int32>.stride
        }
    }

    /// The shape of the multi-array, given as an integer array
    var intShape: [Int] {
        return shape.map { $0.intValue }
    }

    /// The total number of bytes the multi-array occupies in memory, starting from its `dataPointer`
    var totalSize: Int {
        let numStrides = shape[0].intValue * strides[0].intValue
        return numStrides * unitStride
    }

}

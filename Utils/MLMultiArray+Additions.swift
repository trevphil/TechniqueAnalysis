//
//  MLMultiArray+Additions.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 1/29/19.
//

import CoreML

extension MLMultiArray {

    var intShape: [Int] {
        return shape.map { $0.intValue }
    }

    var totalSize: Int {
        return (0..<shape.count).map { shape[$0].intValue * strides[$0].intValue }.reduce(0, +)
    }

}

//
//  Array+Additions.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 31.01.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

extension Array {

    /// Safely retrieve an element from an array
    ///
    /// - Parameter index: The index of the element you want to retrieve
    /// - Returns: The element, or `nil` if out of bounds (or if the element is `nil`)
    func element(atIndex index: Int) -> Element? {
        guard indices.contains(index) else {
            return nil
        }
        return self[index]
    }

}

//
//  Array+Additions.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 31.01.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

extension Array {

    func element(atIndex index: Int) -> Element? {
        guard indices.contains(index) else {
            return nil
        }
        return self[index]
    }

}

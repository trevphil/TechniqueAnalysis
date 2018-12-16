//
//  Array+Additions.swift
//  TechniqueAnalysis
//
//  Created by Trevor on 04.12.18.
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

//
//  NSObject+Additions.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 12/12/18.
//

import Foundation

extension NSObject {

    /// Returns the name of the class
    @objc class var className: String {
        return String(describing: self)
    }

    /// Returns the name of the instance's class
    var className: String {
        return String(describing: type(of: self))
    }

}

//
//  RawRepresentable+Additions.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/9/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

protocol NotificationName {
    var name: Notification.Name { get }
}

extension RawRepresentable where RawValue == String, Self: NotificationName {

    var name: Notification.Name {
        return Notification.Name(self.rawValue)
    }
}

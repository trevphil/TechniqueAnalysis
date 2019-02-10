//
//  RawRepresentable+Additions.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/9/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

/// Protocol for objects which should have a notification name
protocol NotificationName {

    /// The name of the notification
    var name: Notification.Name { get }

}

extension RawRepresentable where RawValue == String, Self: NotificationName {

    /// Allow String enums to have notification names
    var name: Notification.Name {
        return Notification.Name(self.rawValue)
    }

}

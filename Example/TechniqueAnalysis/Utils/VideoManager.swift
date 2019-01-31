//
//  VideoManager.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 1/31/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

struct VideoManager {

    let supportedFormats = [
        "avi", "flv", "wmv", "mov", "mp4"
    ]

    let testVideos: [URL]
    let trainVideos: [URL]

    init() {
        var test = [URL]()
        var train = [URL]()
        testVideos = test
        trainVideos = train

        if let path = Bundle.main.resourcePath,
            let contents = try? FileManager.default.contentsOfDirectory(atPath: path) {
            let videos = contents.filter { item -> Bool in
                let numChars = item.count
                let idx = item.index(item.startIndex, offsetBy: numChars - 3)
                return numChars > 4 && supportedFormats.contains(String(item[idx...]).lowercased())
            }
            for item in videos {
                print(item)
            }
        }
    }

}

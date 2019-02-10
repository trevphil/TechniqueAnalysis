//
//  VideoManager.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 1/31/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import TechniqueAnalysis

/// Manager of unlabeled and labeled videos included in the example project
struct VideoManager {

    // MARK: - Properties

    private static let supportedFormats = [
        "avi", "flv", "wmv", "mov", "mp4"
    ]

    /// An array of tuples with URLs of labeled videos, and their corresponding metadata
    static let labeledVideos: [(url: URL, meta: TAMeta)] = {
        return VideoManager.getLabeledVideos()
    }()

    /// An array of tuples with URLs of unlabeled videos, and their corresponding metadata
    static let unlabeledVideos: [(url: URL, meta: TAMeta)] = {
        return VideoManager.getUnlabeledVideos()
    }()

    // MARK: - Private Functions

    private static func videoFileNames() -> [String] {
        guard let path = Bundle.main.resourcePath,
            let contents = try? FileManager.default.contentsOfDirectory(atPath: path) else {
                return []
        }

        return contents.filter { item -> Bool in
            let numChars = item.count
            let idx = item.index(item.startIndex, offsetBy: numChars - 3)
            return numChars > 4 && supportedFormats.contains(String(item[idx...]).lowercased())
        }
    }

    private static func getLabeledVideos() -> [(URL, TAMeta)] {
        guard let path = Bundle.main.resourceURL else {
            return []
        }

        let videos = videoFileNames().sorted()
        return videos.compactMap { FileNamer.meta(from: $0, baseURL: path, isLabeled: true) }
    }

    private static func getUnlabeledVideos() -> [(URL, TAMeta)] {
        guard let path = Bundle.main.resourceURL else {
            return []
        }

        let videos = videoFileNames().sorted()
        return videos.compactMap { FileNamer.meta(from: $0, baseURL: path, isLabeled: false) }
    }

}

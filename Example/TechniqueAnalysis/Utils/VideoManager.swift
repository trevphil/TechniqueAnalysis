//
//  VideoManager.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 1/31/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import TechniqueAnalysis

struct VideoManager {

    // MARK: - Properties

    /// Shared Singleton Instance
    static let shared = VideoManager()

    private static let supportedFormats = [
        "avi", "flv", "wmv", "mov", "mp4"
    ]

    let labeledVideos: [(url: URL, meta: Meta)] = {
        return VideoManager.labeledVideos()
    }()

    let unlabeledVideos: [(url: URL, meta: Meta)] = {
        return VideoManager.unlabeledVideos()
    }()

    // MARK: - Initialization

    private init() {}

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

    private static func labeledVideos() -> [(URL, Meta)] {
        guard let path = Bundle.main.resourceURL else {
            return []
        }

        let videos = videoFileNames()
        return videos.compactMap { FileNamer.meta(from: $0, baseURL: path, isLabeled: true) }
    }

    private static func unlabeledVideos() -> [(URL, Meta)] {
        guard let path = Bundle.main.resourceURL else {
            return []
        }

        let videos = videoFileNames()
        return videos.compactMap { FileNamer.meta(from: $0, baseURL: path, isLabeled: false) }
    }

}

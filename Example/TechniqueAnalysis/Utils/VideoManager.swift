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

    let labeledVideos: [(url: URL, meta: Timeseries.Meta)]
    let unlabeledVideos: [(url: URL, meta: Timeseries.Meta)]

    // MARK: - Initialization

    private init() {
        labeledVideos = VideoManager.labeledVideos()
        unlabeledVideos = VideoManager.unlabeledVideos()
    }

    // MARK: - Public Functions

    static func setup() {
        // Empty (used to automatically initialize Singleton in memory)
    }

    // MARK: - Private Functions

    private static func videoFileNames() -> [String] {
        guard let path = Bundle.main.resourcePath,
            let contents = try? FileManager.default.contentsOfDirectory(atPath: path) else {
                return []
        }

        return contents.filter { item -> Bool in
            let numChars = item.count
            let idx = item.index(item.startIndex, offsetBy: numChars - 3)
            print(numChars > 4 && supportedFormats.contains(String(item[idx...]).lowercased()))
            return numChars > 4 && supportedFormats.contains(String(item[idx...]).lowercased())
        }
    }

    private static func noExtension(_ file: String) -> String {
        if let index = file.lastIndex(of: ".") {
            return String(file[..<index])
        }
        return file
    }

    private static func labeledVideos() -> [(URL, Timeseries.Meta)] {
        guard let path = Bundle.main.resourceURL else {
            return []
        }

        func parseLabeled(videoName: String, baseURL: URL) -> (url: URL, meta: Timeseries.Meta)? {
            let parts = noExtension(videoName).split(separator: "_").map { String($0) }
            guard parts.element(atIndex: 0) != "test",
                let name = parts.element(atIndex: 0)?.replacingOccurrences(of: "-", with: " ").capitalized,
                let description = parts.element(atIndex: 1)?.replacingOccurrences(of: "-", with: " ").capitalized,
                let angleString = parts.element(atIndex: 2),
                let angle = Timeseries.CameraAngle(rawValue: angleString) else {
                    return nil
            }

            let url = baseURL.appendingPathComponent(videoName, isDirectory: false)
            let meta = Timeseries.Meta(isLabeled: true, exerciseName: name, exerciseDetail: description, angle: angle)
            return (url, meta)
        }

        let videos = videoFileNames()
        return videos.compactMap { parseLabeled(videoName: $0, baseURL: path) }
    }

    private static func unlabeledVideos() -> [(URL, Timeseries.Meta)] {
        guard let path = Bundle.main.resourceURL else {
            return []
        }

        func parseUnlabeled(videoName: String, baseURL: URL) -> (url: URL, meta: Timeseries.Meta)? {
            let parts = noExtension(videoName).split(separator: "_").map { String($0) }
            guard parts.element(atIndex: 0) == "test",
                let name = parts.element(atIndex: 1)?.replacingOccurrences(of: "-", with: " ").capitalized,
                let description = parts.element(atIndex: 2)?.replacingOccurrences(of: "-", with: " ").capitalized,
                let angleString = parts.element(atIndex: 3),
                let angle = Timeseries.CameraAngle(rawValue: angleString) else {
                    return nil
            }

            let url = baseURL.appendingPathComponent(videoName, isDirectory: false)
            let meta = Timeseries.Meta(isLabeled: false, exerciseName: name, exerciseDetail: description, angle: angle)
            return (url, meta)
        }

        let videos = videoFileNames()
        return videos.compactMap { parseUnlabeled(videoName: $0, baseURL: path) }
    }

}

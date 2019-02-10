//
//  FileNamer.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 05.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import TechniqueAnalysis

/// Assistant for converting between filenames and `TAMeta` objects
struct FileNamer {

    // MARK: - Exposed Functions

    /// Converts a filename into a `TAMeta` object
    ///
    /// - Parameters:
    ///   - filename: The filename to parse
    ///   - baseURL: The URL path where the file is located (not including the file itself in the URL)
    ///   - isLabeled: `true` if the file is labeled data and `false` otherwise
    /// - Returns: A tuple with the newly created `TAMeta` object and the full URL to the corresponding video
    static func meta(from filename: String, baseURL: URL, isLabeled: Bool) -> (url: URL, meta: TAMeta)? {
        let name = noExtension(filename)
        let parts = name.split(separator: "_").map { String($0) }
        return isLabeled ?
            parseLabeled(parts: parts, videoName: filename, baseURL: baseURL) :
            parseUnlabeled(parts: parts, videoName: filename, baseURL: baseURL)
    }

    /// Converts a `TAMeta` object to a filename
    ///
    /// - Parameters:
    ///   - meta: The `TAMeta` object to convert
    ///   - ext: The desired extension for the filename
    /// - Returns: The constructed filename
    /// - Note: This is used by the cache manager to decide how to name the file for a cached timeseries
    static func dataFileName(from meta: TAMeta, ext: String) -> String {
        var parts = [
            meta.exerciseName.replacingOccurrences(of: " ", with: "-").lowercased(),
            meta.exerciseDetail.replacingOccurrences(of: " ", with: "-").lowercased(),
            meta.angle.rawValue
        ]

        if !meta.isLabeled {
            parts.insert("test", at: 0)
        }

        return "\(parts.joined(separator: "_")).\(ext)"
    }

    /// Removes the file extension from a filename
    ///
    /// - Parameter filename: The filename from which the extension should be removed
    /// - Returns: The same filename, but without the extension. Returns `nil` if the file
    ///            has no extension.
    static func fileExtension(_ filename: String) -> String? {
        guard let index = filename.lastIndex(of: "."),
            index != filename.endIndex else {
                return nil
        }

        let next = filename.index(after: index)
        return String(filename[next...])
    }

    // MARK: - Private Functions

    private static func noExtension(_ filename: String) -> String {
        if let index = filename.lastIndex(of: ".") {
            return String(filename[..<index])
        }
        return filename
    }

    private static func parseUnlabeled(parts: [String], videoName: String, baseURL: URL) -> (url: URL, meta: TAMeta)? {
        guard parts.element(atIndex: 0) == "test",
            let name = parts.element(atIndex: 1)?.replacingOccurrences(of: "-", with: " ").capitalized,
            let description = parts.element(atIndex: 2)?.replacingOccurrences(of: "-", with: " ").capitalized,
            let angleString = parts.element(atIndex: 3),
            let angle = TACameraAngle(rawValue: angleString) else {
                return nil
        }

        let url = baseURL.appendingPathComponent(videoName, isDirectory: false)
        let meta = TAMeta(isLabeled: false, exerciseName: name, exerciseDetail: description, angle: angle)
        return (url, meta)
    }

    private static func parseLabeled(parts: [String], videoName: String, baseURL: URL) -> (url: URL, meta: TAMeta)? {
        guard parts.element(atIndex: 0) != "test",
            let name = parts.element(atIndex: 0)?.replacingOccurrences(of: "-", with: " ").capitalized,
            let description = parts.element(atIndex: 1)?.replacingOccurrences(of: "-", with: " ").capitalized,
            let angleString = parts.element(atIndex: 2),
            let angle = TACameraAngle(rawValue: angleString) else {
                return nil
        }

        let url = baseURL.appendingPathComponent(videoName, isDirectory: false)
        let meta = TAMeta(isLabeled: true, exerciseName: name, exerciseDetail: description, angle: angle)
        return (url, meta)
    }

}

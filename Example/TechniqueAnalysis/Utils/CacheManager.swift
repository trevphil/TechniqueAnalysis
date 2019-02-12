//
//  CacheManager.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 05.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import TechniqueAnalysis

/// Manager class for saving/fetching cached `TATimeseries`
class CacheManager {

    /// Notification when the status of the cache has changed
    ///
    /// - processingFinished: Notification that all labeled items have been processed
    /// - processedItem: Notification that a new labeled item has been processed. Contains
    ///                  user info `"current"` and `"total"` (both `Int`) for the current progress.
    enum CacheNotification: String, NotificationName {
        case processingFinished = "processed_all_labeled_data"
        case processedItem = "processed_new_labeled_data_item"
    }

    // MARK: - Properties

    /// Shared Singleton instance
    static let shared = CacheManager()

    /// An array of cached `TATimeseries` objects
    private(set) var cached: [TATimeseries]
    private var processingQueue = [(url: URL, meta: TAMeta)]()
    private let processor: TAVideoProcessor?

    /// `true` if the manager has processed all labeled videos, and `false` otherwise
    var processingFinished: Bool {
        return processingQueue.isEmpty && cached.count >= VideoManager.labeledVideos.count
    }

    private static let cachedTimeseriesExtension = "ts"

    private static let cacheDirectory: String? = {
        return try? FileManager.default.url(for: .documentDirectory,
                                            in: .allDomainsMask,
                                            appropriateFor: nil,
                                            create: true).appendingPathComponent("timeseries_cache",
                                                                                 isDirectory: true).relativePath
    }()

    // MARK: - Initialization

    private init() {
        if let directory = CacheManager.cacheDirectory {
            try? FileManager.default.createDirectory(at: URL(fileURLWithPath: directory, isDirectory: true),
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)
        }

        CacheManager.clearCache()
        self.cached = CacheManager.retrieveCache()

        do {
            self.processor = try TAVideoProcessor(sampleLength: Params.clipLength,
                                                  insetPercent: Params.insetPercent,
                                                  fps: Params.fps,
                                                  modelType: Params.modelType)
        } catch {
            print("Error while initializing TAVideoProcessor in CacheManager: \(error)")
            self.processor = nil
        }
    }

    // MARK: - Exposed Functions

    /// Cache a `TATimeseries` in storage. Does not persist if app is deleted.
    ///
    /// - Parameter timeseries: The `TATimeseries` to cache
    /// - Returns: `true` if caching was successful and `false` otherwise
    func cache(_ timeseries: TATimeseries) -> Bool {
        let encoder = JSONEncoder()
        guard let directory = CacheManager.cacheDirectory,
            let data = try? encoder.encode(timeseries) else {
                return false
        }

        let filename = FileNamer.dataFileName(from: timeseries.meta,
                                              ext: CacheManager.cachedTimeseriesExtension)
        let filePath = URL(fileURLWithPath: directory,
                          isDirectory: true).appendingPathComponent(filename, isDirectory: false).relativePath

        _ = try? FileManager.default.removeItem(atPath: filePath)

        FileManager.default.createFile(atPath: filePath,
                                       contents: data,
                                       attributes: [:])
        cached.append(timeseries)
        return true
    }

    /// Process all labeled videos from the resource bundle, if they are not already cached
    func processLabeledVideos() {
        guard processingQueue.isEmpty else {
            print("CacheManager Error: Processing labeled videos is already in progress")
            return
        }

        let labeledVideos = VideoManager.labeledVideos
        let toProcess = labeledVideos.filter { !cache(contains: $0.meta) }
        if toProcess.isEmpty { return }

        self.processingQueue = toProcess
        processNext(originalSize: toProcess.count)
    }

    // MARK: - Private Functions

    private func notifyProcessingFinished() {
        NotificationCenter.default.post(name: CacheNotification.processingFinished.name, object: self)
    }

    private func notifyItemProcessed(_ itemIndex: Int, total: Int) {
        NotificationCenter.default.post(name: CacheNotification.processedItem.name,
                                        object: self,
                                        userInfo: [ "current": itemIndex, "total": total ])
    }

    private func cache(contains meta: TAMeta) -> Bool {
        return cached.contains(where: { cachedSeries -> Bool in
            cachedSeries.meta.exerciseName == meta.exerciseName &&
                cachedSeries.meta.exerciseDetail == meta.exerciseDetail &&
                cachedSeries.meta.angle == meta.angle &&
                cachedSeries.meta.isLabeled == meta.isLabeled
        })
    }

    private func processNext(originalSize: Int) {
        guard let next = processingQueue.popLast(),
            let processor = processor else {
                notifyProcessingFinished()
                return
        }

        processor.makeTimeseries(videoURL: next.url,
                                 meta: next.meta,
                                 onFinish: { results in
                                    for timeseries in results {
                                        _ = self.cache(timeseries)
                                    }

                                    if self.processingQueue.isEmpty {
                                        self.generateAndCacheReflections()
                                        self.notifyProcessingFinished()
                                    } else {
                                        self.notifyItemProcessed(originalSize - self.processingQueue.count,
                                                                 total: originalSize)
                                        self.processNext(originalSize: originalSize)
                                    }
        },
                                 onFailure: { _ in })
    }

    private static func clearCache() {
        guard let cacheDirectory = cacheDirectory,
            let contents = try? FileManager.default.contentsOfDirectory(atPath: cacheDirectory) else {
                return
        }

        for cachedItem in contents {
            if let fullPath = URL(string: cacheDirectory)?.appendingPathComponent(cachedItem, isDirectory: false) {
                _ = try? FileManager.default.removeItem(at: fullPath)
            }
        }
    }

    private static func retrieveCache() -> [TATimeseries] {
        guard let directory = cacheDirectory,
            let cachedFilenames = try? FileManager.default.contentsOfDirectory(atPath: directory).sorted() else {
                return []
        }

        var decodedSeries = [TATimeseries]()
        let decoder = JSONDecoder()

        for filename in cachedFilenames {
            let fileURL = URL(fileURLWithPath: directory, isDirectory: true).appendingPathComponent(filename)

            guard FileNamer.fileExtension(filename) == cachedTimeseriesExtension,
                let data = try? Data(contentsOf: fileURL),
                let decoded = try? decoder.decode(TATimeseries.self, from: data) else {
                    continue
            }

            decodedSeries.append(decoded)
            print("Loaded from cache: \(filename)")
        }

        return decodedSeries
    }

    private func generateAndCacheReflections() {
        let reflections = cached.compactMap({ $0.reflected })
        for reflection in reflections {
            _ = cache(reflection)
        }
    }

}

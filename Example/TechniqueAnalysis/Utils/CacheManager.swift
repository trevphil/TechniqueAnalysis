//
//  CacheManager.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 05.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import TechniqueAnalysis

struct CacheManager {

    // MARK: - Properties

    /// Shared Singleton Instance
    static let shared = CacheManager()

    let cache: [CompressedTimeseries]

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
        self.cache = CacheManager.retrieveCache()
    }

    // MARK: - Exposed Functions

    func cache(_ compressedTimeseries: CompressedTimeseries) -> Bool {
        let encoder = JSONEncoder()
        guard let directory = CacheManager.cacheDirectory,
            let data = try? encoder.encode(compressedTimeseries) else {
                return false
        }

        let filename = FileNamer.dataFileName(from: compressedTimeseries.meta,
                                              ext: CacheManager.cachedTimeseriesExtension)
        let filePath = URL(fileURLWithPath: directory,
                          isDirectory: true).appendingPathComponent(filename, isDirectory: false).relativePath

        _ = try? FileManager.default.removeItem(atPath: filePath)

        FileManager.default.createFile(atPath: filePath,
                                       contents: data,
                                       attributes: [:])
        return true
    }

    // MARK: - Private Functions

    private static func retrieveCache() -> [CompressedTimeseries] {
        guard let directory = cacheDirectory,
            let cachedFilenames = try? FileManager.default.contentsOfDirectory(atPath: directory) else {
                return []
        }

        var decodedSeries = [CompressedTimeseries]()
        let decoder = JSONDecoder()

        for filename in cachedFilenames {
            let fileURL = URL(fileURLWithPath: directory, isDirectory: true).appendingPathComponent(filename)

            guard FileNamer.fileExtension(filename) == cachedTimeseriesExtension,
                let data = try? Data(contentsOf: fileURL),
                let decoded = try? decoder.decode(CompressedTimeseries.self, from: data) else {
                    continue
            }

            decodedSeries.append(decoded)
        }

        return decodedSeries
    }

}

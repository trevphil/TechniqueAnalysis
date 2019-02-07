//
//  TAVideoProcessor.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 1/26/19.
//

import CoreML
import AVKit

public enum TAVideoProcessorError: Error {
    case initializationError(String)
    case noDataError(String)
    case filesystemAccessError(String)
}

public class TAVideoProcessor {

    // MARK: - Properties

    private let poseEstimationModel: TAPoseEstimationModel
    private let generatedVideosPath: URL
    private let sampleLength: TimeInterval
    private let insetPercent: Double
    private let fps: Double
    private let workerQueue = DispatchQueue(label: "video_processing")

    // MARK: - Initialization

    public init(sampleLength: TimeInterval,
                insetPercent: Double,
                fps: Double,
                modelType: TAPoseEstimationModel.ModelType) throws {
        guard let poseEstimationModel = TAPoseEstimationModel(type: modelType) else {
            throw TAVideoProcessorError.initializationError("Could not initialize underlying Pose Estimation Model")
        }

        guard let path = try? FileManager.default.url(for: .documentDirectory,
                                                      in: .allDomainsMask, appropriateFor: nil, create: true) else {
            throw TAVideoProcessorError.filesystemAccessError("Could not create URL path for generating video subclips")
        }

        self.generatedVideosPath = path.appendingPathComponent("sections", isDirectory: true)
        self.poseEstimationModel = poseEstimationModel
        self.sampleLength = sampleLength
        self.insetPercent = insetPercent
        self.fps = fps
        
        _ = try? FileManager.default.createDirectory(at: generatedVideosPath,
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)
    }

    // MARK: - Public Functions
    
    public func makeTimeseries(videoURL: URL,
                               meta: TAMeta,
                               onFinish: @escaping (([TATimeseries]) -> ()),
                               onFailure: @escaping (([Error]) -> ())) {
        workerQueue.async {
            self.processVideo(videoURL: videoURL, meta: meta) { series, errors in
                if errors.isEmpty {
                    onFinish(series)
                } else {
                    onFailure(errors)
                }
            }
        }
    }

    // MARK: - Private Functions

    private func processVideo(videoURL: URL,
                              meta: TAMeta,
                              onFinish: @escaping (([TATimeseries], [Error]) -> ())) {
        var timeseries = [Int: TATimeseries]()
        var errors = [Int: Error]()
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter() // ENTER 1
        makeSections(from: videoURL) { sectionURLs in
            
            for (idx, url) in sectionURLs.enumerated() {
                let asset = AVAsset(url: url)
                
                dispatchGroup.enter() // ENTER 2
                self.makeImages(from: asset) { images in

                    dispatchGroup.enter() // ENTER 3
                    self.makeTimeseries(from: &images, meta: meta) { series, error in
                        if let series = series { timeseries[idx] = series }
                        if let error = error { errors[idx] = error }
                        dispatchGroup.leave() // LEAVE 3
                    }

                    dispatchGroup.leave() // LEAVE 2
                }
            }
            self.cleanupSections(sectionURLs)

            dispatchGroup.leave() // LEAVE 1
        }
        
        dispatchGroup.notify(queue: workerQueue) {
            let sortedSeries = timeseries.keys.sorted().compactMap { timeseries[$0] }
            let sortedErrors = errors.keys.sorted().compactMap { errors[$0] }
            onFinish(sortedSeries, sortedErrors)
        }
    }

    private func subclipIntervals(totalLength: TimeInterval) -> [(start: TimeInterval, end: TimeInterval)] {
        let sections: [(TimeInterval, TimeInterval)]
        let inset = totalLength * insetPercent
        if totalLength <= sampleLength {
            sections = [(0, totalLength)]
        } else if totalLength <= (inset * 2) + (sampleLength * 2) {
            sections = [(totalLength/2 - sampleLength/2, totalLength/2 + sampleLength/2)]
        } else {
            sections = [
                (inset, inset + sampleLength),
                (totalLength - inset - sampleLength, totalLength - inset)
            ]
        }
        return sections
    }

    private func makeSections(from videoURL: URL, onFinish: @escaping (([URL]) -> ())) {
        var sectionURLs = [Int: URL]()
        let video = AVAsset(url: videoURL)
        let dispatchGroup = DispatchGroup()

        let videoExtension = videoURL.pathExtension
        let videoName = videoURL.lastPathComponent.replacingOccurrences(of: ".\(videoExtension)", with: "")
        let duration = TimeInterval(video.duration.value) / TimeInterval(video.duration.timescale)
        let sections = subclipIntervals(totalLength: duration)

        for (idx, section) in sections.enumerated() {
            let preset = AVAssetExportPresetHighestQuality
            guard let exportSession = AVAssetExportSession(asset: video, presetName: preset) else {
                continue
            }

            let sectionURL = generatedVideosPath.appendingPathComponent("\(videoName)_section\(idx).\(videoExtension)")
            _ = try? FileManager.default.removeItem(at: sectionURL)
            exportSession.outputURL = sectionURL
            exportSession.outputFileType = .mp4
            let startTime = CMTime(seconds: section.start, preferredTimescale: video.duration.timescale)
            let endTime = CMTime(seconds: section.end, preferredTimescale: video.duration.timescale)
            let timeRange = CMTimeRange(start: startTime, end: endTime)
            exportSession.timeRange = timeRange
            sectionURLs[idx] = sectionURL

            dispatchGroup.enter()
            exportSession.exportAsynchronously {
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: workerQueue) {
            let sorted = sectionURLs.keys.sorted().compactMap { sectionURLs[$0] }
            onFinish(sorted)
        }
    }

    private func cleanupSections(_ sectionURLs: [URL]) {
        for url in sectionURLs {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print("Error: Unable to remove generated section subclip: \(error)")
            }
        }
    }

    private func samples(for video: AVAsset) -> [NSValue] {
        let numSeconds = TimeInterval(video.duration.value) / TimeInterval(video.duration.timescale)
        let numSamples = Int(numSeconds * fps)

        var sampleTimes = [NSValue]()
        var current: Double = 0
        for _ in 0..<numSamples {
            let sample = CMTime(seconds: current, preferredTimescale: video.duration.timescale)
            sampleTimes.append(NSValue(time: sample))
            current += (1.0 / fps)
        }
        return sampleTimes
    }

    private func makeImages(from asset: AVAsset, onFinish: @escaping ((inout [CGImage]) -> ())) {
        var images = [Double: CGImage]()
        var sortedImages = [CGImage]()
        let sampleTimes = samples(for: asset)

        let generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let dispatchGroup = DispatchGroup()
        _ = (0..<sampleTimes.count).forEach { _ in dispatchGroup.enter() }
        
        let handler: AVAssetImageGeneratorCompletionHandler = { _, image, time, _, _ in
            if let image = image {
                images[time.seconds] = image
                sortedImages = images.keys.sorted().compactMap { images[$0] }
            }
            dispatchGroup.leave()
        }

        generator.generateCGImagesAsynchronously(forTimes: sampleTimes, completionHandler: handler)

        dispatchGroup.notify(queue: workerQueue) {
            onFinish(&sortedImages)
        }
    }
    
    private func makeTimeseries(from images: inout [CGImage],
                                meta: TAMeta,
                                onFinish: @escaping ((TATimeseries?, Error?) -> ())) {
        var heatmaps = [Int: MLMultiArray]()
        let dispatchGroup = DispatchGroup()
        
        for _ in (0..<images.count) { dispatchGroup.enter() }

        var idx: Int = 0
        while !images.isEmpty {
            // Iterate in this way to reduce CGImage memory allocations as we process them
            let image = images.removeFirst()
            makeHeatmap(from: image) { heatmap in
                if let heatmap = heatmap { heatmaps[idx] = heatmap }
                dispatchGroup.leave()
            }
            idx += 1
        }
        
        dispatchGroup.notify(queue: workerQueue) {
            do {
                let sortedHeatmaps = heatmaps.keys.sorted().compactMap { heatmaps[$0] }
                let timeseries = try TATimeseries(data: sortedHeatmaps, meta: meta)
                onFinish(timeseries, nil)
            } catch {
                onFinish(nil, error)
            }
        }
    }
    
    private func makeHeatmap(from image: CGImage, onFinish: @escaping ((MLMultiArray?) -> ())) {
        let failure = { (error: Error?) in
            print("Error applying CoreVision on cgImage: \(error?.localizedDescription ?? "(none)")")
            onFinish(nil)
        }
        
        poseEstimationModel.predictUsingVision(cgImage: image, onSuccess: onFinish, onFailure: failure)
    }

}

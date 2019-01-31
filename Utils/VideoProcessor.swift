//
//  VideoProcessor.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 1/26/19.
//

import CoreML
import AVKit

public enum VideoProcessorError: Error {
    case initializationError(String)
    case noDataError(String)
    case multiArrayError(String)
    case filesystemAccessError(String)
}

public class VideoProcessor {

    // MARK: - Properties

    private let poseEstimationModel: PoseEstimationModel
    private let generatedVideosPath: URL
    private let sampleLength: TimeInterval
    private let insetPercent: Double
    private let fps: Double
    private let workerQueue = DispatchQueue(label: "video_processing")

    // MARK: - Initialization

    public init(sampleLength: TimeInterval,
                insetPercent: Double,
                fps: Double,
                modelType: PoseEstimationModel.ModelType) throws {
        guard let poseEstimationModel = PoseEstimationModel(type: modelType) else {
            throw VideoProcessorError.initializationError("Could not initialize underlying Pose Estimation Model")
        }
        
        guard let path = try? FileManager.default.url(for: .sharedPublicDirectory,
                                                      in: .allDomainsMask, appropriateFor: nil, create: true) else {
            throw VideoProcessorError.filesystemAccessError("Could not create URL path for generating video subclips")
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
                               meta: Timeseries.Meta,
                               onFinish: @escaping (([Timeseries]) -> ()),
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
                              meta: Timeseries.Meta,
                              onFinish: @escaping (([Timeseries], [Error]) -> ())) {
        var timeseries = [Int: Timeseries]()
        var errors = [Int: Error]()
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter() // ENTER 1
        makeSections(from: videoURL) { sectionURLs in
            
            for (idx, url) in sectionURLs.enumerated() {
                let asset = AVAsset(url: url)
                
                dispatchGroup.enter() // ENTER 2
                self.makeImages(from: asset) { images in
                    
                    dispatchGroup.enter() // ENTER 3
                    self.makeTimeseries(from: images, meta: meta) { series, error in
                        
                        if let series = series { timeseries[idx] = series }
                        if let error = error { errors[idx] = error }
                        dispatchGroup.leave() // LEAVE 3
                    }
                    
                    dispatchGroup.leave() // LEAVE 2
                }
            }
            
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

    private func makeImages(from asset: AVAsset, onFinish: @escaping (([CGImage]) -> ())) {
        var images = [Double: CGImage]()
        let sampleTimes = samples(for: asset)

        let generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let dispatchGroup = DispatchGroup()
        _ = (0..<sampleTimes.count).forEach { _ in dispatchGroup.enter() }
        
        let handler: AVAssetImageGeneratorCompletionHandler = { _, image, time, _, _ in
            if let image = image {
                images[time.seconds] = image
            }
            dispatchGroup.leave()
        }

        generator.generateCGImagesAsynchronously(forTimes: sampleTimes, completionHandler: handler)

        dispatchGroup.notify(queue: workerQueue) {
            let sorted = images.keys.sorted().compactMap { images[$0] }
            onFinish(sorted)
        }
    }
    
    private func makeTimeseries(from images: [CGImage],
                                meta: Timeseries.Meta,
                                onFinish: @escaping ((Timeseries?, Error?) -> ())) {
        var heatmaps = [Int: MLMultiArray]()
        let dispatchGroup = DispatchGroup()
        
        for _ in (0..<images.count) { dispatchGroup.enter() }
        
        for (idx, image) in images.enumerated() {
            makeHeatmap(from: image) { heatmap in
                if let heatmap = heatmap { heatmaps[idx] = heatmap }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: workerQueue) {
            do {
                let sortedHeatmaps = heatmaps.keys.sorted().compactMap { heatmaps[$0] }
                let timeseries = try self.configuredTimeseries(meta: meta, heatmaps: sortedHeatmaps)
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
    
    private func configuredTimeseries(meta: Timeseries.Meta, heatmaps: [MLMultiArray]) throws -> Timeseries {
        guard let sampleItem = heatmaps.element(atIndex: 0) else {
            throw VideoProcessorError.noDataError("No heatmaps given for timeseries!")
        }
        
        guard sampleItem.strides.count == 3 && sampleItem.shape.count == 3 else {
            let errorMessage = "Timeseries slice has an invalid shape: \(sampleItem.intShape)"
            throw VideoProcessorError.multiArrayError(errorMessage)
        }
        
        let shape = [NSNumber(value: heatmaps.count)] + sampleItem.shape
        guard let multi = try? MLMultiArray(shape: shape, dataType: sampleItem.dataType) else {
            let errorMessage = "Error while initializing MLMultiArray with shape \(shape.map { $0.intValue })"
            throw VideoProcessorError.multiArrayError(errorMessage)
        }
        
        let base = multi.dataPointer
        for (idx, heatmap) in heatmaps.enumerated() {
            let src = heatmap.dataPointer
            let dest = base + idx * multi.strides[0].intValue
            memcpy(dest, src, heatmap.totalSize)
        }
        
        return try Timeseries(data: multi, meta: meta)
    }

}

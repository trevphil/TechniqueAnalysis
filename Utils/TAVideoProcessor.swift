//
//  TAVideoProcessor.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 1/26/19.
//

import CoreML
import AVKit

/// Error condition thrown by `TAVideoProcessor`
public enum TAVideoProcessorError: Error {
    case initializationError(String)
    case noDataError(String)
    case filesystemAccessError(String)
    case subclipError(String)
}

/// Video processor for converting video inta `TATimeseries`
public class TAVideoProcessor {

    // MARK: - Properties

    private let poseEstimationModel: TAPoseEstimationModel
    private let generatedVideosPath: URL
    private let sampleLength: TimeInterval
    private let insetPercent: Double
    private let fps: Double
    private let workerQueue = DispatchQueue(label: "video_processing")

    // MARK: - Initialization

    /// Create a new instance of `TAVideoProcessor`
    ///
    /// - Parameters:
    ///   - sampleLength: The maximum number of seconds that each sub-clip should have, when sampled from a video
    ///   - insetPercent: A decimal between [0, 1] for how far into the video sub-clips should be sampled.
    ///                   For example, a video with length 100s, `sampleLength`=5s, and `insetPercent`=0.1
    ///                   would create sub-clips spanning times [10s, 15s] and [85s, 90s].
    ///   - fps: The frames per second (data sample rate) used when constructing images from a video clip
    ///   - modelType: ML model type used to determine a person's pose within a video
    /// - Throws: `TAVideoProcessorError` if unable to initialize underlying ML model or bad filesystem access
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
    
    /// Construct an array of `TATimeseries` objects from a video
    ///
    /// - Parameters:
    ///   - videoURL: The URL of the video that will be processed
    ///   - meta: Meta-information about the video, such as name and detail
    ///   - onFinish: Callback when the video has been processed and a timeseries has been created.
    ///               The callback will not be executed on the main queue.
    ///   - onFailure: Callback when problems occurred during processing. An array of errors is passed.
    ///                The callback will not be executed on the main queue.
    /// - Warning: This function can be quite memory-intensive, and it is _not_ recommended to dispatch
    ///            this function if a previous call to the function has not finished.
    public func makeTimeseries(videoURL: URL,
                               meta: TAMeta,
                               onFinish: @escaping ((TATimeseries) -> ()),
                               onFailure: @escaping (([Error]) -> ())) {
        workerQueue.async {
            self.processVideo(videoURL: videoURL, meta: meta) { series, errors in
                if let series = series, errors.isEmpty {
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
                              onFinish: @escaping ((TATimeseries?, [Error]) -> ())) {
        var timeseries: TATimeseries?
        var errors = [Error]()
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter() // ENTER 1
        makeSubclip(from: videoURL) { subclipURL in

            guard let subclipURL = subclipURL else {
                errors.append(TAVideoProcessorError.subclipError("Unable to make subclip from video"))
                dispatchGroup.leave() // LEAVE 1
                return
            }
            
            let asset = AVAsset(url: subclipURL)

            dispatchGroup.enter() // ENTER 2
            self.makeImages(from: asset) { images in

                dispatchGroup.enter() // ENTER 3
                self.makeTimeseries(from: &images, meta: meta) { series, error in
                    if let series = series { timeseries = series }
                    if let error = error { errors.append(error) }
                    dispatchGroup.leave() // LEAVE 3
                }

                dispatchGroup.leave() // LEAVE 2
            }
            self.cleanupSubclip(subclipURL)

            dispatchGroup.leave() // LEAVE 1
        }
        
        dispatchGroup.notify(queue: workerQueue) {
            onFinish(timeseries, errors)
        }
    }

    private func subclipBounds(totalLength: TimeInterval) -> (start: TimeInterval, end: TimeInterval) {
        let inset = totalLength * insetPercent
        if totalLength <= sampleLength + inset {
            return (0, sampleLength)
        } else {
            return (inset, inset + sampleLength)
        }
    }

    private func makeSubclip(from videoURL: URL, onFinish: @escaping ((URL?) -> ())) {
        let video = AVAsset(url: videoURL)
        let videoExtension = videoURL.pathExtension
        let videoName = videoURL.lastPathComponent.replacingOccurrences(of: ".\(videoExtension)", with: "")
        let duration = TimeInterval(video.duration.value) / TimeInterval(video.duration.timescale)
        let bounds = subclipBounds(totalLength: duration)

        let preset = AVAssetExportPresetMediumQuality
        guard let exportSession = AVAssetExportSession(asset: video, presetName: preset) else {
            onFinish(nil)
            return
        }

        let subclipURL = generatedVideosPath.appendingPathComponent("\(videoName).\(videoExtension)")
        _ = try? FileManager.default.removeItem(at: subclipURL)
        exportSession.outputURL = subclipURL
        exportSession.outputFileType = .mp4
        let startTime = CMTime(seconds: bounds.start, preferredTimescale: video.duration.timescale)
        let endTime = CMTime(seconds: bounds.end, preferredTimescale: video.duration.timescale)
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        exportSession.timeRange = timeRange

        exportSession.exportAsynchronously {
            onFinish(subclipURL)
        }
    }

    private func cleanupSubclip(_ subclipURL: URL) {
        do {
            try FileManager.default.removeItem(at: subclipURL)
        } catch {
            print("Error: Unable to remove generated section subclip: \(error)")
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
        generator.appliesPreferredTrackTransform = true

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

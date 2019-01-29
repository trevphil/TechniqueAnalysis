//
//  VideoProcessor.swift
//  TechniqueAnalysis
//
//  Created by Trevor Phillips on 1/26/19.
//

import CoreML
import AVKit
import AVFoundation

public enum VideoProcessorError: Error {
    case initializationError(String)
    case noDataError(String)
    case multiArrayError(String)
}

public class VideoProcessor {

    // MARK: - Properties

    private let poseEstimationModel: PoseEstimationModel
    private let sampleLength: TimeInterval
    private let insetPercent: Double
    private let fps: Double
    private let workerQueue = DispatchQueue(label: "video_processing")
    private var dispatchGroup: DispatchGroup?
    private var heatmaps: [MLMultiArray]?

    private var documentsURL: URL? {
        return try? FileManager.default.url(for: .documentDirectory,
                                            in: .allDomainsMask,
                                            appropriateFor: nil,
                                            create: true)
    }

    // MARK: - Initialization

    public init(sampleLength: TimeInterval,
                insetPercent: Double,
                fps: Double,
                modelType: PoseEstimationModel.ModelType) throws {
        guard let poseEstimationModel = PoseEstimationModel(type: modelType) else {
            throw VideoProcessorError.initializationError("Could not initialize underlying Pose Estimation Model")
        }

        self.poseEstimationModel = poseEstimationModel
        self.sampleLength = sampleLength
        self.insetPercent = insetPercent
        self.fps = fps
        self.poseEstimationModel.delegate = self
    }

    // MARK: - Public Functions

    public func makeTimeseries(videoURL: URL,
                               meta: Timeseries.Meta,
                               onFinish: @escaping ((Timeseries) -> ()),
                               onFailure: @escaping ((Error) -> ())) {
        let dispatchGroup = DispatchGroup()
        let heatmaps = [MLMultiArray]()
        self.dispatchGroup = dispatchGroup
        self.heatmaps = heatmaps

        workerQueue.async {
            self.processVideo(videoURL: videoURL, dispatchGroup: dispatchGroup)

            dispatchGroup.notify(queue: self.workerQueue) {
                defer {
                    self.dispatchGroup = nil
                    self.heatmaps = nil
                }

                do {
                    let timeseries = try self.configuredTimeseries(meta: meta)
                    onFinish(timeseries)
                } catch {
                    onFailure(error)
                }
            }
        }
    }

    // MARK: - Private Functions

    private func processVideo(videoURL: URL, dispatchGroup: DispatchGroup) {
        dispatchGroup.enter()
        makeSections(from: videoURL) { videoURLs in
            for url in videoURLs {
                print(videoURLs.map { $0.absoluteString })
                let asset = AVAsset(url: url)
                dispatchGroup.enter()

                self.makeImages(from: asset) { images in
                    let buffers = images.compactMap { $0.asPixelBuffer }
                    print("\(buffers.count) pixel buffers generated")
                    for buffer in buffers {
                        dispatchGroup.enter()
                        self.poseEstimationModel.predictUsingVision(pixelBuffer: buffer)
                    }
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.leave()
        }
    }

    private func configuredTimeseries(meta: Timeseries.Meta) throws -> Timeseries {
        guard let heatmaps = heatmaps, let sampleItem = heatmaps.element(atIndex: 0) else {
            throw VideoProcessorError.noDataError("No heatmaps were created!")
        }

        let shape = [NSNumber(value: heatmaps.count)] + sampleItem.shape
        let dataType = sampleItem.dataType
        guard let multi = try? MLMultiArray(shape: shape, dataType: dataType) else {
            let errorMessage = "Error while initializing MLMultiArray with shape \(shape.map { $0.intValue })"
            throw VideoProcessorError.multiArrayError(errorMessage)
        }

        let blockSize = MemoryLayout<Double>.size * sampleItem.shape.map({ $0.intValue }).reduce(0, +)
        let base = multi.dataPointer
        for (idx, heatmap) in heatmaps.enumerated() {
            let src = heatmap.dataPointer
            let dest = base + blockSize * idx
            memcpy(dest, src, blockSize)
        }

        return Timeseries(data: multi, meta: meta)
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
        guard let docs = documentsURL else {
            onFinish([])
            return
        }

        var sectionURLs = [URL]()
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

            let sectionURL = docs.appendingPathComponent("\(videoName)_section\(idx).\(videoExtension)")
            _ = try? FileManager.default.removeItem(at: sectionURL)
            exportSession.outputURL = sectionURL
            exportSession.outputFileType = .mp4
            let startTime = CMTime(seconds: section.start, preferredTimescale: video.duration.timescale)
            let endTime = CMTime(seconds: section.end, preferredTimescale: video.duration.timescale)
            let timeRange = CMTimeRange(start: startTime, end: endTime)
            exportSession.timeRange = timeRange
            sectionURLs.append(sectionURL)

            dispatchGroup.enter()
            exportSession.exportAsynchronously {
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: workerQueue) {
            onFinish(sectionURLs)
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
        var images = [CGImage]()
        let generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = CMTime.zero
        generator.requestedTimeToleranceAfter = CMTime.zero
        let dispatchGroup = DispatchGroup()
        let sampleTimes = samples(for: asset)

        _ = (0..<sampleTimes.count).forEach { _ in dispatchGroup.enter() }
        let handler: AVAssetImageGeneratorCompletionHandler = { requestedTime, image, actualTime, result, error in
            if let image = image {
                images.append(image)
            }
            dispatchGroup.leave()
        }

        generator.generateCGImagesAsynchronously(forTimes: sampleTimes, completionHandler: handler)

        dispatchGroup.notify(queue: workerQueue) {
            onFinish(images)
        }
    }

}

extension VideoProcessor: PoseEstimationDelegate {

    public func visionRequestDidComplete(heatmap: MLMultiArray) {
        workerQueue.async {
            self.heatmaps?.append(heatmap)
            self.dispatchGroup?.leave()
        }
    }

    public func visionRequestDidFail(error: Error?) {}

    public func didSamplePerformance(inferenceTime: Double, executionTime: Double, fps: Int) {}

}

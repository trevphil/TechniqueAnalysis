//
//  ExerciseSelectionModel.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/8/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

/// Delegate object which responds to events from `ExerciseSelectionModel`
protocol ExerciseSelectionModelDelegate: class {

    /// Called on the main queue when an item from the labeled data set has been processed
    ///
    /// - Parameters:
    ///   - itemIndex: The index of the item which was processed
    ///   - total: The total number of items being processed
    func didProcess(_ itemIndex: Int, outOf total: Int)

    /// Alerts the delegate on the main queue, that all labeled data has been processed
    func didFinishProcessing()

}

/// Model which allows a user to pick an exercise that they want to videotape and analyze
class ExerciseSelectionModel {

    // MARK: - Properties

    /// The model's title
    let title: String
    /// A list of exercises that the user can choose from, to be analyzed
    let availableExercises: [String]
    /// A delegate object responding to this model's events
    weak var delegate: ExerciseSelectionModelDelegate?

    private var processingFinishedObserver: NSObjectProtocol?
    private var itemProcessedObserver: NSObjectProtocol?

    /// `true` if processing of the labeled dataset has not finished, and `false` otherwise
    var shouldWaitForProcessing: Bool {
        return !CacheManager.shared.processingFinished
    }

    // MARK: - Initialization

    init() {
        self.title = "Exercises"
        let exercises: Set<String> = Set(VideoManager.labeledVideos.map {
            $0.meta.exerciseName
        })
        self.availableExercises = Array(exercises).sorted()

        subscribeToCacheNotifications()
    }

    deinit {
        unsubscribeFromCacheNotifications()
    }

    // MARK: - Exposed Functions

    /// Process the labeled video dataset if necessary
    func processLabeledVideosIfNeeded() {
        if shouldWaitForProcessing {
            CacheManager.shared.processLabeledVideos()
        }
    }

    // MARK: - Private Functions

    private func subscribeToCacheNotifications() {
        if processingFinishedObserver == nil {
            let processingFinished = CacheManager.CacheNotification.processingFinished.name
            processingFinishedObserver = NotificationCenter.default
                .addObserver(forName: processingFinished,
                             object: nil,
                             queue: .main) { _ in
                                self.delegate?.didFinishProcessing()
            }
        }

        if itemProcessedObserver == nil {
            let processedItem = CacheManager.CacheNotification.processedItem.name
            itemProcessedObserver = NotificationCenter.default
                .addObserver(forName: processedItem,
                             object: nil,
                             queue: .main) { notification in
                                guard let current = notification.userInfo?["current"] as? Int,
                                    let total = notification.userInfo?["total"] as? Int else {
                                        return
                                }
                                self.delegate?.didProcess(current, outOf: total)
            }
        }
    }

    private func unsubscribeFromCacheNotifications() {
        if let processingFinishedObserver = processingFinishedObserver {
            NotificationCenter.default.removeObserver(processingFinishedObserver)
        }
        if let itemProcessedObserver = itemProcessedObserver {
            NotificationCenter.default.removeObserver(itemProcessedObserver)
        }
    }

}

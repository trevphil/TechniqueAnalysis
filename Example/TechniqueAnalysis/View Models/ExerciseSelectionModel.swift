//
//  ExerciseSelectionModel.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/8/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

protocol ExerciseSelectionModelDelegate: class {
    func didProcess(_ itemIndex: Int, outOf total: Int)
    func didFinishProcessing()
}

class ExerciseSelectionModel {

    // MARK: - Properties

    let title: String
    let availableExercises: [String]
    private var processingFinishedObserver: NSObjectProtocol?
    private var itemProcessedObserver: NSObjectProtocol?
    weak var delegate: ExerciseSelectionModelDelegate?

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

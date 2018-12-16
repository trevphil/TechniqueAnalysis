//
//  Measure.swift
//  TechniqueAnalysis
//
//  Created by Trevor on 04.12.18.
//

import Foundation

protocol PerformanceToolDelegate: class {
    func updateSample(inferenceTime: Double, executionTime: Double, fps: Int)
}

class PerformanceTool {

    private enum Label: String {
        case start, stop, endInference
    }
    
    // MARK: - Properties
    
    weak var delegate: PerformanceToolDelegate?
    private var index = -1
    private var measurements = [[Label: Double]]()
    private let capacity = 30

    // MARK: - Initialization
    
    init() {
        let now = CACurrentMediaTime()
        let measurement = [Label.start: now, Label.stop: now]
        measurements = Array(repeating: measurement, count: capacity)
    }
    
    // MARK: - Exposed Functions
    
    func start() {
        index = (index + 1) % capacity
        
        if measurements.indices.contains(index) {
            measurements[index] = [:]
        }
        
        label(.start)
    }
    
    func stop() {
        label(.stop)
        
        if let previous = measurement(beforeIndex: index),
            let current = measurements.element(atIndex: index),
            let startTime = current[.start],
            let endInferenceTime = current[.endInference],
            let endTime = current[.stop],
            let previousStartTime = previous[.start] {
            delegate?.updateSample(inferenceTime: endInferenceTime - startTime,
                                   executionTime: endTime - startTime,
                                   fps: Int(1 / (startTime - previousStartTime)))
        }
    }

    func endInference() {
        label(.endInference)
    }
    
    // MARK: - Private Functions

    private func label(_ label: Label) {
        if var measurement = measurements.element(atIndex: index) {
            measurement[label] = CACurrentMediaTime()
            measurements[index] = measurement
        }
    }
    
    private func measurement(beforeIndex index: Int) -> [Label: Double]? {
        return measurements.element(atIndex: (index + capacity - 1) % capacity)
    }
    
}

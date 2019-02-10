//
//  HeatmapController.swift
//  TechniqueAnalysis
//
//  Created by Trevor on 04.12.18.
//

import UIKit
import TechniqueAnalysis

/// Controller which shows a heatmap of the user's body in real time
class HeatmapController: UIViewController {

    // MARK: - Properties

    private let model: HeatmapModel
    @IBOutlet private weak var videoPreviewContainer: UIView!
    private var heatmapView: TAHeatmapView?

    // MARK: - Initialization

    /// Create a new instance of `HeatmapController`
    ///
    /// - Parameter model: The model used to configure the instance
    init(model: HeatmapModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
        self.title = model.title
        model.delegate = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        model.setupCameraPreview(withinView: videoPreviewContainer)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        model.tearDownCameraPreview()
    }

    // MARK: - Private Functions

    private func setupHeatmapView(with heatmapModel: TAHeatmapViewModel) {
        let hmView = TAHeatmapView(model: heatmapModel)
        view.addSubview(hmView)
        hmView.translatesAutoresizingMaskIntoConstraints = false
        hmView.leftAnchor.constraint(equalTo: videoPreviewContainer.leftAnchor).isActive = true
        hmView.rightAnchor.constraint(equalTo: videoPreviewContainer.rightAnchor).isActive = true
        hmView.topAnchor.constraint(equalTo: videoPreviewContainer.topAnchor).isActive = true
        hmView.bottomAnchor.constraint(equalTo: videoPreviewContainer.bottomAnchor).isActive = true
        hmView.backgroundColor = .clear
        self.heatmapView = hmView
    }

}

extension HeatmapController: HeatmapModelDelegate {

    func updateHeatmapView(with heatmapViewModel: TAHeatmapViewModel) {
        if let heatmapView = heatmapView {
            heatmapView.configure(with: heatmapViewModel)
        } else {
            setupHeatmapView(with: heatmapViewModel)
        }
    }

}

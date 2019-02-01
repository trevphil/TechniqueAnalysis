//
//  JointController.swift
//  TechniqueAnalysis
//
//  Created by Trevor on 04.12.18.
//

import UIKit
import CoreML
import TechniqueAnalysis

class JointController: UIViewController {

    // MARK: - Properties

    @IBOutlet private weak var videoPreviewContainer: UIView!
    @IBOutlet private weak var labelsTableView: UITableView!
    @IBOutlet private weak var inferenceLabel: UILabel!
    @IBOutlet private weak var etimeLabel: UILabel!
    @IBOutlet private weak var fpsLabel: UILabel!
    private var poseView: PoseView?

    private let model: PoseEstimationModel?
    private var tableData = [PointEstimate]()

    // MARK: - Initialization

    init() {
        self.model = PoseEstimationModel(type: .cpm)
        super.init(nibName: nil, bundle: nil)
        self.model?.delegate = self
        self.title = "Joints"
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        labelsTableView.dataSource = self
        labelsTableView.delegate = self
        labelsTableView.register(UINib(nibName: String(describing: LabelCell.self), bundle: nil),
                                 forCellReuseIdentifier: LabelCell.identifier)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model?.setupCameraPreview(withinView: videoPreviewContainer)
        if let poseView = poseView {
            videoPreviewContainer.bringSubviewToFront(poseView)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        model?.tearDownCameraPreview()
    }

    // MARK: - Private Functions

    private func setupPoseView(with poseModel: PoseViewModel) {
        let pose = PoseView(model: poseModel,
                            delegate: self,
                            jointLineColor: BodyPart.jointLineColor)
        videoPreviewContainer.addSubview(pose)
        pose.frame = videoPreviewContainer.bounds
        model?.videoPreviewLayer?.frame = videoPreviewContainer.bounds
        pose.setupOutputComponent()
        pose.backgroundColor = .clear
        self.poseView = pose
    }

    private func showKeypointsDescription(with bodyPoints: [PointEstimate]) {
        tableData = bodyPoints.sorted(by: {
            ($0.bodyPart?.rawValue ?? 0) < ($1.bodyPart?.rawValue ?? 1)
        })
        labelsTableView.reloadData()
    }

    private func text(for pointEstimate: PointEstimate) -> String {
        let xString = String(format: "%.3f", pointEstimate.point.x)
        let yString = String(format: "%.3f", pointEstimate.point.y)
        let coordinate = "(\(xString), \(yString))"
        let confidence = String(format: "%.3f", pointEstimate.confidence)
        return "\(coordinate), [\(confidence)]"
    }

}

extension JointController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LabelCell.identifier,
                                                       for: indexPath) as? LabelCell,
            let bodyPoint = tableData.element(atIndex: indexPath.row) else {
                return UITableViewCell()
        }

        cell.configure(mainText: bodyPoint.bodyPart?.asString ?? "Unknown",
                       subText: text(for: bodyPoint))
        return cell
    }

}

extension JointController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }

}

extension JointController: PoseEstimationDelegate {

    func visionRequestDidComplete(heatmap: MLMultiArray) {
        if let poseModel = PoseViewModel(heatmap: heatmap) {
            if let poseView = poseView {
                poseView.configure(with: poseModel)
            } else {
                setupPoseView(with: poseModel)
            }
            showKeypointsDescription(with: poseModel.bodyPoints)
        }
    }

    func visionRequestDidFail(error: Error?) {
        print("ERROR: - Vision request failed. Error=\(error?.localizedDescription ?? "(no message)")")
    }

    func didSamplePerformance(inferenceTime: Double, executionTime: Double, fps: Int) {
        inferenceLabel.text = "Inference: \(Int(inferenceTime * 1000.0)) mm"
        etimeLabel.text = "Execution: \(Int(executionTime * 1000.0)) mm"
        fpsLabel.text = "FPS: \(fps)"
    }

}

extension JointController: PoseViewDelegate {

    func color(for bodyPart: BodyPart) -> UIColor? {
        return bodyPart.color
    }

    func string(for bodyPart: BodyPart) -> String? {
        return bodyPart.asString
    }

}

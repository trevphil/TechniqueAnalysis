//
//  TestController.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 07.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class TestController: UIViewController {

    // MARK: - Properties

    @IBOutlet private weak var tableView: UITableView!
    private let model: TestModel

    // MARK: - Initialization

    init(model: TestModel) {
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

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.register(UINib(nibName: String(describing: VideoCell.self), bundle: nil),
                           forCellReuseIdentifier: VideoCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.backgroundColor = .black
        view.backgroundColor = .black
    }

}

extension TestController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.testableItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VideoCell.identifier,
                                                       for: indexPath) as? VideoCell,
            let videoMeta = model.testableItems.element(atIndex: indexPath.row)?.meta else {
                return UITableViewCell()
        }

        cell.configure(exerciseName: videoMeta.exerciseName,
                       exerciseDetail: videoMeta.exerciseDetail,
                       cameraAngle: videoMeta.angle.rawValue.capitalized,
                       correctExercise: nil,
                       correctOverall: nil)
        return cell
    }

}

extension TestController: TestModelDelegate {

    func didProcessLabeledData(_ index: Int, outOf total: Int) {
        <#code#>
    }

    func didPredictUnlabeledData(atIndex index: Int, correctExercise: Bool, correctOverall: Bool, score: Double) {
        <#code#>
    }


}

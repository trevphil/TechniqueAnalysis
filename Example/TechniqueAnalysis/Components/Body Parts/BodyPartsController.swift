//
//  BodyPartsController.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/17/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

/// A view controller which shows the movement of various body parts through time,
/// for some specific `TATimeseries` object
class BodyPartsController: UIViewController {

    // MARK: - Properties

    @IBOutlet private weak var exerciseNameLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    private let model: BodyPartsModel

    // MARK: - Initialization

    /// Create a new instance of `BodyPartsController`
    ///
    /// - Parameter model: The view model to use when configuring the object
    init(model: BodyPartsModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = model.title
        exerciseNameLabel.text = model.exerciseName
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 100
        tableView.register(UINib(nibName: String(describing: BodyPartCell.self), bundle: nil),
                           forCellReuseIdentifier: BodyPartCell.identifier)
    }

}

extension BodyPartsController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.numBodyParts
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BodyPartCell.identifier,
                                                       for: indexPath) as? BodyPartCell,
            let samples = model.bodyPartOverTime(indexPath.row) else {
                return UITableViewCell()
        }

        cell.configure(with: samples)
        return cell
    }

}

extension BodyPartsController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

}

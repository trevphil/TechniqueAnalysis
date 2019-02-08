//
//  ExerciseSelectionController.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor Phillips on 2/8/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class ExerciseSelectionController: UIViewController {

    // MARK: - Properties

    private let model: ExerciseSelectionModel
    private let onExerciseSelection: ((String) -> Void)
    @IBOutlet private weak var tableView: UITableView!

    // MARK: - Initialization

    init(model: ExerciseSelectionModel,
         onExerciseSelection: @escaping ((String) -> Void)) {
        self.model = model
        self.onExerciseSelection = onExerciseSelection
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorColor = .clear
        tableView.register(UINib(nibName: String(describing: ExerciseCell.self), bundle: nil),
                           forCellReuseIdentifier: ExerciseCell.identifier)
    }

}

extension ExerciseSelectionController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.availableExercises.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ExerciseCell.identifier,
                                                       for: indexPath) as? ExerciseCell,
            let exercise = model.availableExercises.element(atIndex: indexPath.row) else {
                return UITableViewCell()
        }

        cell.configure(with: exercise)
        return cell
    }

}

extension ExerciseSelectionController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let exercise = model.availableExercises.element(atIndex: indexPath.row) else {
            return
        }

        onExerciseSelection(exercise)
    }

}

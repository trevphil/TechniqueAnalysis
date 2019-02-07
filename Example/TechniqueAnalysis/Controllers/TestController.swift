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
        tableView.estimatedRowHeight = 100
        tableView.backgroundColor = .black
        view.backgroundColor = .black

        model.beginTesting()
    }

}

extension TestController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.testCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VideoCell.identifier,
                                                       for: indexPath) as? VideoCell,
            let testCase = model.testCases.element(atIndex: indexPath.row) else {
                return UITableViewCell()
        }

        cell.configure(with: testCase)
        return cell
    }

}

extension TestController: TestModelDelegate {

    func didUpdateTestCase(atIndex index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        tableView.reloadRows(at: [indexPath], with: .left)
    }

    func didProcessLabeledData(_ index: Int, outOf total: Int) {
        print("Processed \(index)/\(total)")
    }

}

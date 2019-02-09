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
    @IBOutlet private weak var processingStatusLabel: UILabel?
    @IBOutlet private weak var processingStatusHeight: NSLayoutConstraint?
    @IBOutlet private weak var processingStatusContainer: UIView?
    @IBOutlet private weak var processingActivityIndicator: UIActivityIndicatorView?
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
        tableView.register(UINib(nibName: String(describing: TestResultCell.self), bundle: nil),
                           forCellReuseIdentifier: TestResultCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.backgroundColor = .black
        view.backgroundColor = .black

        model.beginTesting()

        if model.shouldWaitForProcessing {
            processingStatusLabel?.text = "Processing..."
            processingStatusHeight?.constant = 100
        } else {
            hideProcessingHeader()
        }
    }

    // MARK: - Private Functions

    private func hideProcessingHeader() {
        processingStatusHeight?.constant = 0
        processingActivityIndicator?.isHidden = true
        UIView.animate(withDuration: 0.25,
                       animations: { [weak self] in
                        self?.view.layoutIfNeeded()
            },
                       completion: { [weak self] _ in
                        self?.processingStatusContainer?.isHidden = true
        })
    }

}

extension TestController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.testCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TestResultCell.identifier,
                                                       for: indexPath) as? TestResultCell,
            let testCase = model.testCases.element(atIndex: indexPath.row) else {
                return UITableViewCell()
        }

        cell.configure(with: testCase)
        return cell
    }

}

extension TestController: TestModelDelegate {

    func didBeginTesting() {
        hideProcessingHeader()
    }

    func didBeginTestingCase(atIndex index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    func didFinishTestingCase(atIndex index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        tableView.reloadRows(at: [indexPath], with: .left)
    }

    func didProcess(_ itemIndex: Int, outOf total: Int) {
        processingStatusLabel?.text = "Processed \(itemIndex)/\(total)"
    }

}

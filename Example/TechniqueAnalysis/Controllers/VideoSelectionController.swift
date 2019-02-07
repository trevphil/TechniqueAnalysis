//
//  VideoSelectionController.swift
//  TechniqueAnalysis_Example
//
//  Created by Trevor on 01.02.19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import TechniqueAnalysis

class VideoSelectionController: UIViewController {

    // MARK: - Properties

    let videos: [(url: URL, meta: TAMeta)]
    let onVideoSelected: ((URL, TAMeta) -> Void)
    @IBOutlet private weak var tableView: UITableView!

    // MARK: - Initialization

    init(onVideoSelected: @escaping ((URL, TAMeta) -> Void)) {
        self.videos = VideoManager.shared.unlabeledVideos
        self.onVideoSelected = onVideoSelected
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
        tableView.register(UINib(nibName: String(describing: VideoCell.self), bundle: nil),
                           forCellReuseIdentifier: VideoCell.identifier)

        tableView.backgroundColor = .black
        view.backgroundColor = .black
    }

}

extension VideoSelectionController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VideoCell.identifier,
                                                       for: indexPath) as? VideoCell,
            let video = videos.element(atIndex: indexPath.row) else {
                return UITableViewCell()
        }

        cell.configure(exerciseName: video.meta.exerciseName,
                       exerciseDetail: video.meta.exerciseDetail,
                       cameraAngle: video.meta.angle.rawValue.capitalized)
        return cell
    }

}

extension VideoSelectionController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let video = videos.element(atIndex: indexPath.row) else {
            return
        }
        onVideoSelected(video.url, video.meta)
    }

}

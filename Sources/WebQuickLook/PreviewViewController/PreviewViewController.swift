//
//  PreviewViewController.swift
//  QLDemo
//
//  Created by Home on 15/06/25.
//

import UIKit
import QuickLook

struct RemoteResource {
    let remoteURL: URL
    var result: Result<URL, any Error>?
}

// TODO: add option for lazy loading of files or load all at once
public class PreviewViewController: QLPreviewController {
    internal var resources: [RemoteResource] = []
    
    private var downloadTask: Task<Void, Never>?
    public init(remoteURLs: [URL]) {
        resources = remoteURLs.map {RemoteResource(remoteURL: $0)}
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
//        delegate = self
        
        downloadTask = Task {
            await DownloadHandler.shared.downloadFiles(from: resources.map(\.remoteURL)) { ind, res in
                await MainActor.run {
                    self.resources[ind].result = res
                    self.reloadData()
                }
            }
        }
    
//        if self.navigationItem.rightBarButtonItem == nil {
//            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissPreview))
//            self.navigationItem.rightBarButtonItem = doneButton
//        }
    }
    
//    @objc func dismissPreview() {
//        self.dismiss(animated: true, completion: nil)
//    }
}

// TODO: - implement delegate methodes
//extension PreviewViewController: QLPreviewControllerDelegate {}

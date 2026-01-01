//
//  PreviewViewController.swift
//  QLDemo
//
//  Created by Home on 15/06/25.
//

import UIKit
import QuickLook

public class PreviewViewController: QLPreviewController {

    private var remoteURLs: [URL] = []
    private var localFileURLs: [URL?] = []
    
    public init(remoteURLs: [URL]) {
        self.remoteURLs = remoteURLs
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        
        Task {
            self.localFileURLs = await DownloadHandler.shared.downloadFiles(from: remoteURLs)
            self.reloadData()
        }
    
        if self.navigationItem.rightBarButtonItem == nil {
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissPreview))
            self.navigationItem.rightBarButtonItem = doneButton
        }
    }
    
    @objc func dismissPreview() {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - QLPreviewControllerDataSource
extension PreviewViewController: QLPreviewControllerDataSource {
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return remoteURLs.count
    }

    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        // If file failed to download, show placeholder or error
        if index < localFileURLs.count, let url = localFileURLs[index] {
            return url as QLPreviewItem
        } else {
            // Use a local "error.txt" or placeholder PDF if desired
            let errorURL = FileManager.default.temporaryDirectory.appendingPathComponent("error.txt")
            if !FileManager.default.fileExists(atPath: errorURL.path) {
                try? "Failed to load file.".write(to: errorURL, atomically: true, encoding: .utf8)
            }
            return errorURL as QLPreviewItem
        }
    }
}

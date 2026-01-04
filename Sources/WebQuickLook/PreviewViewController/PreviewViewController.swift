//
//  PreviewViewController.swift
//  QLDemo
//
//  Created by Home on 15/06/25.
//

import UIKit
import QuickLook

public class PreviewViewController: QLPreviewController {

    internal var remoteURLs: [URL] = []
    internal var localFileURLs: [Result<URL, any Error>] = []
    
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
        delegate = self
        
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

// TODO: - implement delegate methodes
extension PreviewViewController: QLPreviewControllerDelegate {}

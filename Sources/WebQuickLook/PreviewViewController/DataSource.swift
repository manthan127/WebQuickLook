//
//  File.swift
//  
//
//  Created by Home on 04/01/26.
//

import QuickLook

extension PreviewViewController: QLPreviewControllerDataSource {
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return remoteURLs.count
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard index < localFileURLs.count else {
            return CallingAPIURL() as QLPreviewItem
        }
        
        let result = localFileURLs[index]
        
        switch result {
        case .success(let url):
            return url as QLPreviewItem
        case .failure(_):
            return failURL() as QLPreviewItem
        }
    }
}

private extension PreviewViewController {
    func failURL() -> URL {
        let errorURL = FileManager.default.temporaryDirectory.appendingPathComponent("error.txt")
        if !FileManager.default.fileExists(atPath: errorURL.path) {
            try? "Failed to load file.".write(to: errorURL, atomically: true, encoding: .utf8)
        }
        return errorURL
    }
    
    func CallingAPIURL() -> URL {
        let errorURL = FileManager.default.temporaryDirectory.appendingPathComponent("processing.txt")
        if !FileManager.default.fileExists(atPath: errorURL.path) {
            try? "API is Being Called".write(to: errorURL, atomically: true, encoding: .utf8)
        }
        return errorURL
    }
}

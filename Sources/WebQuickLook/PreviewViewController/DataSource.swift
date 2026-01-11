//
//  File.swift
//  
//
//  Created by Home on 04/01/26.
//

import QuickLook

extension PreviewViewController: QLPreviewControllerDataSource {
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return resources.count
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard index < resources.count, let result = resources[index].result else {
            return callingAPIURL() as QLPreviewItem
        }
        
        switch result {
        case .success(let url):
            return url as QLPreviewItem
        case .failure(let error):
            switch error {
            case let error as WebQuickLookError :
                return error.makeFile() as QLPreviewItem
            default:
                return failURL() as QLPreviewItem
            }
        }
    }
}

private extension PreviewViewController {
    func failURL() -> URL {
        WebQuickLook.config.downloadFailed ?? WebQuickLook.makeFile(name: "error", text: "Failed to load file.")
    }
    
    func callingAPIURL() -> URL {
        WebQuickLook.config.downloading ?? WebQuickLook.makeFile(name: "processing", text: "API is Being Called")
    }
}

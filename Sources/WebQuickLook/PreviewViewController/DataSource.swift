//
//  File.swift
//  
//
//  Created by Home on 04/01/26.
//

#if canImport(UIKit)
import QuickLook

extension PreviewViewController: QLPreviewControllerDataSource {
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return resources.count
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard index < resources.count, let result = resources[index].result else {
            return URL.callingAPIURL() as QLPreviewItem
        }
        
        switch result {
        case .success(let url):
            return url as QLPreviewItem
        case .failure(let error):
            return error.previewItem as QLPreviewItem
            // when showing this errors right now it's hard to tell which file has failed and in case of default why it has failed
        }
    }
}
#endif

//
//  File.swift
//  
//
//  Created by Home on 14/03/26.
//

import QuickLook

// TODO: - implement delegate methods
extension PreviewViewController: QLPreviewControllerDelegate {
    public func previewControllerWillDismiss(_ controller: QLPreviewController) {
        
    }
    
    public func previewControllerDidDismiss(_ controller: QLPreviewController) {
        
    }
    
    public func previewController(_ controller: QLPreviewController, shouldOpen url: URL, for item: any QLPreviewItem) -> Bool {
        true
    }
    //--
    public func previewController(
        _ controller: QLPreviewController, frameFor item: any QLPreviewItem,
        inSourceView view: AutoreleasingUnsafeMutablePointer<UIView?>
    ) -> CGRect {
        .zero
    }
    
    public func previewController(
        _ controller: QLPreviewController, transitionImageFor item: any QLPreviewItem, 
        contentRect: UnsafeMutablePointer<CGRect>
    ) -> UIImage? {
        nil
    }
    
    public func previewController(_ controller: QLPreviewController, transitionViewFor item: any QLPreviewItem) -> UIView? {
        nil
    }
    //--
    public func previewController(
        _ controller: QLPreviewController,
        editingModeFor previewItem: any QLPreviewItem
    ) -> QLPreviewItemEditingMode {
        .createCopy
    }
    
    public func previewController(
        _ controller: QLPreviewController,
        didUpdateContentsOf previewItem: any QLPreviewItem
    ) {
        
    }
    
    public func previewController(
        _ controller: QLPreviewController,
        didSaveEditedCopyOf previewItem: any QLPreviewItem,
        at modifiedContentsURL: URL
    ) {
        
    }
}

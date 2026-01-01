//
//  QuickLookPreview.swift
//  QLDemo
//
//  Created by Home on 15/06/25.
//

import SwiftUI

public struct QuickLookPreview: UIViewControllerRepresentable {
    let urls: [URL]
    public init(urls: [URL]) {
        self.urls = urls
    }
    
     public func makeUIViewController(context: Context) -> UIViewController {
        let previewVC = PreviewViewController(remoteURLs: urls)
        
        let navController = UINavigationController(rootViewController: previewVC)
        return navController
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

#Preview(body: {
    QuickLookPreview(urls: [URL(string: "")].compactMap({$0}))
})

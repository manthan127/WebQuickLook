import SwiftUI

//TODO: - add other swift ui equalants API for webQuicklook
extension View {
    public func webQuickLookPreview(_ item: Binding<URL?>) -> some View {
        self
            .fullScreenCover(item: item) { i in
                QuickLookPreview(urls: [i])                
            }
    }
}

extension URL: @retroactive Identifiable {
    public var id: URL { self }
}

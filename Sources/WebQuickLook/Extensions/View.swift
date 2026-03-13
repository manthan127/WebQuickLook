import SwiftUI
import QuickLook

//TODO: - add other swift ui equalants API for webQuicklook
extension View {
    public func webQuickLookPreview(_ item: Binding<URL?>) -> some View {
        self
            .modifier(WebQuicklookModifier(item: item))
    }
    
    public func webQuickLookPreview(_ selection: Binding<URL?>, in items: [URL]) -> some View {
        self
            .modifier(WebQuicklookModifierArr(selection: selection, items: items))
    }
}

struct WebQuicklookModifier: ViewModifier {
    @Binding var item: URL?
    @State var url: URL?
    
    init(item: Binding<URL?>) {
        self._item = item
        if item.wrappedValue != nil {
            self.url = URL.callingAPIURL()
        }
    }
    
    func body(content: Content) -> some View {
        content
            .quickLookPreview($url)
            .onChange(of: url) { newValue in
                if newValue == nil {
                    item = nil
                }
            }
            .onChange(of: item, perform: userChangedURL(_ :))
    }
    
    func userChangedURL(_ newValue: URL?) {
        guard let item = newValue else {return}
        Task {
            self.url = URL.callingAPIURL()
            await DownloadHandler.shared.downloadFiles(from: [item]) { _, downloadResult in
                switch downloadResult {
                case .success(let url):
                    self.url = url
                    print("----", url)
                case .failure(let error):
                    self.url = error.previewItem
                }
            }
        }
    }
}

struct WebQuicklookModifierArr: ViewModifier {
    @Binding var selection: URL?
    let items: [URL]
    
    @State private var url: URL?
    @State private var urls: [URL]
    
    init(selection: Binding<URL?>, items: [URL]) {
        self._selection = selection
        self.items = items
        
        // start calling api
        if selection.wrappedValue != nil {
            self.url = URL.callingAPIURL()
        }
        urls = Array(repeating: URL.callingAPIURL(), count: items.count)
    }
    
    func body(content: Content) -> some View {
        content
            .quickLookPreview($selection, in: items)
            .onChange(of: selection, perform: userChangedSelection(_:))
    }
    
    // stop work of previous api call before calling new api for download
    // TODO: - need to load urls lazily
    private func userChangedSelection(_ newValue: URL?) {
        Task {
            self.url = URL.callingAPIURL()
            await DownloadHandler.shared.downloadFiles(from: items) { indices, result in
                await MainActor.run {
                    switch result {
                    case .success(let url):
//                        let selectedInd = items.
                        for ind in indices {
                            self.urls[ind] = url
                        }
                    case .failure(let error):
                        for ind in indices {
                            self.urls[ind] = error.failURL()
                        }
                    }
                }
            }
//            await DownloadHandler.shared.downloadFiles(from: [selection]) { indices, downloadResult in
//                guard indices.contains(selectedInd) else { return }
//                switch downloadResult {
//                case .success(let url):
//                    self.url = url
//                    self.urls[selectedInd] = url
//                case .failure(let error):
//                    self.url = error.previewItem
//                    self.urls[selectedInd] = error.previewItem
//                }
//            }
        }
    }
}

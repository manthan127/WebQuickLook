import SwiftUI
import QuickLook

//TODO: - add other swift ui equalants API for webQuicklook
extension View {
    public func webQuickLookPreview(_ item: Binding<URL?>) -> some View {
        self
            .modifier(WebQuicklookModifier(item: item))
    }
    
    public func webQuickLookPreview<Items>(_ selection: Binding<Items.Element?>, in items: Items) -> some View where Items : RandomAccessCollection, Items.Element == URL {
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
            .onChange(of: item) { newValue in //
                print("Volume changed from \(item) to \(newValue)")
                guard let item = item else {return}
                Task {
                    self.url = URL.callingAPIURL()
                    await DownloadHandler.shared.downloadFiles(from: [item]) { indices, downloadResult in
                        switch downloadResult {
                        case .success(let url):
                            self.url = url
                        case .failure(let error):
                            self.url = error.previewItem
                        }
                    }
                }
                // You can perform side effects here, like saving data or updating a model.
            }
    }
}

struct WebQuicklookModifierArr<Items: RandomAccessCollection>: ViewModifier where Items.Element == URL {
    @Binding var selection: Items.Element?
    let items: Items
    
    @State var url: URL?
    let urls: [URL]
    
    init(selection: Binding<Items.Element?>, items: Items) {
        self._selection = selection
        self.items = items
        
        url = nil
        urls = Array(repeating: URL.callingAPIURL(), count: items.count)
    }
    
    func body(content: Content) -> some View {
        content
            .quickLookPreview($selection, in: items)
            .onChange(of: selection) { oldValue in
                if let selection {
                    items.firstIndex(of: selection)
                }
            }
    }
}

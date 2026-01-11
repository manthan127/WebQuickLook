//
//  ContentView.swift
//  WebQuickLookExample
//
//  Created by Home on 01/01/26.
//

import SwiftUI
import WebQuickLook

struct ContentView: View {
    init() {
        WebQuickLook.maxFileSize = 10 * 1024
    }
    var body: some View {
        QuickLookPreview(
            urls: [
                "https://fastly.picsum.photos/id/866/800/600.jpg?hmac=ABydLIy9SfKp2C562ssO9GKtL4uss8xHHILcBin8K48",
                "https://loremflickr.com/cache/resized/defaultImage.small_800_600_nofilter.jpg",
                "https://www.gstatic.com/webp/gallery/1.sm.webp",
                "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf",
                "https://www.africau.edu/images/default/sample.pdf",
                "https://unec.edu.az/application/uploads/2014/12/pdf-sample.pdf",
            ].compactMap{URL(string: $0)}
        )
    }
}

#Preview {
    ContentView()
}

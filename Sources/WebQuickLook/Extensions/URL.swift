//
//  File.swift
//  
//
//  Created by Home on 04/02/26.
//

import Foundation

extension URL {
    static func callingAPIURL() -> URL {
        WebQuickLook.config.downloading ?? WebQuickLook.makeFile(name: "processing", text: "API is Being Called")
    }
}

extension URL: Identifiable {
    public var id: URL { self }
}

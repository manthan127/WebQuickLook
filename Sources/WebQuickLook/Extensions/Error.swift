//
//  File.swift
//  
//
//  Created by Home on 04/02/26.
//

import Foundation

extension Error {
    var previewItem: URL {
        switch self {
        case let error as WebQuickLookError :
            return error.makeFile()
        default:
            return failURL()
        }
    }
    
    func failURL() -> URL {
        WebQuickLook.config.downloadFailed ?? WebQuickLook.makeFile(name: "error", text: "Failed to load file.")
    }
}

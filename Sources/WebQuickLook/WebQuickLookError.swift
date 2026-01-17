//
//  File.swift
//  
//
//  Created by Home on 11/01/26.
//

import Foundation

enum WebQuickLookError: Error {
    case invalidFileType
    case bigFile
    
    func makeFile() -> URL {
        userURL ?? WebQuickLook.makeFile(name: fileName, text: content)
    }
}

private extension WebQuickLookError {
    var userURL: URL? {
        let config = WebQuickLook.config
        return switch self {
        case .invalidFileType: config.invalidFileType
        case .bigFile        : config.bigFile
        }
    }
    
    var fileName: String {
        switch self {
        case .invalidFileType: "invalidFileType"
        case .bigFile        : "fileSizeIsBig"
        }
    }
    
    var content: String {
        switch self {
        case .invalidFileType: "Invalid file type"
        case .bigFile        : "File size bigger than expected\n change limit by setting `WebQuickLook.config.maxFileSize`"
        }
    }
}

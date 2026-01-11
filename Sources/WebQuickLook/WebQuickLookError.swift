//
//  File.swift
//  
//
//  Created by Home on 11/01/26.
//

import Foundation

enum WebQuickLookError: Error {
    case invalidFileType
    
    func makeFile() -> URL {
        userURL ?? WebQuickLook.makeFile(name: fileName, text: content)
    }
}

private extension WebQuickLookError {
    var userURL: URL? {
        let config = WebQuickLook.config
        return switch self {
        case .invalidFileType: config.invalidFileType
        }
    }
    
    var fileName: String {
        switch self {
        case .invalidFileType: "invalidFileType"
        }
    }
    
    var content: String {
        switch self {
        case .invalidFileType: "Invalid file type"
        }
    }
}

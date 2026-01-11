//
//  File.swift
//  
//
//  Created by Home on 01/01/26.
//

import Foundation

// TODO: - make file I/O code better and less verbose

// TODO: -
// - add example app
//   -- show all type of possible screens to user (written below)
//   -- show preview of custom type
// - add documentation

// - possible screen to show to the user
//   -- invalid file type ✅
//   -- file size bigger than max allowed

// - user can tell if they are supporting custom type of url
// - right now we are using last path component of remote url to decide file name there are may problem with this
//   -- remote url might not have extension so will be unsure about the type
//   -- there might be two different urls with the same last path components resulting in first one being overwritten by other

// - make swiftUI like function for users to use

// - cancel api call when quick look is dismissed (with/without resumeData)

// - handle case where duplicate urls are given to the quicklook

// - add some way to reload files that are failed

// - also allow URLRequest instead of url

typealias DownloadResult = Result<URL, Error>

public enum WebQuickLook {
    public static var config: Config = .init()
    
    internal static func makeFile(name: String, text: String) -> URL {
        if !FileManager.default.fileExists(atPath: defaultMessageDirectoryURL.path) {
            try? FileManager.default.createDirectory(at: defaultMessageDirectoryURL, withIntermediateDirectories: true)
        }
        
        let errorURL = defaultMessageDirectoryURL.appendingPathComponent(name + ".txt")
        if !FileManager.default.fileExists(atPath: errorURL.path) {
            try? text.write(to: errorURL, atomically: true, encoding: .utf8)
        }
        return errorURL
    }
}

public struct Config {
    public var maxFileSize: Int64 = 5 * 1024 * 1024
    
    public var downloading: URL?
    public var downloadFailed: URL?
    
    public var invalidFileType: URL?
    public var bigFile: URL?
}

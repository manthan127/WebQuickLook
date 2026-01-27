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
//   -- show all of the possible screens/functionality to user (written below)
// - add documentation

// give user option to at what path user wants to save data 
// - possible screen to show to the user
//   -- invalid file type ✅
//   -- file size bigger than max allowed ✅

// - user can support custom type(probably handling is on user's side, just need to test)
// https://medium.com/@itsuki.enjoy/swiftui-quicklook-preview-edit-files-in-app-generate-thumbnails-for-files-on-the-fly-18bcc7e475db
// https://www.kodeco.com/10447506-quicklook-previews-for-ios-getting-started
// http://developer.apple.com/augmented-reality/quick-look/

// - right now we are using last path component of remote url to decide file name there are may problem with this ✅
//   -- remote url might not have extension so will be unsure about the type
// using URLResponse.suggestedFilename right now to name local files this name is not guaranteed to work

// - make swiftUI like function for users to use

// - cancel api call when quick look is dismissed (with/without resumeData)

// - add some way to reload files that are failed

// - allow URLRequest instead of url
// - view is flashed when there is multiple urls

// - default error screen is not very helpful

typealias DownloadResult = Result<URL, Error>

public enum WebQuickLook {
    public static var config: Config = .init()
    
    internal static func makeFile(name: String, text: String) -> URL {
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

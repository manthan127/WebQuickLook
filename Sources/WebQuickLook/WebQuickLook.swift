//
//  File.swift
//  
//
//  Created by Home on 01/01/26.
//

import Foundation

// TODO: -
// - add example app
//   -- show all type of possible screens to user (written below)
//   -- show preview of custom type
// - add documentation

// - possible screen to show to the user
//   -- downloading
//   -- download failed
//   -- invalid file type
//   -- file size bigger than max allowed

// - user can tell if they are supporting custom type of url
// - right now we are using last path component of remote url to decide file name there are may problem with this
//   -- remote url might not have extension so will be unsure about the type
//   -- there might be two different urls with the same last path components resulting in first one being overwritten by other

// - make swiftUI like function for users to use

enum WebQuickLook {
    static var maxFileSize: Int64 = 10 * 1024 * 1024
}

//
//  RunningAPITracker.swift
//  WebQuickLook
//
//  Created by Home on 03/01/26.
//

import Foundation

actor RunningAPITracker {
    var dic: [URL: Task<URL, Error>] = [:]
    
    subscript(_ key: URL) -> Task<URL, Error>? {
        dic[key]
    }
    
    func set(_ newValue: Task<URL, Error>, for key: URL) {
        dic[key] = newValue
    }
}

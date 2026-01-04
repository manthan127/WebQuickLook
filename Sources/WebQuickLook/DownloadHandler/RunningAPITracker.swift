//
//  RunningAPITracker.swift
//  WebQuickLook
//
//  Created by Home on 03/01/26.
//

import Foundation

actor RunningAPITracker {
    typealias T = Task<Void, Never>
    var dic: [URL: T] = [:]
    
    subscript(_ key: URL) -> T? {
        dic[key]
    }
    
    func set(_ newValue: T, for key: URL) {
        dic[key] = newValue
    }
}

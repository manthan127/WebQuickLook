//
//  RunningAPITracker.swift
//  WebQuickLook
//
//  Created by Home on 03/01/26.
//

import Foundation

actor ActorDictionary<Key: Hashable, Value>: ExpressibleByDictionaryLiteral {
    init(dictionary: Dictionary<Key, Value>) {
        self.dictionary = dictionary
    }
    
    init(dictionaryLiteral elements: (Key, Value)...) {
        for (url, element) in elements {
            dictionary[url] = element
        }
    }
    
    var dictionary: [Key: Value] = [:]
    
    subscript(_ key: Key) -> Value? {
        dictionary[key]
    }
    
    func set(_ newValue: Value, for key: Key) {
        dictionary[key] = newValue
    }
    
    func removeAll(keepingCapacity keepCapacity: Bool = false) {
        dictionary.removeAll(keepingCapacity: keepCapacity)
    }
    
    @discardableResult
    func removeValue(forKey key: Key) -> Value? {
        dictionary.removeValue(forKey: key)
    }
    
    func reduce<Result>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, (key: Key, value: Value)) throws -> ()) rethrows -> Result {
        try dictionary.reduce(into: initialResult, updateAccumulatingResult)
    }
    
    func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, (key: Key, value: Value)) throws -> Result) rethrows -> Result {
        try dictionary.reduce(initialResult, nextPartialResult)
    }
    
    func first(where predicate: ((key: Key, value: Value)) throws -> Bool) rethrows -> (key: Key, value: Value)? {
        try dictionary.first(where: predicate)
    }
}

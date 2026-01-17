//
//  DownloadHandler.swift
//  QLDemo
//
//  Created by Home on 15/06/25.
//

import Foundation
import QuickLook

fileprivate let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent("WebQLPreview")
fileprivate let plistURL: URL = directoryURL.appendingPathComponent("mapping.plist")
internal let defaultMessageDirectoryURL = directoryURL.appendingPathComponent("defaultFiles")
internal let demoDirectoryURL = directoryURL.appendingPathComponent("demoFiles")

internal final class DownloadHandler {
    private init() {
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: defaultMessageDirectoryURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: demoDirectoryURL, withIntermediateDirectories: true)
        mapping = .init(dictionary: Self.loadMappingFromDisk(plistURL: plistURL))
    }
    public static let shared = DownloadHandler()
    
    /// In-memory mapping: remoteURL → filename
    private var mapping: ActorDictionary<URL, String>
    
    private let fileManager = FileManager.default
}

internal extension DownloadHandler {
    func downloadFiles(from urls: [URL], completion: @escaping ([Int], DownloadResult) async -> ()) async {
        // grouping the same urls
        var dic: [URL: [Int]] = [:]
        for (ind, url) in (urls).enumerated() {
            dic[url, default: []].append(ind)
        }
        
        await withTaskGroup(of: Void.self) { group in
            for (url, ind) in dic {
                guard canPreview(ext: url.pathExtension) else {
                    await completion(ind, .failure(WebQuickLookError.invalidFileType))
                    continue
                }
                group.addTask {
                    do {
                        let name = await self.fileName(url: url)
                        let localURL = directoryURL.appendingPathComponent(name + "/" + url.lastPathComponent)
                        
                        try await self.Download(url, localURL: localURL)
                        await completion(ind, .success(localURL))
                    } catch {
                        await completion(ind, .failure(error))
                    }
                }
            }
        }
        try? saveMappingToDisk()
    }
    
    // TODO: - make this function accessible to the user
    func deleteAll() throws {
        let contents = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
        
        let preservedURLs = [defaultMessageDirectoryURL, demoDirectoryURL]
        
        // can speed this up if there is call that takes multiple url at time yo delete it's child
        for url in contents where !preservedURLs.contains(url) {
            // there is one (User Mode -> Kernel Mode) switch for each file deletion
            // if we can modify the directory's internal table might be possible with only one switch
            try? fileManager.removeItem(at: url)
        }
        
        Task {
            await mapping.removeAll()
        }
    }
}

private extension DownloadHandler {
    func fileName(url: URL) async -> String {
        if let map = await self.mapping[url] {
            return map
        } else {
            // using UUID as folder name for handling duplicate names of files
            let name = UUID().uuidString
            
            try? fileManager.createDirectory(at: directoryURL.appendingPathComponent(name), withIntermediateDirectories: true)
            await self.mapping.set(name, for: url)
            
            return name
        }
    }
    
    func canPreview(ext: String) -> Bool {
        let url = demoDirectoryURL.appendingPathComponent("demo."+ext)
        
        do {
            if !fileManager.fileExists(atPath: url.path) {
                try Data().write(to: url)
            }
            return QLPreviewController.canPreview(url as QLPreviewItem)
        } catch {
            return false
        }
    }
    
    
    func Download(_ remoteURL: URL, localURL: URL) async throws {
        if fileManager.fileExists(atPath: localURL.path) {
            return
        }
        
        let data = try await withCheckedThrowingContinuation { cont in
            let task = URLSession.shared.dataTask(with: remoteURL)
            task.delegate = DownloadDelegate(continuation: cont)
            task.resume()
        }
        
        try data.write(to: localURL)
    }
}

private extension DownloadHandler {
    static func loadMappingFromDisk(plistURL: URL) -> [URL: String] {
        guard
            let data = try? Data(contentsOf: plistURL),
            let raw = try? PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: String]
        else {
            return [:]
        }
        
        return Dictionary(
            uniqueKeysWithValues: raw.compactMap { key, value in
                guard let url = URL(string: key) else { return nil }
                return (url, value)
            }
        )
    }
    
    /// Saves in-memory mapping to mapping.plist
    func saveMappingToDisk() throws {
        Task {
            let raw: [String: String] = await mapping.reduce(into: [:]) {
                $0[$1.key.absoluteString] = $1.value
            }
            
            let data = try PropertyListSerialization.data(
                fromPropertyList: raw,
                format: .xml,
                options: 0
            )
            
            try data.write(to: plistURL, options: .atomic)
        }
    }
}

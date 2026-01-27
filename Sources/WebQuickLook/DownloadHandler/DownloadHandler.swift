//
//  DownloadHandler.swift
//  QLDemo
//
//  Created by Home on 15/06/25.
//

import Foundation
import QuickLook

internal let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent("WebQLPreview")
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
//                if !url.pathExtension.isEmpty {
                    guard canPreview(ext: url.pathExtension) else {
                        await completion(ind, .failure(WebQuickLookError.invalidFileType))
                        continue
                    }
//                }
                
                if let fileName = await self.mapping[url] {
                    let fileURL = directoryURL.appendingPathComponent(fileName)
                    if self.fileManager.fileExists(atPath: fileURL.path) {
                        await completion(ind, .success(fileURL))
                        continue
                    }
                }
                
                group.addTask {
                    do {
                        let localURL = try await self.Download(url)
                        await completion(ind, .success(localURL))
                    } catch {
                        print(error)
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
    
    
    func Download(_ remoteURL: URL) async throws -> URL {
        let (data, name) = try await withCheckedThrowingContinuation { cont in
            let task = URLSession.shared.dataTask(with: remoteURL)
            task.delegate = DownloadDelegate(continuation: cont)
            task.resume()
        }
        
        let directoryName = UUID().uuidString
        let fileName = name ?? remoteURL.lastPathComponent
        
        let directoryPath = directoryURL.appendingPathComponent(directoryName)
        let filePath = directoryPath.appendingPathComponent(fileName)
        
        try self.fileManager.createDirectory(at: directoryPath, withIntermediateDirectories: true)
        try data.write(to: filePath)
        
        await self.mapping.set(directoryName + "/" + fileName, for: remoteURL)
        
        return filePath
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

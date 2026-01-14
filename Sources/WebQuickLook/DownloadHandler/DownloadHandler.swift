//
//  DownloadHandler.swift
//  QLDemo
//
//  Created by Home on 15/06/25.
//

import Foundation
import QuickLook

// MARK: This is not working
final class Delegate: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse
    ) async -> URLSession.ResponseDisposition {
        response.expectedContentLength > WebQuickLook.config.maxFileSize ? .cancel : .allow
    }
}

fileprivate let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent("WebQLPreview")
fileprivate let plistURL: URL = directoryURL.appendingPathComponent("mapping.plist")
internal let defaultMessageDirectoryURL = directoryURL.appendingPathComponent("defaultFiles")
internal let demoDirectoryURL = directoryURL.appendingPathComponent("demoFiles")

internal final class DownloadHandler {
    private init() {
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: defaultMessageDirectoryURL, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: demoDirectoryURL, withIntermediateDirectories: true)
        mapping = .init(dictionary: Self.loadMappingFromDisk(plistURL: plistURL))
    }
    public static let shared = DownloadHandler()
    
    /// In-memory mapping: remoteURL → filename
    private var mapping: ActorDictionary<URL, String>
    private var runningAPITracker = ActorDictionary<URL, Task<Void, Never>>()

    private let session = URLSession(configuration: .default, delegate: Delegate(), delegateQueue: .main)
}

internal extension DownloadHandler {
    func downloadFiles(from urls: [URL], completion: @escaping (Int, DownloadResult) async -> ()) async {
        await withTaskGroup(of: Void.self) { group in
            for (ind, url) in urls.enumerated() {
                guard canPreview(ext: url.pathExtension) else {
                    await completion(ind, .failure(WebQuickLookError.invalidFileType))
                    continue
                }
                //            if let _ = await runningAPITracker[url] {
                //                continue
                //            }
                //            let task =
                group.addTask {
                    do {
                        // TODO: - need to optimize if there is same url in array (right now there will be two different api call for same resource)
                        
                        let name = await self.fileNAme(url: url)
                        let localURL = directoryURL.appendingPathComponent(name + "/" + url.lastPathComponent)
                        
                        let url = try await self.Download(url, localURL: localURL)
                        await completion(ind, .success(url))
                    } catch {
                        await completion(ind, .failure(error))
                    }
                }
                //            await runningAPITracker.set(task, for: url)
            }
        }
        try? saveMappingToDisk()
    }
    
    func deleteAll() throws {
        try FileManager.default.removeItem(at: directoryURL)
        Task {
            await mapping.removeAll()
            try? saveMappingToDisk()
        }
    }
    
    func delete(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
        removeValueFromMapping(url.lastPathComponent)
    }
    
    func delete(named name: String) throws {
        try FileManager.default.removeItem(at: directoryURL.appendingPathComponent(name))
        removeValueFromMapping(name)
    }
    
    private func removeValueFromMapping(_ value: String) {
        Task {
            if let key = await mapping.first(where: {$0.value == value})?.key {
                await mapping.removeValue(forKey: key)
                try? saveMappingToDisk()
            }
        }
    }
}

private extension DownloadHandler {
    func fileNAme(url: URL) async -> String {
        if let map = await self.mapping[url] {
            return map
        } else {
            // using UUID as folder name for handling duplicate names of files
            let name = UUID().uuidString
            
            try? FileManager.default.createDirectory(at: directoryURL.appendingPathComponent(name), withIntermediateDirectories: true)
            await self.mapping.set(name, for: url)
            
            return name
        }
    }
    
    func canPreview(ext: String) -> Bool {
        let url = demoDirectoryURL.appendingPathComponent("demo."+ext)
        
        do {
            if !FileManager.default.fileExists(atPath: url.path) {
                try Data().write(to: url)
            }
            return QLPreviewController.canPreview(url as QLPreviewItem)
        } catch {
            return false
        }
    }
    
    
    func Download(_ remoteURL: URL, localURL: URL) async throws -> URL {
        if FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        }
        
        let (data, _) = try await session.data(from: remoteURL)
        try data.write(to: localURL)
        return localURL
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

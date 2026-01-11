//
//  DownloadHandler.swift
//  QLDemo
//
//  Created by Home on 15/06/25.
//

import Foundation

final class Delegate: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse
    ) async -> URLSession.ResponseDisposition {
        response.expectedContentLength > WebQuickLook.maxFileSize ? .cancel : .allow
    }
}

fileprivate let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent("WebQLPreview")
fileprivate var plistURL: URL = directoryURL.appendingPathComponent("mapping.plist")

internal final class DownloadHandler {
    private init() {
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: false)
        mapping = .init(dictionary: Self.loadMappingFromDisk(plistURL: plistURL))
    }
    public static let shared = DownloadHandler()
    private var runningAPITracker = ActorDictionary<URL, Task<Void, Never>>()
    
    /// In-memory mapping: remoteURL → filename
    private var mapping: ActorDictionary<URL, String>

    private let session = URLSession(configuration: .default, delegate: Delegate(), delegateQueue: .main)
}

internal extension DownloadHandler {
    func downloadFiles(from urls: [URL], completion: @escaping (Int, DownloadResult) async -> ()) async {
        await withTaskGroup(of: Void.self) { group in
            for (ind, url) in urls.enumerated() {
                //            if let _ = await runningAPITracker[url] {
                //                continue
                //            }
                //            let task =
                group.addTask {
                    do {
                        let id = UUID().uuidString + url.pathExtension
                        // TODO: - prone to race condition and will be issue if there is similar url in same array
                        let name = await self.mapping[url] ?? id
                        await self.mapping.set(name, for: url)
                
                        let url = try await self.Download(url, fileName: url.lastPathComponent)
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
    private func Download(_ remoteURL: URL, fileName: String) async throws -> URL {
        let localURL = directoryURL.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        }
        
        let (data, _) = try await session.data(from: remoteURL)
        try data.write(to: localURL)
        return localURL
    }
    
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

//
//  DownloadHandler.swift
//  QLDemo
//
//  Created by Home on 15/06/25.
//

import Foundation
import QuickLook
import RemoteResourceKit

internal let webQLPreviewBaseURL = FileManager.default.temporaryDirectory.appendingPathComponent("WebQLPreview")
fileprivate let plistURL: URL = webQLPreviewBaseURL.appendingPathComponent("mapping.plist")
internal let defaultMessageDirectoryURL = webQLPreviewBaseURL.appendingPathComponent("defaultFiles")
internal let demoDirectoryURL = webQLPreviewBaseURL.appendingPathComponent("demoFiles")

internal final class DownloadHandler {
    private init() {
        try? fileManager.createDirectory(at: webQLPreviewBaseURL, withIntermediateDirectories: true)
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
        for (ind, url) in urls.enumerated() {
            dic[url, default: []].append(ind)
        }
        
        await withTaskGroup(of: Void.self) { group in
            for (url, indices) in dic {
                //if !url.pathExtension.isEmpty {
                guard canPreview(ext: url.pathExtension) else {
                    await completion(indices, .failure(WebQuickLookError.invalidFileType))
                    continue
                }
                //}
                
                // TODO: - not checking properly for already downloaded files
                if let fileName = await self.mapping[url] {
                    let fileURL = webQLPreviewBaseURL.appendingPathComponent(fileName)
                    if self.fileManager.fileExists(atPath: fileURL.path) {
                        await completion(indices, .success(fileURL))
                        continue
                    }
                }
                
                let resourceGroup = makeResourceGroup(url: url, indices: indices, completion: completion)
                group.addTask {
                    let downloadSession = DownloadSession()
                    downloadSession.delegate = self
                    await downloadSession.download(resourceGroup)
                }
            }
        }
        try? saveMappingToDisk()
    }
    
    // TODO: - make this function accessible to the user
    func deleteAll() throws {
        let contents = try fileManager.contentsOfDirectory(at: webQLPreviewBaseURL, includingPropertiesForKeys: nil)
        
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

extension DownloadHandler: DownloadSessionDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse) async throws -> URLSession.ResponseDisposition {
        let isCanceled = response.expectedContentLength > WebQuickLook.config.maxFileSize
        if isCanceled {
            throw WebQuickLookError.bigFile
        }
        return .becomeDownload
    }
}

private extension DownloadHandler {
    func makeResourceGroup(url: URL, indices: [Int], completion: @escaping ([Int], DownloadResult) async -> ()) -> ResourceGroup {
        ResourceGroup(baseURL: webQLPreviewBaseURL) {
            let id = UUID().uuidString
            Folder(name: id) {
                File(name: nil, url: url)
                    .onDownloadComplete { localURL in
                        let name = id + "/" + localURL.lastPathComponent
                        await self.mapping.set(name, for: url)
                        await completion(indices, .success(localURL))
                    }
                    .onError { error in
                        await completion(indices, .failure(error))
                    }
            }
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

//
//  DownloadHandler.swift
//  QLDemo
//
//  Created by Home on 15/06/25.
//

import Foundation

actor RunningAPITracker {
    var dic: [URL: Task<URL?, Never>] = [:]
    
    subscript(_ key: URL) -> Task<URL?, Never>? {
        dic[key]
    }
    
    func set(_ newValue: Task<URL?, Never>, for key: URL) {
        dic[key] = newValue
    }
}

public class DownloadHandler {
    private init() {
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: false)
    }
    public static let shared = DownloadHandler()
    
    private var runningAPITracker = RunningAPITracker()
    private let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent("WebQLPreview")
    
    private lazy var session = URLSession(configuration: .default, delegate: Delegate(), delegateQueue: .main)
    
    func Download(_ remoteURL: URL) async -> URL? {
        let fileName = remoteURL.lastPathComponent
        let localURL = directoryURL.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        }
        
        do {
            let (data, _) = try await session.data(from: remoteURL)
            try data.write(to: localURL)
            return localURL
        } catch {
            return nil
        }
    }
}


final class Delegate: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse
    ) async -> URLSession.ResponseDisposition {
        response.expectedContentLength > WebQuickLook.maxFileSize ? .cancel : .allow
    }
}

public extension DownloadHandler {
    func downloadFiles(from urls: [URL]) async -> [URL?] {
        // used array of task instead of TaskGroup to keep responses in correct order
        var tasks: [Task<URL?, Never>] = []
        for url in urls {
            if let runningTask = await runningAPITracker[url] {
                tasks.append(runningTask)
                continue
            }
            let task = Task { await Download(url) }
            tasks.append(task)
            await runningAPITracker.set(task, for: url)
        }
        
        var urls: [URL?] = []
        for task in tasks {
            urls.append(await task.value)
        }
        return urls
    }
    
    func deleteAll() throws {
        try FileManager.default.removeItem(at: directoryURL)
    }
    
    func delete(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
    
    func delete(named name: String) throws {
        try FileManager.default.removeItem(at: directoryURL.appendingPathComponent(name))
    }
}

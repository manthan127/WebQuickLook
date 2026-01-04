//
//  DownloadHandler.swift
//  QLDemo
//
//  Created by Home on 15/06/25.
//

import Foundation

internal class DownloadHandler {
    private init() {
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: false)
    }
    public static let shared = DownloadHandler()
    
    private var runningAPITracker = RunningAPITracker()
    private let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent("WebQLPreview")
    
    private let session = URLSession(configuration: .default, delegate: Delegate(), delegateQueue: .main)
    
    func Download(_ remoteURL: URL) async throws -> URL {
        let fileName = remoteURL.lastPathComponent
        let localURL = directoryURL.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        }
        
        let (data, _) = try await session.data(from: remoteURL)
        try data.write(to: localURL)
        return localURL
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

internal extension DownloadHandler {
    func downloadFiles(from urls: [URL], completion: @escaping (Int, DownloadResult) async -> ()) async {
        for (ind, url) in urls.enumerated() {
//            if let _ = await runningAPITracker[url] {
//                continue
//            }
//            let task = 
            Task {
                do {
                    let url = try await Download(url)
                    await completion(ind, .success(url))
                } catch {
                    await completion(ind, .failure(error))
                }
            }
//            await runningAPITracker.set(task, for: url)
        }
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

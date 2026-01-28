//
//  File.swift
//  
//
//  Created by Home on 17/01/26.
//

import Foundation

final class DownloadDelegate: NSObject, URLSessionDataDelegate {
    typealias C = CheckedContinuation<(URL, String), any Error>
    let continuation: C
    let defaultName: String
    
    init(continuation: C, defaultName: String) {
        self.continuation = continuation
        self.defaultName = defaultName
        super.init()
    }
    
    private var isCanceled = false
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        if let error {
            continuation.resume(throwing: isCanceled ? WebQuickLookError.bigFile : error)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {}
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse
    ) async -> URLSession.ResponseDisposition {
        isCanceled = response.expectedContentLength > WebQuickLook.config.maxFileSize
        return isCanceled ? .cancel : .becomeDownload
    }
}

extension DownloadDelegate: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let directoryName = UUID().uuidString
        let fileName = downloadTask.response?.suggestedFilename ?? defaultName
        
        let directoryPath = webQLPreviewBaseURL.appendingPathComponent(directoryName)
        let filePath = directoryPath.appendingPathComponent(fileName)
        do {
            let fileManager = FileManager.default
            try fileManager.createDirectory(at: directoryPath, withIntermediateDirectories: true)
            try fileManager.moveItem(at: location, to: filePath)
            
            continuation.resume(returning: (filePath, directoryName + "/" + fileName))
        } catch {
            continuation.resume(throwing: error)
        }
    }
}

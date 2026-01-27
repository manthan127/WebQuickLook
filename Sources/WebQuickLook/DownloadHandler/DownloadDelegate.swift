//
//  File.swift
//  
//
//  Created by Home on 17/01/26.
//

import Foundation

final class DownloadDelegate: NSObject, URLSessionDataDelegate {
    typealias C = CheckedContinuation<(Data, String?), any Error>
    let continuation: C
    
    private var accumulatedData = Data()
    private var isCancled = false
    
    init(continuation: C) {
        self.continuation = continuation
        super.init()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        if let error {
            continuation.resume(throwing: isCancled ? WebQuickLookError.bigFile : error)
        } else {
            let name = task.response?.suggestedFilename
            continuation.resume(returning: (accumulatedData, name))
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        accumulatedData.append(data)
    }
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse
    ) async -> URLSession.ResponseDisposition {
        isCancled = response.expectedContentLength > WebQuickLook.config.maxFileSize
        return isCancled ? .cancel : .allow
    }
}

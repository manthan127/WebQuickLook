//
//  File.swift
//  
//
//  Created by Home on 17/01/26.
//

import Foundation

final class DownloadDelegate: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    typealias C = CheckedContinuation<Data, any Error>
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
            continuation.resume(returning: accumulatedData)
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

//extension DownloadDelegate: URLSessionDownloadDelegate {
//    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
//        print(location)
//        cont.resume(returning: location)
//    }
//}

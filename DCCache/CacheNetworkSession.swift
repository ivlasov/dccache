//
//  DCCache
//

import Foundation
import DCUtils

extension Cache {
    class NetworkSession: NSObject, URLSessionDownloadDelegate {
        
        class Task: NSObject {
            
            let identifier = NSUUID().uuidString
            
            var onUpdate: ((_ bytesReady: Double, _ bytesTotal: Double) -> Void)?
            var onComplete: ((_ value: Data?, _ error: NSError?) -> Void)?
            
            let task: URLSessionTask
            
            init(session: URLSession, url: URL) {
                task = session.downloadTask(with: url)
                super.init()
                task.resume()
            }
            
            func process(bytesReady: Double, bytesTotal: Double) {
                onUpdate?(bytesReady, bytesTotal)
            }
            
            func finish(url: URL?, error: NSError?) {
                if let url = url {
                    onComplete?(try? Data(contentsOf: url), error)
                } else {
                    onComplete?(nil, error)
                }
            }
            
            open func cancel() {
                task.cancel()
            }
            
        }
        
        fileprivate var session: URLSession!
        fileprivate let queue = OperationQueue()
        fileprivate var tasks = [Task]()
        
        override init() {
            super.init()
            queue.maxConcurrentOperationCount = 5
            session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: queue)
        }
        
        func performTask(url: String) -> Task? {
            guard let url = URL(string: url) else {return nil}
            tasks << Task(session: session, url: url)
            return tasks.last
        }
        
        // MARK - NSURLSessionDownloadDelegate
        
        private func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            guard let error = error as NSError? else {return}
            tasks.first(where: {$0.task == task})?.finish(url: nil, error: error as NSError?)
            tasks.removeAll(where: {$0.task == task} )
            print("CACHE ERROR " + (task.originalRequest?.url?.absoluteString ?? "") + error.localizedDescription)
        }
        
        public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
            tasks.first(where: {$0.task == downloadTask})?.finish(url: location, error: nil)
            tasks.removeAll(where: {$0.task == downloadTask} )
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            tasks.first(where: {$0.task == downloadTask})?.process(bytesReady: Double(totalBytesWritten), bytesTotal: Double(totalBytesExpectedToWrite))
        }
        
    }
}

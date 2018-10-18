//
//  DCCache
//

import Foundation

extension Cache {
    class Task {
        
        let identifier  : String
        var tasks       = [CacheTask]()
        var sessionTask : NetworkSession.Task?
        let cache       : String
        
        init(identifier: String, cache: String) {
            self.identifier = identifier
            self.cache = cache
        }
        
        fileprivate func notifyUpdate(bytesReady: Double, bytesTotal: Double) {
            OperationQueue.main.addOperation {
                for task in self.tasks {
                    task.onUpdate?(bytesReady, bytesTotal)
                }
            }
        }
        
        fileprivate func notifyComplete(object: Any?, error: NSError?, save: Bool = true) {
            if save {
                Cache.named(cache)[identifier] = object
            }
            let object = Cache.named(cache)[identifier]
            OperationQueue.main.addOperation {
                for task in self.tasks {
                    task.onComplete?(object, error)
                }
            }
        }
        
        func cancel(task: CacheTask) {
            tasks.remove(predicate: {$0.id == task.id})
            if tasks.count == 0 {
                sessionTask?.cancel()
            }
        }
        
        func perform(queue: OperationQueue, session: NetworkSession, handler: @escaping (() -> Void)) {
            let cache = Cache.named(self.cache)
            if let object = cache.items[identifier.MD5] {
                OperationQueue.main.addOperation {
                    self.notifyComplete(object: object, error: nil, save: false)
                    handler()
                }
            } else if cache.contains(key: identifier) {
                queue.addOperation {
                    let object = cache[self.identifier]
                    OperationQueue.main.addOperation {
                        self.notifyComplete(object: object, error: nil, save: false)
                        handler()
                    }
                }
            } else {
                sessionTask = session.performTask(url: identifier)
                sessionTask?.onUpdate = { [weak self] (bytesReady,bytesTotal) in
                    self?.notifyUpdate(bytesReady: bytesReady, bytesTotal: bytesTotal)
                }
                sessionTask?.onComplete = { [weak self](object,error) in
                    self?.notifyComplete(object: object, error: error)
                    OperationQueue.main.addOperation {
                        handler()
                    }
                }
            }
        }
    }
}

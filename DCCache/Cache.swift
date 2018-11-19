//
//  DCCache
//

import Foundation
import DCUtils

public protocol CacheConverter {
    func object(from data: Data?) -> Any?
    func data(from object: Any?) -> Data?
}

public protocol CacheStorageProvider {
    var identifier: String {get set}
    subscript(key: String?) -> Data? {get set}
    func path(key: String?) -> String?
    func contains(key: String?) -> Bool
    func clear()
}

fileprivate var caches = [Cache]()

open class Cache {
    
    @discardableResult public
    static func initialize(_ name: String, options: Options? = nil) -> Cache {
        for cache in caches {
            if cache.name == name {
                return cache
            }
        }
        var aOptions = options
        if aOptions == nil {
            aOptions = Options()
        }
        let cache = Cache(name: name, options: aOptions!)
        caches << cache
        return cache
    }
    
    @discardableResult
    public static func named(_ name: String) -> Cache {
        for cache in caches {
            if cache.name == name {
                return cache
            }
        }
        return Cache.initialize(name)
    }
    
    public fileprivate(set) var name   = String()
    public fileprivate(set) var options: Options!
    
    var items = [String:Any]()
    
    init(name: String, options: Options) {
        self.name = name
        self.options = options
        self.options.storage?.identifier = name
    }
    
    open subscript(key: String?) -> Any? {
        get {
            guard let key = key else {return nil}
            if let item = items[key.MD5] {return item}
            if let item = options.storage?[key.MD5] {
                if let converter = options.converter {
                    let item = converter.object(from: item)
                    if options.useMemory {
                        items[key.MD5] = item
                    }
                    return item
                }
                if options.useMemory {
                    items[key.MD5] = item
                }
                return item
            }
            return nil
        }
        set {
            guard let key = key else {return}
            if let data = newValue as? Data {
                options.storage?[key.MD5] = data
                if options.useMemory {
                    if let converter = options.converter {
                        items[key.MD5] = converter.object(from: data)
                    } else {
                        items[key.MD5] = data
                    }
                }
            } else if let converter = options.converter {
                options.storage?[key.MD5] = converter.data(from: newValue)
                if options.useMemory {
                    items[key.MD5] = newValue
                }
            }
        }
    }
    
    open func contains(key: String?, checkDownloads: Bool = false) -> Bool {
        guard let key = key else {return false}
        if let _ = items[key.MD5] {return true}
        if let exists = options.storage?.contains(key: key.MD5) {
            if exists {return true}
        }
        if checkDownloads {
            if tasks.contains(where: {$0.identifier == key}) {return true}
        }
        return false
    }
    
    open func clear() {
        items = [String:Any]()
    }
    
    // MARK: - Preload
    
    fileprivate var tasks = [Task]()
    fileprivate let session = NetworkSession()
    fileprivate let queue = OperationQueue()
    
    @discardableResult open func perform(key: String?) -> CacheTask? {
        guard let key = key else {return nil}
        let cacheTask = CacheTask(identifier: key, cache: name)
        process(task: cacheTask)
        return cacheTask
    }
    
    fileprivate func process(task: CacheTask) {
        for item in tasks {
            if item.identifier == task.identifier {
                item.tasks << task
                return
            }
        }
        let item = Task(identifier: task.identifier, cache: name)
        item.tasks << task
        tasks << item
        item.perform(queue: queue, session: session) { [weak self] in
            self?.tasks.removeAll(where: {$0.identifier == item.identifier} )
        }
    }
    
    func cancel(task: CacheTask) {
        tasks.filter({$0.identifier == task.identifier}).first?.cancel(task: task)
    }
    
}

open class CacheTask {
    let id = NSUUID().uuidString
    public let identifier: String
    public var onUpdate: ((_ bytesReady: Double, _ bytesTotal: Double) -> Void)?
    public var onComplete: ((_ object: Any?, _ error: NSError?) -> Void)?
    var cache: String
    init(identifier: String, cache: String) {
        self.identifier = identifier
        self.cache = cache
    }
    public func cancel() {
        Cache.named(cache).cancel(task: self)
    }
}

public func == (lhs: Cache?, rhs: Cache?) -> Bool {
    return lhs?.name == rhs?.name
}

//
//  DCCache
//

import Foundation
import DCUtils

extension Cache {
    open class DiskProvider: CacheStorageProvider {

        open var identifier     = ""
        open var fileExtension  : String?
        
        public init() {}
        
        public init(fileExtension: String) {
            self.fileExtension = fileExtension
        }
        
        fileprivate var cacheFolder: String? {
            let path = Storage.Directory.path(known: .cache(path: "mp.cache/\(identifier)"))
            var isDir: ObjCBool = false
            if !FileManager.default.fileExists(atPath: path, isDirectory: &isDir) || !isDir.boolValue {
                do {
                    _ = try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print(error)
                    return nil
                }
            }
            return path
        }
        
        open func path(key: String?) -> String? {
            guard let key = key else {return nil}
            guard let path = cacheFolder else {return nil}
            if let ext = fileExtension {
                return path + "/" + key + "." + ext
            }
            return path + "/" + key
        }
        
        open func contains(key: String?) -> Bool {
            if let path = path(key: key) {
                return FileManager.default.fileExists(atPath: path)
            }
            return false
        }
        
        open subscript(key: String?) -> Data? {
            get {
                if let path = path(key: key) {
                    return (try? Data(contentsOf: URL(fileURLWithPath: path)))
                }
                return nil
            }
            set {
                guard let path = path(key: key) else {
                    return
                }
                if let data = newValue {
                    try? data.write(to: URL(fileURLWithPath: path), options: [.atomic])
                } else {
                    if FileManager.default.fileExists(atPath: path) {
                        do {
                            _ = try FileManager.default.removeItem(atPath: path)
                        } catch {
                            print(error)
                        }
                    }
                }
            }
        }
        
        public func clear() {
            guard let path = cacheFolder else {return}
            try? FileManager.default.removeItem(atPath: path)
        }
        
    }
}

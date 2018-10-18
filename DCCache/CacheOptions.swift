//
//  DCCache
//

import Foundation

extension Cache {
    open class Options {
        
        open var storage    : CacheStorageProvider?
        open var converter  : CacheConverter?
        open var useMemory  : Bool
        
        public init(storage: CacheStorageProvider? = DiskProvider(), converter: CacheConverter? = nil, useMemory: Bool = true) {
            self.converter = converter
            self.storage = storage
            self.useMemory = useMemory
        }
        
    }
}

import Foundation

/// A Swift-friendly wrapper of NSCache
final class Cache<Key: Hashable, Value> {
    private let underlyingCache = NSCache<WrappedKey, WrappedValue>()

    func insert(_ value: Value, forKey key: Key) {
        let entry = WrappedValue(value: value)
        underlyingCache.setObject(entry, forKey: WrappedKey(key))
    }

    func value(forKey key: Key) -> Value? {
        underlyingCache.object(forKey: WrappedKey(key))?.value
    }

    func removeValue(forKey key: Key) {
        underlyingCache.removeObject(forKey: WrappedKey(key))
    }
}

private extension Cache {
    private final class WrappedKey: NSObject {
        private let key: Key

        init(_ key: Key) {
            self.key = key
        }

        override var hash: Int {
            key.hashValue
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let otherWrappedKey = object as? WrappedKey else { return false }
            return key == otherWrappedKey.key
        }
    }

    private final class WrappedValue {
        let value: Value

        init(value: Value) {
            self.value = value
        }
    }
}

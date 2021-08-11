import Foundation

enum GameTagKey: String {
    case casinoGameTag, numberGameTag, arcadeGameTag
}

class MemoryCacheImpl {
    static let shared = MemoryCacheImpl()
    private init() {}
    private var dicts: [String: Any?] = [:]
    
    func setGameTag<T>(_ key: GameTagKey,_ tags: T) {
        self.setByKey(key.rawValue, tags)
    }
    
    func getGameTag<T>(_ key: GameTagKey) -> T? {
        return self.dicts[key.rawValue] as? T
    }
    
    private func setByKey<T>(_ key: String, _ value: T) {
        self.dicts[key] = value
    }
    
    private func getByKey<T>(_ key: String) -> T? {
        return self.dicts[key] as? T
    }
    
}

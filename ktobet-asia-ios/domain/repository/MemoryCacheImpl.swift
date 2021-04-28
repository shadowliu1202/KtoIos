import Foundation

class MemoryCacheImpl {
    static let shared = MemoryCacheImpl()
    private init() {}
    private var dicts: [String: Any?] = [:]
    let kCasinoGameTag = "casinoGameTag"
    
    func setCasinoGameTag(_ tags: [CasinoTag]) {
        self.dicts[kCasinoGameTag] = tags
    }
    
    func getCasinoGameTag() -> [CasinoTag]? {
        return self.dicts[kCasinoGameTag] as? [CasinoTag]
    }
    
}

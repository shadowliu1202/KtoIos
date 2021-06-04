import Foundation

class MemoryCacheImpl {
    static let shared = MemoryCacheImpl()
    private init() {}
    private var dicts: [String: Any?] = [:]
    let kCasinoGameTag = "casinoGameTag"
    let kNumberGameTag = "numberGameTag"
    
    func setCasinoGameTag(_ tags: [CasinoTag]) {
        self.dicts[kCasinoGameTag] = tags
    }
    
    func getCasinoGameTag() -> [CasinoTag]? {
        return self.dicts[kCasinoGameTag] as? [CasinoTag]
    }
    
    func setNumberGameTag(_ tags: [NumberGameTag]) {
        self.dicts[kNumberGameTag] = tags
    }
    
    func getNumberGameTag() -> [NumberGameTag]? {
        return self.dicts[kNumberGameTag] as? [NumberGameTag]
    }
    
}

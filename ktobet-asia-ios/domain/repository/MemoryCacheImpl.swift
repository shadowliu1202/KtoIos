import Foundation

enum GameTagKey: String {
  case casinoGameTag
  case numberGameTag
  case arcadeGameTag
}

let KeyPlayer = "Player"

class MemoryCacheImpl {
  private var dicts: [String: Any?] = [:]

  func setGameTag<T>(_ key: GameTagKey, _ tags: T) {
    self.setByKey(key.rawValue, tags)
  }

  func getGameTag<T>(_ key: GameTagKey) -> T? {
    self.dicts[key.rawValue] as? T
  }

  func set<T>(_ key: String, _ value: T) {
    self.dicts[key] = value
  }

  func get<T>(_ key: String) -> T? {
    self.dicts[key] as? T
  }

  private func setByKey<T>(_ key: String, _ value: T) {
    self.dicts[key] = value
  }

  private func getByKey<T>(_ key: String) -> T? {
    self.dicts[key] as? T
  }
}

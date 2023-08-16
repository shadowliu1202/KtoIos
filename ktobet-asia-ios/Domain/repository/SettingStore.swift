import Foundation

struct SettingStore {
  func clearCache() {
    Persistent<String>.clear()
  }

  @Persistent(key: .defaultProduct) var defaultProduct: Int32?
  @PersistentObject(key: .playerInfo) var playerInfo: PlayerBean?
}

extension Key {
  static let defaultProduct: Key = "defaultProduct"
  static let playerInfo: Key = "playerInfo"
}

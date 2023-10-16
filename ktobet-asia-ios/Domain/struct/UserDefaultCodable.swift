import Foundation
import sharedbu

struct PlayerInfoCacheBean: Codable {
  let displayID: String
  let gamerID: String
  let locale: String
  let level: Int32
  let defaultProduct: Int32
  
  func copy(
    displayID: String? = nil,
    gamerID: String? = nil,
    locale: String? = nil,
    level: Int32? = nil,
    defaultProduct: Int32? = nil)
    -> Self
  {
    .init(
      displayID: displayID ?? self.displayID,
      gamerID: gamerID ?? self.gamerID,
      locale: locale ?? self.locale,
      level: level ?? self.level,
      defaultProduct: defaultProduct ?? self.defaultProduct)
  }
}

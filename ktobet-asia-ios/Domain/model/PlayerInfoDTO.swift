import Foundation
import sharedbu

struct PlayerInfoDTO {
    let displayID: String
    let gamerID: String
    let level: Int
    let defaultProduct: ProductType
  
    func copy(
        displayID: String? = nil,
        gamerID: String? = nil,
        level: Int? = nil,
        defaultProduct: ProductType? = nil)
        -> Self
    {
        .init(
            displayID: displayID ?? self.displayID,
            gamerID: gamerID ?? self.gamerID,
            level: level ?? self.level,
            defaultProduct: defaultProduct ?? self.defaultProduct)
    }
}

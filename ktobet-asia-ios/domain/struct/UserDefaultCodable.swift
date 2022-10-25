import Foundation
import SharedBu

struct PlayerInfoCache: Codable {
    let account: String
    let ID: String
    let locale: String
    let VIPLevel: Int32
    let defaultProduct: Int32
}

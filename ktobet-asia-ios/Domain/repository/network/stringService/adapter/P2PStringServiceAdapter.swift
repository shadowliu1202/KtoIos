import Foundation
import sharedbu

class P2PStringServiceAdapter: P2PStringService {
  let productBanker = ResourceKey(key: Localize.string("product_banker"))
  let productGamePlayer = ResourceKey(key: Localize.string("product_game_player"))
  let productNoPlayer = ResourceKey(key: Localize.string("product_no_player"))
}

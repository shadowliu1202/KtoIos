import Foundation
import SharedBu

class CasinoStringServiceAdapter: CasinoStringService {
  let productBanker = ResourceKey(key: Localize.string("product_banker"))
  let productBlack = ResourceKey(key: Localize.string("product_black"))
  let productBlackBull = ResourceKey(key: Localize.string("product_black_bull"))
  let productDi = ResourceKey(key: Localize.string("product_di"))
  let productDragon = ResourceKey(key: Localize.string("product_dragon"))
  let productFirstCard = ResourceKey(key: Localize.string("product_first_card"))
  let productGamePlayer = ResourceKey(key: Localize.string("product_game_player"))
  let productHuang = ResourceKey(key: Localize.string("product_huang"))
  let productPhoenix = ResourceKey(key: Localize.string("product_phoenix"))
  let productPlayer = ResourceKey(key: Localize.string("product_player"))
  let productPlayerWithPosition = ResourceKey(key: Localize.string("product_game_player_with_position"))
  let productRed = ResourceKey(key: Localize.string("product_red"))
  let productRedBull = ResourceKey(key: Localize.string("product_red_bull"))
  let productSplit = ResourceKey(key: Localize.string("product_split"))
  let productTian = ResourceKey(key: Localize.string("product_tian"))
  let productTiger = ResourceKey(key: Localize.string("product_tiger"))
  let productXuan = ResourceKey(key: Localize.string("product_xuan"))
  var productNoPlayer = ResourceKey(key: Localize.string("product_no_player"))
}

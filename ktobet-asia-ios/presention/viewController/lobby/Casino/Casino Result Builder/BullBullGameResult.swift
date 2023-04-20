import SharedBu
import UIKit

protocol BullBullGameResult {
  var firstCard: PokerCard? { get }
  var bankerCards: [PokerCard] { get }
  var playerFirstCards: [PokerCard] { get }
  var playerSecondCards: [PokerCard] { get }
  var playerThirdCards: [PokerCard] { get }
}

extension CasinoGameResult.BullBull: BullBullGameResult { }

struct BullBullGameResultBuilder: CasinoResultBuilder {
  let result: BullBullGameResult

  func build(to background: UIView) {
    var rowViews = [
      pokerCardsRow(
        title: Localize.string("product_banker_title"),
        pokerCards: result.bankerCards),
      pokerCardsRow(
        title: Localize.string("product_player_1_title"),
        pokerCards: result.playerFirstCards),
      pokerCardsRow(
        title: Localize.string("product_player_2_title"),
        pokerCards: result.playerSecondCards),
      pokerCardsRow(
        title: Localize.string("product_player_3_title"),
        pokerCards: result.playerThirdCards),
    ]

    if let firstCard = result.firstCard {
      rowViews.insert(
        pokerCardsRow(
          title: Localize.string("product_first_card"),
          pokerCards: [firstCard]),
        at: 0)
    }

    addPokerCardsRowsStackView(rowViews: rowViews, to: background)
  }
}

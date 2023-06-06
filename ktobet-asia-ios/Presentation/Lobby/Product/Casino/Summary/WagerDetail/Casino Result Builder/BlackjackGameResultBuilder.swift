import SharedBu
import UIKit

struct BlackjackGameResultBuilder: CasinoResultBuilder {
  let result: CasinoGameResult.BlackjackN2

  func build(to background: UIView) {
    addPokerCardsRowsStackView(
      rowViews: [
        pokerCardsRow(
          title: Localize.string("product_dealer"),
          pokerCards: result.dealerCards),
        pokerCardsRow(
          title: Localize.string("product_player"),
          pokerCards: result.playerCards),
        pokerCardsRow(
          title: Localize.string("product_split"),
          pokerCards: result.splitCards),
      ],
      to: background)
  }
}

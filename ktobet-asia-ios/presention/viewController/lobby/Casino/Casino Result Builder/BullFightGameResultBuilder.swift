import SharedBu
import UIKit

struct BullFightGameResultBuilder: CasinoResultBuilder {
  let result: CasinoGameResult.BullFight

  func build(to background: UIView) {
    addPokerCardsRowsStackView(
      rowViews: [
        pokerCardsRow(
          title: Localize.string("product_black_bull"),
          pokerCards: result.blackCards),
        pokerCardsRow(
          title: Localize.string("product_red_bull"),
          pokerCards: result.redCards),
      ],
      to: background)
  }
}

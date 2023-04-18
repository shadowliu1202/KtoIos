import SharedBu
import UIKit

protocol TwoSideGameResult {
  var leftTitleKey: String { get }
  var leftCards: [PokerCard] { get }
  var rightTitleKey: String { get }
  var rightCards: [PokerCard] { get }
  var spacing: CGFloat { get }
}

extension CasinoGameResult.Baccarat: TwoSideGameResult {
  var leftTitleKey: String { "product_player_title" }
  var leftCards: [PokerCard] { playerCards }
  var rightTitleKey: String { "product_banker_title" }
  var rightCards: [PokerCard] { bankerCards }
  var spacing: CGFloat { 32 }
}

extension CasinoGameResult.DragonTiger: TwoSideGameResult {
  var leftTitleKey: String { "product_dragon_title" }
  var leftCards: [PokerCard] { dragonCards }
  var rightTitleKey: String { "product_tiger_title" }
  var rightCards: [PokerCard] { tigerCards }
  var spacing: CGFloat { 138 }
}

extension CasinoGameResult.WinThreeCards: TwoSideGameResult {
  var leftTitleKey: String { "product_dragon_title" }
  var leftCards: [PokerCard] { dragonCards }
  var rightTitleKey: String { "product_phonix_title" }
  var rightCards: [PokerCard] { phoenixCards }
  var spacing: CGFloat { 32 }
}

struct TwoSideGameResultBuilder: CasinoResultBuilder {
  let result: TwoSideGameResult

  func build(to background: UIView) {
    let stackView = UIStackView(
      arrangedSubviews: [
        cardStackView(
          title: Localize.string(result.leftTitleKey),
          cardsView: result.leftCards
            .map { pokerCardView(number: $0.pokerNumber, suit: $0.pokerSuits) }),
        cardStackView(
          title: Localize.string(result.rightTitleKey),
          cardsView: result.rightCards
            .map { pokerCardView(number: $0.pokerNumber, suit: $0.pokerSuits) })
      ],
      spacing: result.spacing,
      axis: .horizontal,
      distribution: .equalSpacing,
      alignment: .fill)

    background.addBorder(.bottom)
    background.addSubview(stackView)
    stackView.snp.makeConstraints { make in
      make.top.equalToSuperview()
      make.centerX.equalToSuperview()
      make.left.greaterThanOrEqualToSuperview().inset(39)
      make.right.lessThanOrEqualToSuperview().inset(39)
      make.bottom.equalToSuperview().inset(30)
    }
  }
}

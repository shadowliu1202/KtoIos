import SharedBu
import UIKit

struct SicboGameResultBuilder: CasinoResultBuilder {
  let sicbo: CasinoGameResult.Sicbo

  func build(to background: UIView) {
    let stackView = UIStackView(
      arrangedSubviews: sicbo.diceNumbers.compactMap { diceImageView($0) },
      spacing: 16,
      axis: .horizontal,
      distribution: .equalSpacing,
      alignment: .center)

    background.addBorder(.bottom)
    background.addSubview(stackView)
    stackView.snp.makeConstraints { make in
      make.top.equalToSuperview()
      make.centerX.equalToSuperview()
      make.left.greaterThanOrEqualToSuperview().inset(30)
      make.right.lessThanOrEqualToSuperview().inset(30)
      make.bottom.equalToSuperview().inset(30)
    }
  }
}

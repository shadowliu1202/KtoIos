import SharedBu
import UIKit

protocol CasinoResultBuilder {
  func build(to background: UIView)
}

extension CasinoResultBuilder {
  func pokerCardView(number: PokerNumber, suit: PokerSuits) -> UIView {
    let squareView = UIView()
    squareView.heightAnchor.constraint(equalToConstant: 54).isActive = true
    squareView.widthAnchor.constraint(equalToConstant: 36).isActive = true
    squareView.backgroundColor = UIColor.white
    squareView.cornerRadius = 8

    let numberLabel = UILabel(frame: CGRect(x: 6, y: 5, width: 24, height: 24))
    squareView.addSubview(numberLabel)
    numberLabel.text = number.stringValue
    numberLabel.font = UIFont(name: "PingFangTC-Semibold", size: 20)
    numberLabel.textAlignment = .center

    if suit == PokerSuits.diamond || suit == PokerSuits.heart {
      numberLabel.textColor = UIColor.primaryDefault
    }
    else {
      numberLabel.textColor = UIColor.greyScaleDefault
    }

    let img = UIImageView(frame: CGRect(
      x: 0, y: numberLabel.frame.height + numberLabel.frame.origin.y,
      width: 18, height: 18))
    img.image = suit.image
    img.center.x = numberLabel.center.x
    squareView.addSubview(img)

    return squareView
  }

  func cardStackView(title: String, cardsView: [UIView]) -> UIStackView {
    let titleLabel = UILabel()
    titleLabel.textColor = UIColor.greyScaleWhite
    titleLabel.font = UIFont(name: "PingFangSC-Regular", size: 14)
    titleLabel.text = title

    let cardStack = UIStackView(
      arrangedSubviews: cardsView,
      spacing: 8,
      axis: .horizontal,
      distribution: .fillEqually,
      alignment: .fill)

    return UIStackView(
      arrangedSubviews: [titleLabel, cardStack],
      spacing: 8,
      axis: .vertical,
      distribution: .equalSpacing,
      alignment: .center)
  }

  func diceImageView(_ diceNumber: DiceNumber) -> UIImageView? {
    guard let image = diceNumber.image else { return nil }
    let imageView = UIImageView(image: image)

    imageView.snp.makeConstraints { make in
      make.size.equalTo(44)
    }

    return imageView
  }

  func pokerCardsRow(title: String, pokerCards: [PokerCard]) -> UIView? {
    guard !pokerCards.isEmpty else { return nil }

    let numbersOfCardPerRow = 7
    let numbersOfRow = Int(ceil(Double(pokerCards.count / numbersOfCardPerRow))) + 1

    let backgroundView = UIView()
    let titleLabel = UILabel()
    titleLabel.textColor = UIColor.greyScaleWhite
    titleLabel.font = UIFont(name: "PingFangSC-Regular", size: 14)
    titleLabel.text = title

    backgroundView.addSubview(titleLabel)
    titleLabel.snp.makeConstraints { make in
      make.top.left.right.equalToSuperview()
    }

    let fullStackView = UIStackView(
      spacing: 16,
      axis: .vertical,
      distribution: .equalSpacing,
      alignment: .fill)

    backgroundView.addSubview(fullStackView)
    fullStackView.snp.makeConstraints { make in
      make.top.equalTo(titleLabel.snp.bottom).inset(-8)
      make.left.bottom.equalToSuperview()
      make.right.lessThanOrEqualToSuperview()
    }

    var currentCardIndex = 0
    (1...numbersOfRow).forEach { rowIndex in
      let endOfRowCardIndex = rowIndex * numbersOfCardPerRow > pokerCards.count ?
        pokerCards.count : rowIndex * numbersOfCardPerRow

      let rowStack = UIStackView(
        arrangedSubviews:
        pokerCards[currentCardIndex..<endOfRowCardIndex]
          .map {
            pokerCardView(number: $0.pokerNumber, suit: $0.pokerSuits)
          },
        spacing: 8, axis: .horizontal,
        distribution: .equalSpacing,
        alignment: .leading)

      let isLastRowAndRowNotFull = rowIndex == numbersOfRow &&
        (pokerCards.count % numbersOfCardPerRow) != 0

      if isLastRowAndRowNotFull {
        rowStack.addArrangedSubview(.init())
      }

      fullStackView.addArrangedSubview(rowStack)

      currentCardIndex = endOfRowCardIndex
    }

    return backgroundView
  }

  func addPokerCardsRowsStackView(rowViews: [UIView?], to background: UIView) {
    let stackView = UIStackView(
      arrangedSubviews: rowViews.compactMap { $0 },
      spacing: 16,
      axis: .vertical,
      distribution: .fillEqually,
      alignment: .fill)

    background.addSubview(stackView)
    stackView.snp.makeConstraints { make in
      make.top.equalToSuperview()
      make.left.right.equalToSuperview().inset(30)
      make.bottom.equalToSuperview().inset(30)
    }

    background.addBorder(.bottom)
  }
}

extension PokerNumber {
  fileprivate var stringValue: String {
    switch self {
    case .ace:
      return "A"
    case .two:
      return "2"
    case .three:
      return "3"
    case .four:
      return "4"
    case .five:
      return "5"
    case .six:
      return "6"
    case .seven:
      return "7"
    case .eight:
      return "8"
    case .night:
      return "9"
    case .ten:
      return "10"
    case .jack:
      return "J"
    case .queen:
      return "Q"
    case .king:
      return "K"
    default:
      return ""
    }
  }
}

extension PokerSuits {
  fileprivate var image: UIImage? {
    switch self {
    case .clover:
      return UIImage(named: "iconPokerClover")
    case .diamond:
      return UIImage(named: "iconPokerDiamond")
    case .heart:
      return UIImage(named: "iconPokerHeart")
    case .spades:
      return UIImage(named: "iconPokerSpades")
    default:
      return nil
    }
  }
}

extension DiceNumber {
  fileprivate var image: UIImage? {
    switch self {
    case .one:
      return UIImage(named: "sicbo-1")
    case .two:
      return UIImage(named: "sicbo-2")
    case .three:
      return UIImage(named: "sicbo-3")
    case .four:
      return UIImage(named: "sicbo-4")
    case .five:
      return UIImage(named: "sicbo-5")
    case .six:
      return UIImage(named: "sicbo-6")
    default:
      return nil
    }
  }
}

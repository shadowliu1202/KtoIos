import RxSwift
import SharedBu
import UIKit

class CasinoDetailViewController: LobbyViewController {
  static let segueIdentifier = "toCasinoDetailViewController"
  @IBOutlet private weak var tableView: UITableView!
  @IBOutlet private weak var scrollView: UIScrollView!
  @IBOutlet private weak var betResultTitleLabel: UILabel!
  @IBOutlet private weak var backgroundView: UIView!
  @IBOutlet private weak var tableViewHeightConstant: NSLayoutConstraint!

  private let localStorageRepo = Injectable.resolve(LocalStorageRepository.self)!
  private var viewModel = Injectable.resolve(CasinoViewModel.self)!
  private var disposeBag = DisposeBag()

  var wagerId: String! = ""
  var recordDetail: CasinoDetail?

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(
      vc: self,
      barItemType: .back,
      title: Localize.string("balancelog_wager_detail"))
    tableView.dataSource = self
    tableView.delegate = self
    tableView.setHeaderFooterDivider(footerHeight: 0)
    viewModel.getWagerDetail(wagerId: wagerId).subscribe { [weak self] detail in
      guard let self, let detail else { return }
      self.recordDetail = detail
      self.tableView.reloadData()
      self.displayGameResult(detail)
    } onFailure: { [weak self] error in
      self?.handleErrors(error)
    }.disposed(by: disposeBag)
  }

  override func viewDidLayoutSubviews() {
    self.tableViewHeightConstant.constant = self.tableView.contentSize.height
  }

  deinit {
    print("CasinoDetailViewController deinit")
  }

  private func displayGameResult(_ detail: CasinoDetail) {
    switch detail.status {
    case .canceled,
         .void_:
      createCancelView()
    case .bet,
         .settled:
      createResultView(gameResult: detail.gameResult)
    default:
      break
    }
  }

  private func createCancelView() {
    let cancelTitleLabel = UILabel()
    cancelTitleLabel.text = Localize.string("common_cancel")
    cancelTitleLabel.font = UIFont(name: "PingFangSC-Medium", size: 14)
    cancelTitleLabel.textColor = UIColor.whitePure
    scrollView.addSubview(cancelTitleLabel)
    cancelTitleLabel.translatesAutoresizingMaskIntoConstraints = false
    cancelTitleLabel.leadingAnchor.constraint(equalTo: betResultTitleLabel.leadingAnchor, constant: 0).isActive = true
    cancelTitleLabel.topAnchor.constraint(equalTo: betResultTitleLabel.bottomAnchor, constant: 4).isActive = true
    addResultBottomLine()
  }

  private func addResultBottomLine() {
    let bottomBorderLine = UIView()
    bottomBorderLine.backgroundColor = UIColor.gray3C3E40
    scrollView.addSubview(bottomBorderLine)
    bottomBorderLine.translatesAutoresizingMaskIntoConstraints = false
    bottomBorderLine.widthAnchor.constraint(equalTo: self.scrollView.widthAnchor, multiplier: 1).isActive = true
    bottomBorderLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
    bottomBorderLine.topAnchor.constraint(equalTo: betResultTitleLabel.bottomAnchor, constant: 40).isActive = true
    bottomBorderLine.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
  }
}

// MARK: - TableView Delegate, DataSource

extension CasinoDetailViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    self.recordDetail == nil ? 0 : 6
  }

  func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    guard let detail = recordDetail else { return 0 }
    if indexPath.row == 0 || (indexPath.row == 4 && detail.prededuct != AccountCurrency.zero()) {
      return 90
    }
    else {
      return 70
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let detail = recordDetail else { return UITableViewCell() }
    if indexPath.row == 0 || (detail.prededuct != AccountCurrency.zero() && indexPath.row == 4) {
      if
        let cell = tableView.dequeueReusableCell(
          withIdentifier: "CasinoDetailRecord3Cell",
          for: indexPath) as? CasinoDetailRecord3TableViewCell
      {
        cell.removeBorder()
        if indexPath.row == 0 {
          cell.betIdLabel.text = detail.betId
          cell.otherBetIdLabel.text = detail.otherId
        }

        if indexPath.row == 4 {
          cell.titleLabel.text = Localize.string("product_bet_amount")
          cell.betIdLabel.text = detail.stakes.description()
          cell.otherBetIdLabel.text = Localize.string("product_prededuct") + " " + detail.prededuct.description()
          cell.otherBetIdLabel.font = UIFont(name: "PingFangSC-Semibold", size: 14)
          cell.otherBetIdLabel.textColor = UIColor.whitePure
        }

        if indexPath.row != 0 {
          cell.addBorder(rightConstant: 30, leftConstant: 30)
        }

        return cell
      }
    }
    else {
      if
        let cell = tableView.dequeueReusableCell(
          withIdentifier: "CasinoDetailRecord2Cell",
          for: indexPath) as? CasinoDetailRecord2TableViewCell
      {
        cell.setup(index: indexPath.row, detail: detail, supportLocal: localStorageRepo.getSupportLocale())

        if indexPath.row != 0 {
          cell.addBorder(rightConstant: 30, leftConstant: 30)
        }
        if indexPath.row == 5 {
          cell.addBorder(.bottom, rightConstant: 30, leftConstant: 30)
        }
        return cell
      }
    }

    return UITableViewCell()
  }
}

// MARK: - Create Result View

extension CasinoDetailViewController {
  private func createResultView(gameResult: CasinoGameResult) {
    if
      gameResult is CasinoGameResult.Baccarat ||
      gameResult is CasinoGameResult.DragonTiger ||
      gameResult is CasinoGameResult.WinThreeCards
    {
      createTwoSideThreeCardsResultView(gameResult: gameResult)
      return
    }

    if let sicbo = gameResult as? CasinoGameResult.Sicbo {
      createSicboResultView(gameResult: sicbo)
      return
    }

    if let roulette = gameResult as? CasinoGameResult.Roulette {
      createRouletteResultView(gameResult: roulette)
      return
    }

    if
      gameResult is CasinoGameResult.BullBull ||
      gameResult is CasinoGameResult.BullFight ||
      gameResult is CasinoGameResult.BlackjackN2
    {
      createRowPokerCardsResultView(gameResult: gameResult)
    }

    if gameResult is CasinoGameResult.Unknown {
      addResultBottomLine()
    }
  }

  private func createTwoSideThreeCardsResultView(gameResult: CasinoGameResult) {
    let spacing: CGFloat

    let leftTitle: String
    let leftCards: [UIView]

    let rightTitle: String
    let rightCards: [UIView]

    if let baccarat = gameResult as? CasinoGameResult.Baccarat {
      spacing = 32

      leftTitle = Localize.string("product_player_title")
      leftCards = baccarat.playerCards
        .map {
          addPokerCard(
            pokerCardNumber: setPokerNumber(pokerNumber: $0.pokerNumber),
            pokerCardSuit: $0.pokerSuits)
        }

      rightTitle = Localize.string("product_banker_title")
      rightCards = baccarat.bankerCards
        .map {
          addPokerCard(
            pokerCardNumber: setPokerNumber(pokerNumber: $0.pokerNumber),
            pokerCardSuit: $0.pokerSuits)
        }
    }
    else if let dragonTiger = gameResult as? CasinoGameResult.DragonTiger {
      spacing = 138

      leftTitle = Localize.string("product_dragon_title")
      leftCards = dragonTiger.dragonCards
        .map {
          addPokerCard(
            pokerCardNumber: setPokerNumber(pokerNumber: $0.pokerNumber),
            pokerCardSuit: $0.pokerSuits)
        }

      rightTitle = Localize.string("product_tiger_title")
      rightCards = dragonTiger.tigerCards
        .map {
          addPokerCard(
            pokerCardNumber: setPokerNumber(pokerNumber: $0.pokerNumber),
            pokerCardSuit: $0.pokerSuits)
        }
    }
    else if let winThreeCards = gameResult as? CasinoGameResult.WinThreeCards {
      spacing = 32

      leftTitle = Localize.string("product_dragon_title")
      leftCards = winThreeCards.dragonCards
        .map {
          addPokerCard(
            pokerCardNumber: setPokerNumber(pokerNumber: $0.pokerNumber),
            pokerCardSuit: $0.pokerSuits)
        }

      rightTitle = Localize.string("product_phonix_title")
      rightCards = winThreeCards.phoenixCards
        .map {
          addPokerCard(
            pokerCardNumber: setPokerNumber(pokerNumber: $0.pokerNumber),
            pokerCardSuit: $0.pokerSuits)
        }
    }
    else {
      return
    }

    let stackView = UIStackView(
      arrangedSubviews: [
        buildCardStackView(title: leftTitle, cardsView: leftCards),
        buildCardStackView(title: rightTitle, cardsView: rightCards),
      ],
      spacing: spacing,
      axis: .horizontal,
      distribution: .equalSpacing,
      alignment: .fill)

    backgroundView.addBorder(.bottom)
    backgroundView.addSubview(stackView)
    stackView.snp.makeConstraints { make in
      make.top.equalToSuperview()
      make.centerX.equalToSuperview()
      make.left.greaterThanOrEqualToSuperview().inset(39)
      make.right.lessThanOrEqualToSuperview().inset(39)
      make.bottom.equalToSuperview().inset(30)
    }
  }

  private func createRowPokerCardsResultView(gameResult: CasinoGameResult) {
    let stackView = UIStackView(
      spacing: 16,
      axis: .vertical,
      distribution: .fillEqually,
      alignment: .fill)

    backgroundView.addSubview(stackView)
    stackView.snp.makeConstraints { make in
      make.top.equalToSuperview()
      make.left.right.equalToSuperview().inset(30)
      make.bottom.equalToSuperview().inset(30)
    }

    if let bullBull = gameResult as? CasinoGameResult.BullBull {
      createBullBullResultView(gameResult: bullBull, stackView: stackView)
    }
    else if let bullFight = gameResult as? CasinoGameResult.BullFight {
      createBullFightResultView(gameResult: bullFight, stackView: stackView)
    }
    else if let blackjackN2 = gameResult as? CasinoGameResult.BlackjackN2 {
      createN2BlackJackResultView(gameResult: blackjackN2, stackView: stackView)
    }

    backgroundView.addBorder(.bottom)
  }

  private func createBullBullResultView(
    gameResult: CasinoGameResult.BullBull,
    stackView: UIStackView)
  {
    if let firstCard = gameResult.firstCard {
      let firstCardView = createOneRowOfPokerCards(pokerCards: [firstCard], title: Localize.string("product_first_card"))
      stackView.addArrangedSubview(firstCardView)
    }

    let bankerCardView = createOneRowOfPokerCards(
      pokerCards: gameResult.bankerCards,
      title: Localize.string("product_banker_title"))
    let playerFirstCardView = createOneRowOfPokerCards(
      pokerCards: gameResult.playerFirstCards,
      title: Localize.string("product_player_1_title"))
    let playerSecondCardView = createOneRowOfPokerCards(
      pokerCards: gameResult.playerSecondCards,
      title: Localize.string("product_player_2_title"))
    let playerThirdCardView = createOneRowOfPokerCards(
      pokerCards: gameResult.playerThirdCards,
      title: Localize.string("product_player_3_title"))

    stackView.addArrangedSubview(bankerCardView)
    stackView.addArrangedSubview(playerFirstCardView)
    stackView.addArrangedSubview(playerSecondCardView)
    stackView.addArrangedSubview(playerThirdCardView)
  }

  private func createBullFightResultView(
    gameResult: CasinoGameResult.BullFight,
    stackView: UIStackView)
  {
    let blackBullView = createOneRowOfPokerCards(
      pokerCards: gameResult.blackCards,
      title: Localize.string("product_black_bull"))
    let redBullView = createOneRowOfPokerCards(pokerCards: gameResult.redCards, title: Localize.string("product_red_bull"))

    stackView.addArrangedSubview(blackBullView)
    stackView.addArrangedSubview(redBullView)
  }

  private func createN2BlackJackResultView(
    gameResult: CasinoGameResult.BlackjackN2,
    stackView: UIStackView)
  {
    createOneRowOfN2BlackJackResultView(
      pokerCards: gameResult.dealerCards,
      title: Localize.string("product_dealer"),
      stackView: stackView)
    createOneRowOfN2BlackJackResultView(
      pokerCards: gameResult.playerCards,
      title: Localize.string("product_player"),
      stackView: stackView)
    createOneRowOfN2BlackJackResultView(
      pokerCards: gameResult.splitCards,
      title: Localize.string("product_split"),
      stackView: stackView)
  }

  private func createRouletteResultView(gameResult: CasinoGameResult.Roulette) {
    let label = UILabel()
    label.text = String(gameResult.result)
    label.font = UIFont(name: "PingFangTC-Semibold", size: 18)
    label.textColor = UIColor.whitePure
    label.textAlignment = .center
    label.backgroundColor = .redF20000
    label.cornerRadius = 20

    backgroundView.addSubview(label)
    label.snp.makeConstraints { make in
      make.size.equalTo(40)
      make.centerX.equalToSuperview()
      make.centerY.equalTo(30)
    }

    backgroundView.snp.makeConstraints { make in
      make.height.equalTo(90)
    }

    backgroundView.addBorder(.bottom)
  }

  private func createSicboResultView(gameResult: CasinoGameResult.Sicbo) {
    let stackView = UIStackView(
      arrangedSubviews: gameResult.diceNumbers
        .compactMap {
          guard let image = setDiceNumber(diceNumber: $0) else { return nil }
          let imageView = UIImageView(image: image)

          imageView.snp.makeConstraints { make in
            make.size.equalTo(44)
          }

          return imageView
        },
      spacing: 16,
      axis: .horizontal,
      distribution: .equalSpacing,
      alignment: .center)

    backgroundView.addBorder(.bottom)
    backgroundView.addSubview(stackView)
    stackView.snp.makeConstraints { make in
      make.top.equalToSuperview()
      make.centerX.equalToSuperview()
      make.left.greaterThanOrEqualToSuperview().inset(30)
      make.right.lessThanOrEqualToSuperview().inset(30)
      make.bottom.equalToSuperview().inset(30)
    }
  }
}

// MARK: - Result View Components

extension CasinoDetailViewController {
  private func createOneRowOfN2BlackJackResultView(
    pokerCards: [PokerCard],
    title: String,
    stackView: UIStackView)
  {
    guard pokerCards.count > 0 else { return }
    let row = createOneRowOfPokerCards(pokerCards: pokerCards, title: title)
    stackView.addArrangedSubview(row)
  }

  private func buildCardStackView(
    title: String,
    cardsView: [UIView])
    -> UIStackView
  {
    let titleLabel = UILabel()
    titleLabel.textColor = UIColor.whitePure
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

  private func addPokerCard(pokerCardNumber: String, pokerCardSuit: PokerSuits) -> UIView {
    let squareView = UIView()
    squareView.heightAnchor.constraint(equalToConstant: 54).isActive = true
    squareView.widthAnchor.constraint(equalToConstant: 36).isActive = true
    squareView.backgroundColor = UIColor.white
    squareView.cornerRadius = 8

    let numberLabel = UILabel(frame: CGRect(x: 6, y: 5, width: 24, height: 24))
    squareView.addSubview(numberLabel)
    numberLabel.text = pokerCardNumber
    numberLabel.font = UIFont(name: "PingFangTC-Semibold", size: 20)
    numberLabel.textAlignment = .center
    if pokerCardSuit == PokerSuits.diamond || pokerCardSuit == PokerSuits.heart {
      numberLabel.textColor = UIColor.redF20000
    }
    else {
      numberLabel.textColor = UIColor.black131313
    }

    let img = UIImageView(frame: CGRect(x: 0, y: numberLabel.frame.height + numberLabel.frame.origin.y, width: 18, height: 18))
    img.image = setPokerCardSuit(pokerCardSuit: pokerCardSuit)
    img.center.x = numberLabel.center.x
    squareView.addSubview(img)
    return squareView
  }

  private func createOneRowOfPokerCards(pokerCards: [PokerCard], title: String) -> UIView {
    let numbersOfCardPerRow = 7
    let numbersOfRow = Int(ceil(Double(pokerCards.count / numbersOfCardPerRow))) + 1

    let backgroundView = UIView()
    let titleLabel = UILabel()
    titleLabel.textColor = UIColor.whitePure
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
            addPokerCard(
              pokerCardNumber: setPokerNumber(pokerNumber: $0.pokerNumber),
              pokerCardSuit: $0.pokerSuits)
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

  private func setPokerNumber(pokerNumber: PokerNumber) -> String {
    switch pokerNumber {
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

  private func setPokerCardSuit(pokerCardSuit: PokerSuits) -> UIImage? {
    switch pokerCardSuit {
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

  private func setDiceNumber(diceNumber: DiceNumber) -> UIImage? {
    switch diceNumber {
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

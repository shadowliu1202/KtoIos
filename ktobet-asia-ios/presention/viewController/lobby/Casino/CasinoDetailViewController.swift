import UIKit
import RxSwift
import SharedBu

class CasinoDetailViewController: LobbyViewController {
    static let segueIdentifier = "toCasinoDetailViewController"
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var betResultTitleLabel: UILabel!
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var backgroundViewHeightConstant: NSLayoutConstraint!
    @IBOutlet private weak var tableViewHeightConstant: NSLayoutConstraint!
    
    private var viewModel = DI.resolve(CasinoViewModel.self)!
    private var disposeBag = DisposeBag()
    
    var wagerId: String! = ""
    var recordDetail: CasinoDetail?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, title: Localize.string("balancelog_wager_detail"))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.setHeaderFooterDivider(footerHeight: 0)
        viewModel.getWagerDetail(wagerId: wagerId).subscribe {[weak self] (detail) in
            guard let self = self, let detail = detail else { return }
            self.recordDetail = detail
            self.tableView.reloadData()
            self.displayGameResult(detail)
        } onError: {[weak self] (error) in
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
        case .canceled, .void_ :
            createCancelView()
        case .bet, .settled:
            createResultView(gameResult: detail.gameResult)
        default:
            break
        }
    }
    
    private func createCancelView() {
        let cancelTitleLabel = UILabel()
        cancelTitleLabel.text = Localize.string("common_cancel")
        cancelTitleLabel.font = UIFont(name: "PingFangSC-Medium", size: 14)
        cancelTitleLabel.textColor = UIColor.whiteFull
        scrollView.addSubview(cancelTitleLabel)
        cancelTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cancelTitleLabel.leadingAnchor.constraint(equalTo: betResultTitleLabel.leadingAnchor, constant: 0).isActive = true
        cancelTitleLabel.topAnchor.constraint(equalTo: betResultTitleLabel.bottomAnchor, constant: 4).isActive = true
        addResultBottomLine()
    }
    
    private func addResultBottomLine() {
        let bottomBorderLine = UIView()
        bottomBorderLine.backgroundColor = UIColor.dividerCapeCodGray2
        scrollView.addSubview(bottomBorderLine)
        bottomBorderLine.translatesAutoresizingMaskIntoConstraints = false
        bottomBorderLine.widthAnchor.constraint(equalTo: self.scrollView.widthAnchor, multiplier: 1).isActive = true
        bottomBorderLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        bottomBorderLine.topAnchor.constraint(equalTo: betResultTitleLabel.bottomAnchor, constant: 40).isActive = true
        bottomBorderLine.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
    }
    
    private func createResultView(gameResult: CasinoGameResult) {
        if gameResult is CasinoGameResult.Baccarat ||
            gameResult is CasinoGameResult.DragonTiger ||
            gameResult is CasinoGameResult.WinThreeCards {
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
        
        if gameResult is CasinoGameResult.BullBull ||
            gameResult is CasinoGameResult.BullFight ||
            gameResult is CasinoGameResult.BlackjackN2 {
            createRowPokerCardsResultView(gameResult: gameResult)
        }
        
        if gameResult is CasinoGameResult.Unknown {
            addResultBottomLine()
        }
    }
    
    private func createTwoSideThreeCardsResultView(gameResult: CasinoGameResult) {
        var leftRightSpacing: CGFloat = 0
        var leftTitle = ""
        var rightTitle = ""
        var leftCardViews: [UIView] = []
        var rightCardViews: [UIView] = []
        
        if let baccarat = gameResult as? CasinoGameResult.Baccarat {
            leftRightSpacing = 36
            leftTitle = Localize.string("product_player_title")
            rightTitle = Localize.string("product_banker_title")
            baccarat.playerCards.forEach{ leftCardViews.append(addPokerCard(pokerCardNumber: setPokerNumber(pokerNumber: $0.pokerNumber), pokerCardSuit: $0.pokerSuits)) }
            baccarat.bankerCards.forEach{ rightCardViews.append(addPokerCard(pokerCardNumber: setPokerNumber(pokerNumber: $0.pokerNumber), pokerCardSuit: $0.pokerSuits)) }
        }
        
        if let dragonTiger = gameResult as? CasinoGameResult.DragonTiger {
            leftRightSpacing = 120
            leftTitle = Localize.string("product_dragon_title")
            rightTitle = Localize.string("product_tiger_title")
            dragonTiger.dragonCards.forEach{ leftCardViews.append(addPokerCard(pokerCardNumber: setPokerNumber(pokerNumber: $0.pokerNumber), pokerCardSuit: $0.pokerSuits)) }
            dragonTiger.tigerCards.forEach{ rightCardViews.append(addPokerCard(pokerCardNumber: setPokerNumber(pokerNumber: $0.pokerNumber), pokerCardSuit: $0.pokerSuits)) }
        }
        
        if let winThreeCards = gameResult as? CasinoGameResult.WinThreeCards {
            leftRightSpacing = 36
            leftTitle = Localize.string("product_dragon_title")
            rightTitle = Localize.string("product_phonix_title")
            winThreeCards.dragonCards.forEach{ leftCardViews.append(addPokerCard(pokerCardNumber: setPokerNumber(pokerNumber: $0.pokerNumber), pokerCardSuit: $0.pokerSuits)) }
            winThreeCards.phoenixCards.forEach{ rightCardViews.append(addPokerCard(pokerCardNumber: setPokerNumber(pokerNumber: $0.pokerNumber), pokerCardSuit: $0.pokerSuits)) }
        }
        
        backgroundView.addBorder(.bottom)
        let stackView = UIStackView()
        backgroundView.addSubview(stackView)
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = leftRightSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor).isActive = true
        stackView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor).isActive = true
        
        let leftStackView = UIStackView()
        leftStackView.axis = .horizontal
        leftStackView.distribution = .fillEqually
        leftStackView.alignment = .fill
        leftStackView.spacing = 8
        stackView.addArrangedSubview(leftStackView)
        
        let rightStackView = UIStackView()
        rightStackView.axis = .horizontal
        rightStackView.distribution = .fillEqually
        rightStackView.alignment = .fill
        rightStackView.spacing = 8
        stackView.addArrangedSubview(rightStackView)
        
        leftCardViews.forEach { leftStackView.addArrangedSubview($0) }
        rightCardViews.forEach { rightStackView.addArrangedSubview($0) }
        
        let leftTitleLabel = UILabel()
        backgroundView.addSubview(leftTitleLabel)
        leftTitleLabel.textColor = UIColor.whiteFull
        leftTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        leftTitleLabel.centerXAnchor.constraint(equalTo: leftStackView.centerXAnchor).isActive = true
        leftTitleLabel.bottomAnchor.constraint(equalTo: stackView.topAnchor, constant: -7).isActive = true
        leftTitleLabel.text = leftTitle
        
        let rightTitleLabel = UILabel()
        backgroundView.addSubview(rightTitleLabel)
        rightTitleLabel.textColor = UIColor.whiteFull
        rightTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        rightTitleLabel.centerXAnchor.constraint(equalTo: rightStackView.centerXAnchor).isActive = true
        rightTitleLabel.bottomAnchor.constraint(equalTo: stackView.topAnchor, constant: -7).isActive = true
        rightTitleLabel.text = rightTitle
    }
    
    private func createRowPokerCardsResultView(gameResult: CasinoGameResult) {
        let stackView = UIStackView()
        self.backgroundView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 0).isActive = true
        stackView.leadingAnchor.constraint(equalTo: self.backgroundView.leadingAnchor, constant: 24).isActive = true
        
        if let bullBull = gameResult as? CasinoGameResult.BullBull {
            createBullBullResultView(gameResult: bullBull, stackView: stackView)
            return
        }
        
        if let bullFight = gameResult as? CasinoGameResult.BullFight {
            createBullFightResultView(gameResult: bullFight, stackView: stackView)
            return
        }
        
        if let blackjackN2 = gameResult as? CasinoGameResult.BlackjackN2 {
            createN2BlackJackResultView(gameResult: blackjackN2, stackView: stackView)
        }
    }
    
    private func createBullFightResultView(gameResult: CasinoGameResult.BullFight, stackView: UIStackView) {
        let blackBullView = createOneRowOfPokerCards(pokerCards: gameResult.blackCards, title: Localize.string("product_black_bull"))
        let redBullView = createOneRowOfPokerCards(pokerCards: gameResult.redCards, title: Localize.string("product_red_bull"))
        stackView.addArrangedSubview(blackBullView)
        stackView.addArrangedSubview(redBullView)
        stackView.layoutIfNeeded()
        backgroundViewHeightConstant.constant = stackView.frame.height + 30
        backgroundView.layoutIfNeeded()
        backgroundView.addBorder(.bottom)
    }
    
    private func createN2BlackJackResultView(gameResult: CasinoGameResult.BlackjackN2, stackView: UIStackView) {
        createOneRowOfN2BlackJackResultView(pokerCards: gameResult.dealerCards, title: Localize.string("product_dealer"), stackView: stackView)
        createOneRowOfN2BlackJackResultView(pokerCards: gameResult.playerCards, title: Localize.string("product_player"), stackView: stackView)
        createOneRowOfN2BlackJackResultView(pokerCards: gameResult.splitCards, title: Localize.string("product_split"), stackView: stackView)
        stackView.layoutIfNeeded()
        backgroundViewHeightConstant.constant = stackView.frame.height + 30
        backgroundView.layoutIfNeeded()
        backgroundView.addBorder(.bottom)
    }
    
    private func createOneRowOfN2BlackJackResultView(pokerCards: [PokerCard], title: String, stackView: UIStackView) {
        guard pokerCards.count > 0 else { return }
        let row = createOneRowOfPokerCards(pokerCards: pokerCards, title: title)
        stackView.addArrangedSubview(row)
    }
    
    private func createBullBullResultView(gameResult: CasinoGameResult.BullBull, stackView: UIStackView) {
        if let firstCard = gameResult.firstCard {
            let firstCardView = createOneRowOfPokerCards(pokerCards: [firstCard], title: Localize.string("product_first_card"))
            stackView.addArrangedSubview(firstCardView)
        }
        
        let bankerCardView = createOneRowOfPokerCards(pokerCards: gameResult.bankerCards, title: Localize.string("product_banker_title"))
        let playerFirstCardView = createOneRowOfPokerCards(pokerCards: gameResult.playerFirstCards, title: Localize.string("product_player_1_title"))
        let playerSecondCardView = createOneRowOfPokerCards(pokerCards: gameResult.playerSecondCards, title: Localize.string("product_player_2_title"))
        let playerThirdCardView = createOneRowOfPokerCards(pokerCards: gameResult.playerThirdCards, title: Localize.string("product_player_3_title"))
        stackView.addArrangedSubview(bankerCardView)
        stackView.addArrangedSubview(playerFirstCardView)
        stackView.addArrangedSubview(playerSecondCardView)
        stackView.addArrangedSubview(playerThirdCardView)
        stackView.layoutIfNeeded()
        backgroundViewHeightConstant.constant = stackView.frame.height + 30
        backgroundView.layoutIfNeeded()
        backgroundView.addBorder(.bottom, size: 1, color: UIColor.dividerCapeCodGray2)
    }
    
    private func createRouletteResultView(gameResult: CasinoGameResult.Roulette) {
        let squareView = UIView()
        self.backgroundView.addSubview(squareView)
        let width: CGFloat = 40
        squareView.translatesAutoresizingMaskIntoConstraints = false
        squareView.heightAnchor.constraint(equalToConstant: width).isActive = true
        squareView.widthAnchor.constraint(equalToConstant: width).isActive = true
        squareView.centerXAnchor.constraint(equalTo: self.backgroundView.centerXAnchor).isActive = true
        squareView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 0).isActive = true
        squareView.backgroundColor = UIColor.red
        squareView.cornerRadius = width / 2
        
        let numberLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 22, height: 24))
        squareView.addSubview(numberLabel)
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.centerXAnchor.constraint(equalTo: squareView.centerXAnchor).isActive = true
        numberLabel.centerYAnchor.constraint(equalTo: squareView.centerYAnchor).isActive = true
        numberLabel.text = String(gameResult.result)
        numberLabel.font = UIFont(name: "PingFangTC-Semibold", size: 18)
        numberLabel.textColor = UIColor.whiteFull
        numberLabel.textAlignment = .center
        backgroundViewHeightConstant.constant = 60
        backgroundView.layoutIfNeeded()
        backgroundView.addBorder(.bottom)
    }
    
    private func createSicboResultView(gameResult: CasinoGameResult.Sicbo) {
        let stackView = UIStackView()
        self.backgroundView.addSubview(stackView)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 24
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.centerXAnchor.constraint(equalTo: self.backgroundView.centerXAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 0).isActive = true
        
        for diceNumber in gameResult.diceNumbers {
            if let image = setDiceNumber(diceNumber: diceNumber) {
                stackView.addArrangedSubview(UIImageView(image:image))
            }
        }
        
        backgroundViewHeightConstant.constant = 60
        backgroundView.layoutIfNeeded()
        backgroundView.addBorder(.bottom)
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
        if pokerCardSuit == PokerSuits.diamond ||  pokerCardSuit == PokerSuits.heart {
            numberLabel.textColor = UIColor.redForDarkFull
        } else {
            numberLabel.textColor = UIColor.black_two
        }
        
        
        let img = UIImageView(frame: CGRect(x: 0, y: numberLabel.frame.height + numberLabel.frame.origin.y, width: 18, height: 18))
        img.image = setPokerCardSuit(pokerCardSuit: pokerCardSuit)
        img.center.x = numberLabel.center.x
        squareView.addSubview(img)
        return squareView
    }
    
    private func createOneRowOfPokerCards(pokerCards: [PokerCard], title: String) -> UIView {
        let rowNumber = Int(ceil(Double(pokerCards.count / 7))) + 1
        let oneRowCardNumber = 7
        let spacing: CGFloat = 10
        let totalSpacing = CGFloat(rowNumber) * spacing
        let textHeight = CGFloat(20)
        let totalCardHeight = CGFloat(54 * rowNumber)
        let totalRowHeight = totalSpacing + textHeight + totalCardHeight
        let backgroundView = UIView()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.heightAnchor.constraint(equalToConstant:totalRowHeight).isActive = true
        backgroundView.widthAnchor.constraint(equalToConstant: self.view.frame.width).isActive = true
        
        let vStackView = UIStackView()
        backgroundView.addSubview(vStackView)
        vStackView.axis = .vertical
        vStackView.distribution = .fillEqually
        vStackView.alignment = .fill
        vStackView.spacing = spacing
        vStackView.translatesAutoresizingMaskIntoConstraints = false
        vStackView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 0).isActive = true
        vStackView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: 0).isActive = true
        
        var firstIndex = 0
        for index in 1...rowNumber {
            let lastIndex = index * oneRowCardNumber > pokerCards.count ? pokerCards.count : index * oneRowCardNumber
            let stackView = UIStackView()
            vStackView.addArrangedSubview(stackView)
            stackView.axis = .horizontal
            stackView.distribution = .fillEqually
            stackView.alignment = .fill
            stackView.spacing = 8
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.heightAnchor.constraint(equalToConstant: 54).isActive = true
            pokerCards[firstIndex..<lastIndex].forEach{ stackView.addArrangedSubview(addPokerCard(pokerCardNumber: setPokerNumber(pokerNumber: $0.pokerNumber), pokerCardSuit: $0.pokerSuits)) }
            let remainEmptyView = oneRowCardNumber - stackView.arrangedSubviews.count
            for _ in 0..<remainEmptyView {
                stackView.addArrangedSubview(UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 54)))
            }
            
            firstIndex = lastIndex
        }
        
        let titleLabel = UILabel()
        backgroundView.addSubview(titleLabel)
        titleLabel.textColor = UIColor.whiteFull
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leftAnchor.constraint(equalTo: vStackView.leftAnchor, constant: 0).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: vStackView.topAnchor, constant: -7).isActive = true
        titleLabel.text = title
        
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


extension CasinoDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.recordDetail == nil ? 0 : 6
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let detail = recordDetail else { return 0 }
        if indexPath.row == 0 || (indexPath.row == 4 && detail.prededuct != AccountCurrency.zero()) {
            return 90
        } else {
            return 70
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let detail = recordDetail else { return UITableViewCell() }
        if indexPath.row == 0 || (detail.prededuct != AccountCurrency.zero() && indexPath.row == 4) {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "CasinoDetailRecord3Cell", for: indexPath) as? CasinoDetailRecord3TableViewCell {
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
                    cell.otherBetIdLabel.textColor = UIColor.whiteFull
                }
                
                if indexPath.row != 0 {
                    cell.addBorder()
                }
                
                return cell
            }
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "CasinoDetailRecord2Cell", for: indexPath) as? CasinoDetailRecord2TableViewCell {
                cell.setup(index: indexPath.row, detail: detail)
                if indexPath.row != 0 {
                    cell.addBorder()
                }
                if indexPath.row == 5 {
                    cell.addBorder(.bottom)
                }
                
                return cell
            }
        }
        
        return UITableViewCell()
    }
}


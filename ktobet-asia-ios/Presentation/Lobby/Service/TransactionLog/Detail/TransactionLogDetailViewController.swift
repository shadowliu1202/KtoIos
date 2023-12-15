import RxCocoa
import RxSwift
import sharedbu
import UIKit

struct LogDetail {
  var title: String
  var transactionId: String
  var isSmartBet = false
}

class TransactionLogDetailViewController: LobbyViewController {
  @IBOutlet weak var tableView: UITableView!
  
  @Injected private var viewModel: TransactionLogViewModel
  
  private let disposeBag = DisposeBag()

  private var resultViewHeight: CGFloat = 0
  private lazy var flowController = TransactionFlowController(self, disposeBag: disposeBag)
  
  var param: LogDetail?
  var detailItem: LogDetailRowItem? {
    didSet {
      self.tableView.reloadData()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
    initUI()
    bindData()
  }

  private func initUI() {
    tableView.estimatedRowHeight = 81.0
    tableView.rowHeight = UITableView.automaticDimension
    tableView.dataSource = self
    tableView.setHeaderFooterDivider()
    setHeaderView()
    tableView.tableFooterView?.frame.size.height += resultViewHeight
    flowController.delegate = self
  }

  private func setHeaderView() {
    let headerView = UIView(frame: .zero)
    headerView.backgroundColor = UIColor.clear
    tableView.tableHeaderView?.addSubview(headerView, constraints: [
      .constraint(.equal, \.trailingAnchor, offset: -30),
      .constraint(.equal, \.leadingAnchor, offset: 30),
      .constraint(.equal, \.topAnchor, offset: 0),
      .constraint(.equal, \.bottomAnchor, offset: 0)
    ])

    let naviLabel = UILabel()
    naviLabel.textAlignment = .left
    naviLabel.font = UIFont(name: "PingFangSC-Semibold", size: 24)
    naviLabel.textColor = UIColor.greyScaleWhite
    naviLabel.text = Localize.string("common_transaction")

    let titleLabel = UILabel()
    titleLabel.textAlignment = .left
    titleLabel.font = UIFont(name: "PingFangSC-Medium", size: 16)
    titleLabel.textColor = UIColor.greyScaleWhite
    titleLabel.text = param?.title
    titleLabel.numberOfLines = 0
    titleLabel.setContentHuggingPriority(.required, for: .vertical)
    titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

    let vStackView = UIStackView()
    headerView.addSubview(vStackView, constraints: [
      .constraint(.equal, \.trailingAnchor, offset: 0),
      .constraint(.equal, \.leadingAnchor, offset: 0),
      .constraint(.equal, \.topAnchor, offset: 30),
      .constraint(.equal, \.bottomAnchor, offset: -16)
    ])
    vStackView.axis = .vertical
    vStackView.distribution = .fill
    vStackView.alignment = .fill
    vStackView.spacing = 30
    vStackView.translatesAutoresizingMaskIntoConstraints = false
    vStackView.addArrangedSubview(naviLabel)
    vStackView.addArrangedSubview(titleLabel)
    tableView.layoutTableHeaderView()
  }

  private func bindData() {
    guard let param else { return }
    viewModel.getTransactionLogDetail(transactionId: param.transactionId)
      .subscribe(onSuccess: { [weak self] result in
        guard let self, let param = self.param else { return }
        self.detailItem = LogDetailRowItem(bean: result, isSmartBet: param.isSmartBet)
      })
      .disposed(by: disposeBag)

    viewModel.errors()
      .subscribe(onNext: { [weak self] in
        self?.handleErrors($0)
      })
      .disposed(by: disposeBag)
  }
}

extension TransactionLogDetailViewController: UITableViewDataSource {
  func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    detailItem == nil ? 0 : 5
  }

  func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let item = detailItem else {
      return UITableViewCell()
    }

    let cell = self.tableView.dequeueReusableCell(withIdentifier: "LogDetailCell", cellType: LogDetailCell.self)
      .configure(index: indexPath.row, data: item) { [unowned self] _, wagerID in
        guard let detailItem else { return }
        
        switch detailItem.bean.productType {
        case .casino:
          flowController.goCasinoDetail(wagerID)
        case .p2p:
          flowController.goP2PDetail(wagerID)
        default:
          break
        }
      }

    cell.removeBorder()
    if indexPath.row != 0 {
      cell.addBorder(rightConstant: 30, leftConstant: 30)
    }

    return cell
  }
}

// MARK: - TransactionFlowDelegate

extension TransactionLogDetailViewController: TransactionFlowDelegate {
  func getIsCasinoWagerDetailExist(by wagerID: String) async -> Bool? {
    do {
      return try await viewModel.getIsCasinoWagerDetailExist(by: wagerID)
    }
    catch {
      handleErrors(error)
      return nil
    }
  }
  
  func getIsP2PWagerDetailExist(by wagerID: String) async -> Bool? {
    do {
      return try await viewModel.getIsP2PWagerDetailExist(by: wagerID)
    }
    catch {
      handleErrors(error)
      return nil
    }
  }
  
  func displaySportsBookDetail(wagerId: String) {
    viewModel
      .getSportsBookWagerDetail(wagerId: wagerId)
      .subscribe(onSuccess: { [weak self] html in
        let controller = TransactionHtmlViewController.initFrom(storyboard: "TransactionLog")
        controller.html = html
        self?.navigationController?.pushViewController(controller, animated: true)
      })
      .disposed(by: disposeBag)
  }
}

class LogDetailCell: UITableViewCell, UITextViewDelegate {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var stackView: UIStackView!
  private var callback: ((_ displayID: String, _ wagerID: String) -> Void)?

  func configure(
    index: Int,
    data: LogDetailRowItem,
    callback: ((_ displayID: String, _ wagerID: String) -> Void)?)
    -> Self
  {
    if index == 0 {
      setTilte("balancelog_detail_amount")
      setValue(data.balancelogAmount)
      descriptionLabel.textColor = data.amountColor
    }
    else if index == 1 {
      setTilte("balancelog_detail_after_amount")
      setValue(data.balancelogAfterAmount)
    }
    else if index == 2 {
      setTilte("balancelog_detail_datetime")
      setValue(data.dateTime)
    }
    else if index == 3 {
      setTilte("balancelog_detail_id")
      setValue(data.logId)
    }
    else if index == 4 {
      setTilte("common_remark")
      setValue(data.remark)
      
      if let links = data.linkRemark {
        self.callback = callback
        links.forEach { configureLink($0) }
      }
      else if let vvipCashback = data.vvipCashback {
        descriptionLabel.isHidden = true

        let data = cashbackRemark(vvipCashback)
        data.forEach {
          let row = ListRow(rowConfig: $0)
          stackView.addArrangedSubview(row)
        }

        let foot = UIView()
        foot.snp.makeConstraints { make in
          make.height.equalTo(44)
        }
        stackView.addArrangedSubview(foot)
      }
    }
    return self
  }

  private func setTilte(_ key: String) {
    titleLabel.text = Localize.string(key)
  }

  private func setValue(_ txt: String?) {
    descriptionLabel.text = txt ?? " "
  }
  
  private func configureLink(_ remark: (String?, String?)) {
    guard
      let displayID = remark.0,
      let wagerID = remark.1
    else { return }
    
    let textView = TappableTextView(frame: .zero)
    let attributedText = NSAttributedString(text: displayID)
      .color(.systemRed)
      .underline(.single, color: .systemRed)
    textView.attributedText = attributedText
    textView.font = UIFont(name: "PingFangSC-Regular", size: 16)
    textView.backgroundColor = .clear
    textView.textAlignment = .left
    textView.isSelectable = false
    textView.isEditable = false
    textView.isScrollEnabled = false
    textView.textContainerInset = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 0)
    textView.tapAction = { [unowned self] in
      callback?(displayID, wagerID)
    }
    
    stackView.addArrangedSubview(textView)
  }
  
  private func cashbackRemark(_ vvipCashback: BalanceLogDetailRemark.CashBack) -> [ListRow.RowConfig] {
    [
      ListRow.RowConfig(title: Localize.string("bonus_cashback_remark_title"), content: vvipCashback.title),
      ListRow.RowConfig(
        title: Localize.string("bonus_cashback_remark_subtitle", "\(vvipCashback.issueNumber.month)"),
        content: nil),
      ListRow.RowConfig(title: Localize.string("common_sportsbook"), content: vvipCashback.sbk.formatString(sign: .signed_)),
      ListRow.RowConfig(title: Localize.string("common_casino"), content: vvipCashback.casino.formatString(sign: .signed_)),
      ListRow.RowConfig(title: Localize.string("common_slot"), content: vvipCashback.slot.formatString(sign: .signed_)),
      ListRow.RowConfig(title: Localize.string("common_keno"), content: vvipCashback.numberGame.formatString(sign: .signed_)),
      ListRow.RowConfig(title: Localize.string("common_arcade"), content: vvipCashback.arcade.formatString(sign: .signed_)),
      ListRow.RowConfig(
        title: Localize.string("common_total_amount"),
        content: vvipCashback.totalWinLoss.formatString(sign: .signed_)),
      ListRow.RowConfig(
        title: Localize.string("bonus_cashback_remark_total_bonus", "\(vvipCashback.issueNumber.month)"),
        content: vvipCashback.totalBonusAmount.formatString(sign: .signed_)),
      ListRow.RowConfig(
        title: Localize.string("bonus_cashback_remark_percentage"),
        content: "\(vvipCashback.percent.description())%"),
      ListRow.RowConfig(
        title: Localize.string("bonus_cashback_remark_formula"),
        content: Localize.string("bonus_cashback_remark_formula_content", "\(vvipCashback.percent.description())"))
    ]
  }

  func textViewDidChangeSelection(_ textView: UITextView) {
    textView.selectedTextRange = nil
  }
}

extension LogDetailCell {
  class ListRow: UIView {
    struct RowConfig {
      let title: String
      let content: String?
    }

    let field1Label = UILabel()
    let field2Label = UILabel()

    private lazy var labels = [field1Label, field2Label]

    init(rowConfig: RowConfig) {
      super.init(frame: .zero)
      setupUI()
      config(rowConfig)
    }

    override init(frame: CGRect) {
      super.init(frame: frame)
      setupUI()
    }

    required init?(coder: NSCoder) {
      super.init(coder: coder)
      setupUI()
    }

    private func setupUI() {
      let hstack = UIStackView(
        arrangedSubviews: labels,
        spacing: 5,
        axis: .horizontal,
        distribution: .fill,
        alignment: .fill)

      field1Label.textAlignment = .left
      field2Label.textAlignment = .right

      labels.forEach({
        $0.font = UIFont(name: "PingFangSC-Regular", size: 16)!
        $0.numberOfLines = 0
      })

      addSubview(hstack)
      hstack.snp.makeConstraints { make in
        make.edges.equalToSuperview().inset(UIEdgeInsets(top: 1, left: 0, bottom: 1, right: 0))
      }

      field1Label.setContentHuggingPriority(.required, for: .horizontal)
      field2Label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    private func config(_ rowConfig: RowConfig) {
      field1Label.text = rowConfig.title
      field2Label.text = rowConfig.content
      field2Label.isHidden = rowConfig.content?.isEmpty ?? true
      labels.forEach({ $0.textColor = .white })
    }
  }
}

class LogDetailRowItem {
  private(set) var bean: BalanceLogDetail!
  private(set) var isSmartBet: Bool!
  var balancelogAmount: String { bean.amount.formatString(sign: .signed_) }
  var amountColor: UIColor {
    bean.amount.isPositive ? .statusSuccess : .greyScaleWhite
  }

  var balancelogAfterAmount: String {
    bean.afterBalance.formatString()
  }

  var dateTime: String { bean.date.toDateTimeFormatString() }
  var logId: String?
  var remark: String?
  var linkRemark: [(String?, String?)]?
  var vvipCashback: BalanceLogDetailRemark.CashBack?

  init(bean: BalanceLogDetail, isSmartBet: Bool) {
    self.bean = bean
    self.isSmartBet = isSmartBet
    configureLogIdRemark()
  }

  private func configureLogIdRemark() {
    switch bean.transactionType {
    case let type as TransactionTypes.Product:
      consider(type, bean.productGroup)
    case is TransactionTypes.Adjustment:
      self.logId = bean.wagerMappingId
      self.remark = ""
    case is TransactionTypes.Bonus,
         is TransactionTypes.DepositFeeRefund:
      consider(bean.remark)
    default:
      break
    }
  }

  private func consider(_ type: TransactionTypes.Product, _ group: ProductGroup) {
    switch group {
    case is ProductGroup.P2P:
      let status = getBetStatus(type)
      self.logId = bean.productGroup.supportProvider.provider == Provider.Support.v8 ? bean.wagerMappingId : ""
      
      switch bean.remark {
      case let remark as BalanceLogDetailRemark.TransferWallet:
        if remark.isDetailActive {
          self.linkRemark = remark.ids.map({ ($0.first as String?, $0.second as String?) })
          self.remark = status
        }
        else {
          let remarkStr = bean.productGroup.supportProvider.provider == Provider.Support.gpi ? bean.externalId : bean
            .wagerMappingId
          self.remark = status.isEmpty ? remarkStr : "\(status)\n\(remarkStr)"
        }
        
      case is BalanceLogDetailRemark.Bonus,
           is BalanceLogDetailRemark.CashBack,
           is BalanceLogDetailRemark.General,
           is BalanceLogDetailRemark.None:
        let remarkStr = bean.productGroup.supportProvider.provider == Provider.Support.gpi ? bean.externalId : bean
          .wagerMappingId
        self.remark = status.isEmpty ? remarkStr : "\(status)\n\(remarkStr)"
      default: break
      }
      
    case is ProductGroup.Arcade,
         is ProductGroup.NumberGame,
         is ProductGroup.Slot: if let remark = bean.remark as? BalanceLogDetailRemark.General
      {
        if remark.ids.count > 1 {
          self.logId = bean.wagerMappingId
          self.remark = "\(getBetStatus(type))\n\(displayRemarks(remark.ids))"
        }
        else {
          self.logId = remark.ids.first?.first as String?
          self.remark = "\(getBetStatus(type))\n\(bean.wagerMappingId)"
        }
      }
      else {
        self.logId = bean.wagerMappingId
        self.remark = "\(getBetStatus(type))\n\(bean.wagerMappingId)"
      }
    case is ProductGroup.Casino:
      var remarks: [String] = []
      let status = getBetStatus(type)
      if !status.isEmpty {
        remarks.append(status)
      }
      switch bean.remark {
      case let r as BalanceLogDetailRemark.General:
        remarks.append(r.lobbyName)
        logId = r.ids.count > 1 ? bean.wagerMappingId : r.ids.first?.first as String?
        
        if isSmartBet {
          linkRemark = r.ids.map({ ($0.first as String?, $0.second as String?) })
        }
        else {
          let remarkStr = r.ids.count > 1 ? displayRemarks(r.ids) : bean.wagerMappingId
          remarks.append(remarkStr)
        }
      case let remark as BalanceLogDetailRemark.TransferWallet:
        remarks.append(remark.lobbyName)
        logId = remark.ids.count > 1 ? bean.wagerMappingId : remark.ids.first?.first as String?
        
        if remark.isDetailActive {
          self.linkRemark = remark.ids.map({ ($0.first as String?, $0.second as String?) })
        }
        else {
          let remarkStr = remark.ids.count > 1 ? displayRemarks(remark.ids) : bean.wagerMappingId
          remarks.append(remarkStr)
        }
        
      case is BalanceLogDetailRemark.Bonus,
           is BalanceLogDetailRemark.None:
        let remarkStr = bean.productGroup.supportProvider.provider == Provider.Support.gpi ? bean.externalId : bean
          .wagerMappingId
        remarks.append(remarkStr)
      default:
        break
      }
      self.remark = remarks.joined(separator: "\n")
    default:
      break
    }
  }

  private func getBetStatus(_ transactionType: TransactionTypes.Product) -> String {
    if isReturn(bean, transactionType) {
      return Localize.string("balancelog_settle")
    }
    switch transactionType {
    case .ProductBet():
      if let remark = bean.remark as? BalanceLogDetailRemark.General, remark.betStatus == BetStatus_.reject {
        return Localize.string("common_reject")
      }
      else {
        return Localize.string("common_bet")
      }
    case .ProductWin():
      return Localize.string("balancelog_settle")
    case .ProductVoid():
      return Localize.string("common_reject")
    case .ProductPlayerCancel():
      return Localize.string("balancelog_player_cancel")
    case .ProductUnSettle():
      return Localize.string("balancelog_unsettled")
    case .ProductCancel():
      return Localize.string("common_cancel")
    case .ProductRevise():
      return Localize.string("balancelog_settle")
    case .ProductEnterTable():
      return Localize.string("product_enter_table")
    case .ProductLeaveTable():
      return Localize.string("product_leave_table")
    default:
      return ""
    }
  }

  private func isReturn(_ balanceLogDetail: BalanceLogDetail, _ transactionType: TransactionTypes.Product) -> Bool {
    let excludeStatus: [TransactionTypes.Product] = [.ProductEnterTable(), .ProductLeaveTable()]
    let isInclude = excludeStatus.contains { $0 == transactionType }
    return balanceLogDetail.amount.isPositive && !isInclude
  }

  private func displayRemarks(_ ids: [KotlinPair<NSString, NSString>]) -> String {
    ids.filter({ $0.first != nil }).map({ $0.first! as String }).joined(separator: "\n")
  }

  private func consider(_ remark: BalanceLogDetailRemark) {
    switch remark {
    case let r as BalanceLogDetailRemark.Bonus:
      self.logId = r.bonusId
      self
        .remark = parse(bonusType: r.bonusType) + ":" +
        parseProductBonusSubTitle(
          bonusType: r.bonusType,
          productType: r.productType,
          issueNumber: r.issueNumber,
          defaultTitle: r.bonusName)
    case let r as BalanceLogDetailRemark.CashBack:
      self.logId = r.bonusId
      self.remark = nil
      self.vvipCashback = r
    case is BalanceLogDetailRemark.None:
      self.logId = bean.wagerMappingId
      self.remark = Localize.string("balancelog_deposit_refund")
    default:
      break
    }
  }

  private func parse(bonusType: BonusType) -> String {
    var str = ""
    switch bonusType {
    case .freebet:
      str = Localize.string("bonus_bonustype_1")
    case .depositbonus:
      str = Localize.string("bonus_bonustype_2")
    case .product:
      str = Localize.string("bonus_bonustype_3")
    case .rebate:
      str = Localize.string("bonus_bonustype_4")
    case .levelbonus:
      str = Localize.string("bonus_bonustype_5")
    default:
      break
    }
    return str
  }

  private func parseProductBonusSubTitle(
    bonusType: BonusType,
    productType: ProductType,
    issueNumber: Int32,
    defaultTitle: String)
    -> String
  {
    var str = ""
    switch productType {
    case .sbk:
      switch bonusType {
      case .product:
        str = Localize.string("balancelog_producttype_1_bonustype_3", "\(issueNumber)")
      case .rebate:
        str = Localize.string("balancelog_producttype_1_bonustype_4", "\(issueNumber)")
      default:
        break
      }
    case .slot:
      switch bonusType {
      case .product:
        str = Localize.string("balancelog_producttype_2_bonustype_3", "\(issueNumber)")
      case .rebate:
        str = Localize.string("balancelog_producttype_2_bonustype_4", "\(issueNumber)")
      default:
        break
      }
    case .casino:
      if bonusType == .rebate {
        str = Localize.string("balancelog_producttype_3_bonustype_4", "\(issueNumber)")
      }
    case .numbergame:
      if bonusType == .rebate {
        str = Localize.string("balancelog_producttype_4_bonustype_4", "\(issueNumber)")
      }
    default:
      str = defaultTitle
    }
    return str
  }
}

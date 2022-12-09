import UIKit
import RxSwift
import RxCocoa
import SharedBu

struct LogDetail {
    var title: String
    var transactionId: String
    var isSmartBet: Bool = false
}
class TransactionLogDetailViewController: LobbyViewController {
    var param: LogDetail?
    var detailItem: LogDetailRowItem? {
        didSet {
            self.tableView.reloadData()
        }
    }
    private var resultViewHeight: CGFloat = 0
    @IBOutlet weak var tableView: UITableView!
    let disposeBag = DisposeBag()
    let viewModel = Injectable.resolve(TransactionLogViewModel.self)!
    private lazy var flow = TranscationFlowController(self, disposeBag: disposeBag)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        initUI()
        bindData()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    private func initUI() {
        tableView.estimatedRowHeight = 81.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.setHeaderFooterDivider()
        setHeaderView()
        tableView.tableFooterView?.frame.size.height += resultViewHeight
    }
    
    private func setHeaderView() {
        let headerView = UIView(frame: .zero)
        headerView.backgroundColor = UIColor.clear
        tableView.tableHeaderView?.addSubview(headerView, constraints: [
            .constraint(.equal, \.trailingAnchor, offset: -30),
            .constraint(.equal, \.leadingAnchor, offset: 30),
            .constraint(.equal, \.topAnchor, offset: 0),
            .constraint(.equal, \.bottomAnchor, offset: 0)])
        
        let naviLabel = UILabel()
        naviLabel.textAlignment = .left
        naviLabel.font = UIFont.init(name: "PingFangSC-Semibold", size: 24)
        naviLabel.textColor = UIColor.whitePure
        naviLabel.text = Localize.string("common_transaction")
        
        let titleLabel = UILabel()
        titleLabel.textAlignment = .left
        titleLabel.font = UIFont.init(name: "PingFangSC-Medium", size: 16)
        titleLabel.textColor = UIColor.whitePure
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
        guard let param = param else { return }
        viewModel.getTransactionLogDetail(transactionId: param.transactionId).subscribe(onSuccess: { [weak self] (result) in
            guard let `self` = self, let param = self.param else { return }
            self.detailItem = LogDetailRowItem(bean: result, isSmartBet: param.isSmartBet)
        }, onError: { [weak self] in
            self?.handleErrors($0)
        }).disposed(by: disposeBag)
    }
    
    private func goToCasinoDetail(_ wagerId: String) {
        self.flow.goNext(wagerId)
    }

}

extension TransactionLogDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return detailItem == nil ? 0 : 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = detailItem else {
            return UITableViewCell()
        }
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "LogDetailCell", cellType: LogDetailCell.self)
            .configure(index: indexPath.row, data: item) { [weak self] (externalId) in
                self?.goToCasinoDetail(externalId)
            }
        
        cell.removeBorder()
        if indexPath.row != 0 {
            cell.addBorder(rightConstant: 30, leftConstant: 30)
        }
        
        return cell
    }
}

class LogDetailCell: UITableViewCell, UITextViewDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    private var callback: ((String) -> ())?
    
    func configure(index: Int, data: LogDetailRowItem, callback: ((String)->())?) -> Self {
        if index == 0 {
            setTilte("balancelog_detail_amount")
            setValue(data.balancelogAmount)
            descriptionLabel.textColor = data.amountColor
        } else if index == 1 {
            setTilte("balancelog_detail_after_amount")
            setValue(data.balancelogAfterAmount)
        } else if index == 2 {
            setTilte("balancelog_detail_datetime")
            setValue(data.dateTime)
        } else if index == 3 {
            setTilte("balancelog_detail_id")
            setValue(data.logId)
        } else if index == 4 {
            setTilte("common_remark")
            setValue(data.remark)
            if let links = data.linkRemark {
                self.callback = callback
                links.forEach({ (remark) in
                    let (first, second) = remark
                    guard let displayId = first, let wagerId = second  else {return}
                    let textView = UITextView(frame: .zero)
                    textView.textColor = .systemRed
                    textView.backgroundColor = .clear
                    textView.textAlignment = .left
                    textView.isSelectable = true
                    textView.isEditable = false
                    textView.isScrollEnabled = false
                    textView.textContainerInset = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 0)
                    var txt = AttribTextHolder(text: displayId)
                        .addAttr((text: displayId, type: .color, UIColor.whitePure))
                        .addAttr((text: displayId, type: .font, UIFont.init(name: "PingFangSC-Regular", size: 16) as Any))
                    if displayId.isValidRegex(format: .numbers) {
                        txt = txt
                            .addAttr((text: displayId, type: .link(true), "Casino://\(wagerId)"))
                            .addAttr((text: displayId, type: .color, UIColor.systemRed))
                    }
                    txt.setTo(textView: textView)
                    stackView.addArrangedSubview(textView)
                    textView.delegate = self
                })
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
    
    private func cashbackRemark(_ vvipCashback: BalanceLogDetailRemark.CashBack) -> [ListRow.RowConfig] {
        [ListRow.RowConfig(title: Localize.string("bonus_cashback_remark_title"), content: vvipCashback.title),
         ListRow.RowConfig(title: Localize.string("bonus_cashback_remark_subtitle", "\(vvipCashback.issueNumber.month)"), content: nil),
         ListRow.RowConfig(title: Localize.string("common_sportsbook"), content: vvipCashback.sbk.formatString(sign: .signed_)),
         ListRow.RowConfig(title: Localize.string("common_casino"), content: vvipCashback.casino.formatString(sign: .signed_)),
         ListRow.RowConfig(title: Localize.string("common_slot"), content: vvipCashback.slot.formatString(sign: .signed_)),
         ListRow.RowConfig(title: Localize.string("common_keno"), content: vvipCashback.numberGame.formatString(sign: .signed_)),
         ListRow.RowConfig(title: Localize.string("common_arcade"), content: vvipCashback.arcade.formatString(sign: .signed_)),
         ListRow.RowConfig(title: Localize.string("common_total_amount"), content: vvipCashback.totalWinLoss.formatString(sign: .signed_)),
         ListRow.RowConfig(title: Localize.string("bonus_cashback_remark_total_bonus", "\(vvipCashback.issueNumber.month)"), content: vvipCashback.totalBonusAmount.formatString(sign: .signed_)),
         ListRow.RowConfig(title: Localize.string("bonus_cashback_remark_percentage"), content: "\(vvipCashback.percent.description())%"),
         ListRow.RowConfig(title: Localize.string("bonus_cashback_remark_formula"), content: Localize.string("bonus_cashback_remark_formula_content", "\(vvipCashback.percent.description())"))]
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.scheme == "Casino" {
            let wagerId = String(URL.absoluteString.dropFirst("Casino://".count))
            self.callback?(wagerId)
            return false
        }
        return true
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
                alignment: .fill
            )
            
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
        return bean.amount.isPositive ? .green6AB336 : .whitePure
    }
    var balancelogAfterAmount: String {
        let sign: FormatPattern.Sign = bean.afterBalance.isNegative ? .signed_ : .none
        return bean.afterBalance.formatString(sign)
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
            break
        case is TransactionTypes.Adjustment:
            self.logId = bean.wagerMappingId
            self.remark = ""
        case is TransactionTypes.DepositFeeRefund, is TransactionTypes.Bonus:
            consider(bean.remark)
            break
        default:
            break
        }
    }
    
    private func consider(_ type: TransactionTypes.Product, _ group: ProductGroup) {
        switch group {
        case is ProductGroup.P2P:
            let status = getBetStatus(type)
            self.logId = bean.productGroup.supportProvider.provider == Provider.Support.v8 ? bean.wagerMappingId : ""
            let remarkStr = bean.productGroup.supportProvider.provider == Provider.Support.gpi ? bean.externalId : bean.wagerMappingId
            self.remark = status.isEmpty ? remarkStr : "\(status)\n\(remarkStr)"
        case is ProductGroup.Arcade, is ProductGroup.Slot, is ProductGroup.NumberGame:
            if let remark = bean.remark as? BalanceLogDetailRemark.General {
                if (remark.ids.count > 1) {
                    self.logId = bean.wagerMappingId
                    self.remark = "\(getBetStatus(type))\n\(displayRemarks(remark.ids))"
                } else {
                    self.logId = remark.ids.first?.first as String?
                    self.remark = "\(getBetStatus(type))\n\(bean.wagerMappingId)"
                }
            } else {
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
                if self.isSmartBet {
                    self.linkRemark = r.ids.map({($0.first as String?, $0.second as String?)})
                } else {
                    let remarkStr = r.ids.count > 1 ? displayRemarks(r.ids) : bean.wagerMappingId
                    remarks.append(remarkStr)
                }
                self.logId = r.ids.count > 1 ? bean.wagerMappingId : r.ids.first?.first as String?
            case is BalanceLogDetailRemark.Bonus, is BalanceLogDetailRemark.None:
                let remarkStr = bean.productGroup.supportProvider.provider == Provider.Support.gpi ? bean.externalId : bean.wagerMappingId
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
        if bean.amount.isPositive {
            return Localize.string("balancelog_settle")
        }
        switch transactionType {
        case .ProductBet():
            if let remark = bean.remark as? BalanceLogDetailRemark.General, remark.betStatus == BetStatus_.reject {
                return Localize.string("common_reject")
            } else {
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
        default:
            return ""
        }
    }
    
    private func displayRemarks(_ ids: [KotlinPair<NSString, NSString>]) -> String {
        return ids.filter({$0.first != nil}).map({$0.first! as String}).joined(separator: "\n")
    }
    
    private func consider(_ remark: BalanceLogDetailRemark) {
        switch remark {
        case let r as BalanceLogDetailRemark.Bonus:
            self.logId = r.bonusId
            self.remark = parse(bonusType: r.bonusType) + ":" + parseProductBonusSubTitle(bonusType: r.bonusType, productType: r.productType, issueNumber: r.issueNumber, defaultTitle: r.bonusName)
            break
        case let r as BalanceLogDetailRemark.CashBack:
            self.logId = r.bonusId
            self.remark = nil
            self.vvipCashback = r
            break
        case is BalanceLogDetailRemark.None:
            self.logId = bean.wagerMappingId
            self.remark = Localize.string("balancelog_deposit_refund")
            break
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
    
    private func parseProductBonusSubTitle(bonusType: BonusType, productType: ProductType, issueNumber: Int32, defaultTitle: String) -> String {
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
            break
        }
        return str
    }
}

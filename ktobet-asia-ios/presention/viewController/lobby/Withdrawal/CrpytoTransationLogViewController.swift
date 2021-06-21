import UIKit
import RxSwift
import SharedBu

class CrpytoTransationLogViewController: UIViewController {
    static let segueIdentifier = "toCrpytoTransationLog"
    var crpytoWithdrawalRequirementAmount: Double?
    
    @IBOutlet weak var requirementTextView: UITextView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scrollViewContentHeight: NSLayoutConstraint!
    private var dataSource = [[CryptoWithdrawalLimitTicketDetail]](repeating: [], count: 2)
    private var totalRequestAmount: Double = 0
    private var totalAchievedAmount: Double = 0
    fileprivate var viewModel = DI.resolve(WithdrawalViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self)
        initUI()
        dataBinding()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    private func initUI() {
        let amount = (crpytoWithdrawalRequirementAmount != nil) ? displayAmount(crpytoWithdrawalRequirementAmount!) : ""
        setRequirementText(amount)
        requirementTextView.textContainerInset = .zero
        tableView.delegate = self
        tableView.dataSource = self
        tableView.alwaysBounceVertical = false
        tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
    
    private func setRequirementText(_ txt: String) {
        let requirementTxt = Localize.string("cps_remaining_requirement", txt)
        let surfixTxt = "\(txt) ETH"
        let txt = AttribTextHolder(text: requirementTxt)
            .addAttr((text: requirementTxt, type: .color, UIColor.textPrimaryDustyGray))
            .addAttr((text: surfixTxt, type: .color, UIColor.alert))
        
        txt.setTo(textView: requirementTextView)
    }
    
    private func dataBinding() {
        viewModel.cryptoLimitTransactions().subscribe(onSuccess: { [weak self] (model: CryptoWithdrawalLimitLog) in
            self?.totalRequestAmount = model.totalRequestAmount.cryptoAmount
            self?.dataSource[0] = model.requestTicketDetails
            self?.totalAchievedAmount = model.totalAchievedAmount.cryptoAmount
            self?.dataSource[1] = model.achievedTicketDetails
            self?.tableView.reloadData()
        }, onError: {
            print($0)
        }).disposed(by: disposeBag)
    }
    
    // MARK: KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize", let newvalue = change?[.newKey] {
            if let obj = object as? UITableView , obj == tableView {
                let topSpace: CGFloat = 140
                let bottomPadding: CGFloat = 96
                scrollViewContentHeight.constant = (newvalue as! CGSize).height + topSpace + bottomPadding
            }
        }
    }
}

fileprivate func displayAmount(_ amount: Double) -> String {
    return String(format: "%.8f", amount)
}

extension CrpytoTransationLogViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 48
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var title = ""
        switch section {
        case 0:
            title = Localize.string("cps_total_require_amount", displayAmount(totalRequestAmount))
        case 1:
            title = Localize.string("cps_total_completed_amount", displayAmount(totalAchievedAmount))
        default: break
        }
        return tableView.dequeueReusableCell(withIdentifier: "HeaderCell", cellType: HeaderCell.self).configure(title)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRect.init(x: 0, y: 0, width: 0, height: 30))
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = dataSource[indexPath.section][indexPath.row]
        return tableView.dequeueReusableCell(withIdentifier: "TicketDetailCell", cellType: TicketDetailCell.self).configure(item, isPositive: indexPath.section == 0 ? true : false, localCurrency: viewModel.localCurrency)
    }
    
}

class HeaderCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    
    func configure(_ title: String) -> Self {
        titleLabel.text = title
        return self
    }
}

class TicketDetailCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var fiatAmountLabel: UILabel!
    @IBOutlet weak var cryptoAmountLabel: UILabel!
    
    func configure(_ item: CryptoWithdrawalLimitTicketDetail, isPositive: Bool, localCurrency: String) -> Self {
        dateLabel.text = item.approvedDate.formatDateToStringToSecond()
        idLabel.text = item.displayId
        fiatAmountLabel.text = (isPositive ? "+" : "-") + String(format: "%.2f \(localCurrency)", item.fiatAmount.amount)
        cryptoAmountLabel.text =  displayAmount(item.cryptoAmount.cryptoAmount)+" ETH"
        
        return self
    }
    
}


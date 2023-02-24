import RxSwift
import SharedBu
import UIKit

class CrpytoTransationLogViewController: LobbyViewController {
  static let segueIdentifier = "toCrpytoTransationLog"
  var crpytoWithdrawalRequirementAmount: AccountCurrency?

  @IBOutlet weak var requirementTextView: UITextView!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var scrollViewContentHeight: NSLayoutConstraint!
  private var dataSource = [[CpsWithdrawalSummary.TurnOverDetail]](repeating: [], count: 2)
  private var totalRequestAmount = ""
  private var totalAchievedAmount = ""
  fileprivate var viewModel = Injectable.resolve(WithdrawalViewModel.self)!
  fileprivate var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
    initUI()
    dataBinding()
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func initUI() {
    if let amount = crpytoWithdrawalRequirementAmount {
      setRequirementText(amount.denomination())
    }

    requirementTextView.textContainerInset = .zero
    tableView.delegate = self
    tableView.dataSource = self
    tableView.alwaysBounceVertical = false
    tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
  }

  private func setRequirementText(_ txt: String) {
    let requirementTxt = Localize.string("cps_remaining_requirement", txt)
    let txt = AttribTextHolder(text: requirementTxt)
      .addAttr((text: requirementTxt, type: .color, UIColor.gray9B9B9B))
      .addAttr((text: txt, type: .color, UIColor.orangeFF8000))

    txt.setTo(textView: requirementTextView)
  }

  private func dataBinding() {
    viewModel.cryptoLimitTransactions().subscribe(onSuccess: { [weak self] (model: CpsWithdrawalSummary) in
      self?.totalRequestAmount = model.totalRequestAmount().denomination()
      self?.dataSource[0] = model.requestRecords()
      self?.totalAchievedAmount = model.totalAchievedAmount().denomination()
      self?.dataSource[1] = model.achievedRecords()
      self?.tableView.reloadData()
    }, onFailure: {
      print($0)
    }).disposed(by: disposeBag)
  }

  // MARK: KVO
  override func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey: Any]?,
    context _: UnsafeMutableRawPointer?)
  {
    if keyPath == "contentSize", let newvalue = change?[.newKey] {
      if let obj = object as? UITableView, obj == tableView {
        let topSpace: CGFloat = 140
        let bottomPadding: CGFloat = 96
        scrollViewContentHeight.constant = (newvalue as! CGSize).height + topSpace + bottomPadding
      }
    }
  }
}

extension CrpytoTransationLogViewController: UITableViewDataSource, UITableViewDelegate {
  func numberOfSections(in _: UITableView) -> Int {
    dataSource.count
  }

  func tableView(_: UITableView, estimatedHeightForHeaderInSection _: Int) -> CGFloat {
    48
  }

  func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
    30
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    var title = ""
    switch section {
    case 0:
      title = Localize.string("cps_total_require_amount", totalRequestAmount)
    case 1:
      title = Localize.string("cps_total_completed_amount", totalAchievedAmount)
    default: break
    }
    return tableView.dequeueReusableCell(withIdentifier: "HeaderCell", cellType: HeaderCell.self).configure(title)
  }

  func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
    UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 30))
  }

  func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
    dataSource[section].count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let item = dataSource[indexPath.section][indexPath.row]
    return tableView.dequeueReusableCell(withIdentifier: "TicketDetailCell", cellType: TicketDetailCell.self)
      .configure(item, isPositive: indexPath.section == 0 ? true : false, localCurrency: viewModel.localCurrency.simpleName)
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

  func configure(_ item: CpsWithdrawalSummary.TurnOverDetail, isPositive: Bool, localCurrency _: String) -> Self {
    dateLabel.text = item.approvedDate.toDateTimeString()
    idLabel.text = item.displayId
    fiatAmountLabel.text = (isPositive ? "+" : "-") + item.flatAmount.denomination()
    cryptoAmountLabel.text = item.cryptoAmount.description() + " \(item.cryptoAmount.simpleName)"

    return self
  }
}

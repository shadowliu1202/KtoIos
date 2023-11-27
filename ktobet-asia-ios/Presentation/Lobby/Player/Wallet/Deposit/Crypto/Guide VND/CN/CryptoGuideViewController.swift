import RxSwift
import UIKit

class CryptoGuideViewController: LobbyViewController {
  static let segueIdentifier = "toCryptoGuide"
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var tableView: UITableView!
  private var viewModel = Injectable.resolve(TermsViewModel.self)!
  private var resources: [Market] = [] {
    didSet {
      self.tableView.reloadData()
    }
  }

  let disposeBag = DisposeBag()
  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
    initUI()
    bindData()
  }

  private func initUI() {
    tableView.setDivider(dividerColor: .clear)
    tableView.estimatedRowHeight = 36.0
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedSectionHeaderHeight = 238.0
    tableView.sectionHeaderHeight = UITableView.automaticDimension
    tableView.delegate = self
    tableView.dataSource = self
  }

  private func bindData() {
    viewModel.cryptoGuidance.subscribe(onSuccess: { [weak self] g in
      self?.titleLabel.text = Localize.string("cps_crypto_currency_guide_title")
      self?.descriptionLabel.text = Localize.string("cps_crypto_guidance_description")
      self?.tableView.layoutTableHeaderView()
      self?.resources = g.map({ Market($0.title, $0.links.map({ Guide(name: $0.title, link: $0.link) })) })
    }, onFailure: { [weak self] in
      self?.handleErrors($0)
    }).disposed(by: disposeBag)
  }

  private func reloadRows(at sectionIndex: Int, rowCount: Int, with animation: UITableView.RowAnimation) {
    self.tableView.beginUpdates()
    for i in 0..<rowCount {
      self.tableView.reloadRows(at: [IndexPath(row: i, section: sectionIndex)], with: animation)
    }
    self.tableView.endUpdates()
  }
}

extension CryptoGuideViewController: UITableViewDelegate, UITableViewDataSource {
  func numberOfSections(in _: UITableView) -> Int {
    resources.count
  }

  func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
    CGFloat.leastNormalMagnitude
  }

  func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
    resources[section].guides.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "GuideViewCell", cellType: GuideViewCell.self)
      .configure(resources[indexPath.section].guides[indexPath.row])
    if indexPath.row == 0 {
      cell.topMargin.constant = 16
    }
    else if indexPath.row == resources[indexPath.section].guides.count - 1 {
      cell.bottomMargin.constant = 16
    }
    return cell
  }

  func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if resources[indexPath.section].expanded {
      if indexPath.row == 0 || indexPath.row == resources[indexPath.section].guides.count - 1 {
        return 44
      }
      return 36
    }
    else {
      return 0
    }
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    tableView.dequeueReusableHeaderFooter(
      withIdentifier: "MarketHeaderView",
      cellType: MarketHeaderView.self)
      .configure(
        resources[section],
        isLastSection: section == self.resources.count - 1,
        callback: { [unowned self] header in
          self.resources[section].expanded.toggle()

          header.icon?.image = self.resources[section].expanded
            ? UIImage(named: "arrow-drop-up")
            : UIImage(named: "arrow-drop-down")

          self.reloadRows(
            at: section,
            rowCount: resources[section].guides.count,
            with: .automatic)

          if section == self.resources.count - 1 {
            header.bottomLine.backgroundColor = .greyScaleDivider
          }
          else {
            if self.resources[section].expanded {
              header.bottomLine.backgroundColor = .greyScaleDivider
            }
            else {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                header.bottomLine.backgroundColor = .clear
              }
            }
          }
        })
  }

  func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    let item = resources[indexPath.section].guides[indexPath.row]
    guard let url = URL(string: item.link) else { return }
    UIApplication.shared.open(url)
  }
}

class GuideViewCell: UITableViewCell {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet var topMargin: NSLayoutConstraint!
  @IBOutlet var bottomMargin: NSLayoutConstraint!

  override func prepareForReuse() {
    super.prepareForReuse()
    self.topMargin.constant = 8
    self.bottomMargin.constant = 8
  }

  func configure(_ item: Guide) -> Self {
    self.selectionStyle = .none
    titleLabel.text = item.name
    return self
  }
}

class Market {
  var name: String
  var guides: [Guide]
  var expanded = false
  init(_ name: String, _ guides: [Guide] = []) {
    self.name = name
    self.guides = guides
  }
}

struct Guide {
  var name: String
  var link: String
}

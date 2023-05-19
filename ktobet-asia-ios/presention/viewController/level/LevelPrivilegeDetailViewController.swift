import RxSwift
import SharedBu
import SwiftUI
import UIKit

class LevelPrivilegeDetailViewController: LobbyViewController {
  @IBOutlet private weak var btnPromotion: UIButton!
  @IBOutlet private weak var backgroundView: UIView!
  @IBOutlet private weak var tableView: UITableView!
  @IBOutlet private weak var titleLabel: UILabel!
  @IBOutlet private weak var levelLabel: UILabel!
  @IBOutlet private weak var iconImageView: UIImageView!
  @IBOutlet private weak var footerView: UIView!
  @IBOutlet private weak var dailyLimitAmountLabel: UILabel!
  @IBOutlet private weak var buttonBackgroundView: UIView!
  @IBOutlet private weak var productUnlimitedView: UIView!
  @IBOutlet private weak var productUnlimitedTopBarView: UIView!
  @IBOutlet weak var bannerContainer: UIView!

  private let disposeBag = DisposeBag()
  private let localStorageRepo = Injectable.resolve(LocalStorageRepository.self)!

  private var arg: PrivilegeArg!
  private var cells: [UITableViewCell] = []

  var levelPrivilege: LevelPrivilege!
  var level: Int32!

  var banner: UIView?

  static func instantiate(
    levelPrivilege: LevelPrivilege,
    level: Int32)
    -> LevelPrivilegeDetailViewController
  {
    let controller = LevelPrivilegeDetailViewController.initFrom(storyboard: "LevelPrivilege")

    controller.levelPrivilege = levelPrivilege
    controller.level = level

    return controller
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.delegate = self
    tableView.dataSource = self

    NavigationManagement.sharedInstance
      .addBarButtonItem(vc: self, barItemType: .back, image: "iconNavBack24")

    btnPromotion
      .applyGradient(horizontal: [
        UIColor.complementaryDefault.cgColor,
        UIColor(red: 254 / 255, green: 161 / 255, blue: 68 / 255, alpha: 1).cgColor
      ])

    btnPromotion.rx.touchUpInside
      .subscribe(onNext: {
        NavigationManagement.sharedInstance.goTo(storyboard: "Promotion", viewControllerId: "PromotionNavigationController")
      })
      .disposed(by: disposeBag)

    backgroundView.setViewCorner(topCorner: true, bottomCorner: false, radius: 32)

    levelLabel.layer.masksToBounds = true
    levelLabel.layer.cornerRadius = 16
    levelLabel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]

    buttonBackgroundView
      .addBorder(.top, color: UIColor(red: 155 / 255, green: 155 / 255, blue: 155 / 255, alpha: 0.3))

    levelLabel.text = String(format: Localize.string("common_level_2"), String(level))

    switch levelPrivilege {
    case let depositData as LevelPrivilege.Deposit:
      generateDepositView(data: depositData)
    case let rebateData as LevelPrivilege.Rebate:
      generateProductFeedback(data: rebateData)
    case is LevelPrivilege.ProductSlotRescue:
      generateSlot()
    case let insuranceData as LevelPrivilege.ProductBetInsurance:
      generateInsureance(data: insuranceData)
    default:
      break
    }

    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor.clear
    appearance.shadowImage = UIImage(color: UIColor.clear)

    navigationController?.navigationBar.standardAppearance = appearance
    navigationController?.navigationBar.scrollEdgeAppearance = appearance
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    let barAppearance = UINavigationBarAppearance()
    barAppearance.configureWithTransparentBackground()
    barAppearance.titleTextAttributes = [
      .foregroundColor: UIColor.greyScaleWhite,
      .font: Theme.shared.getNavigationTitleFont(by: localStorageRepo.getSupportLocale())
    ]

    barAppearance.backgroundColor = UIColor.greyScaleDefault.withAlphaComponent(0.9)
    UINavigationBar.appearance().isTranslucent = true

    navigationController?.navigationBar.standardAppearance = barAppearance
    navigationController?.navigationBar.scrollEdgeAppearance = barAppearance
  }

  override func networkDidConnectedHandler() {
    removeBanner()
  }

  override func networkDisconnectHandler() {
    addBanner()
  }

  private func addBanner() {
    guard banner == nil else { return }
    banner = UIHostingController(rootView: BannerView()).view
    banner?.backgroundColor = .clear

    UIView.animate(
      withDuration: 0.0,
      delay: 0.0,
      usingSpringWithDamping: 0.7,
      initialSpringVelocity: 1,
      options: [.curveLinear, .allowUserInteraction],
      animations: { [unowned self] in
        self.bannerContainer.addSubview(self.banner!, constraints: .fill())
      },
      completion: nil)
  }

  private func removeBanner() {
    banner?.removeFromSuperview()
    banner = nil
  }

  private func generateDepositView(data: LevelPrivilege.Deposit) {
    titleLabel.text = Localize.string("common_depositbonus")
    iconImageView.image = UIImage(named: "lvDetailBank")

    if (1...2).contains(level) {
      cells = generateDepositLevelOneTwo(data: data)
    }
    else if (3...10).contains(level) {
      cells = generateDepositGreaterThanLevelTwo(data: data)
    }

    cells.last?.addBorder(.bottom, size: 0.5, rightConstant: 40, leftConstant: 40)
    arg = PrivilegeArg(cells: cells, rowCount: cells.count)
  }

  private func generateProductFeedback(data: LevelPrivilege.Rebate) {
    titleLabel.text = Localize.string("level_product_rebate")
    iconImageView.image = UIImage(named: "lvDetailProduct")
    footerView.isHidden = false
    dailyLimitAmountLabel.text = data.maxBonus.description()

    let products: [ProductType] = [.sbk, .casino, .slot, .numbergame, .arcade]

    products
      .forEach {
        let title = StringMapper.parseProductTypeString(productType: $0)
        let content = generatePercentageText(data.percentages[$0])
        cells.append(generateDetailOneRowCell(leftContent: title, RightContent: content))
      }

    if !data.isMaxBonusLimited() {
      productUnlimitedTopBarView.backgroundColor = UIColor.alert
      productUnlimitedView.backgroundColor = UIColor(red: 1, green: 128 / 255, blue: 0, alpha: 0.2)
      dailyLimitAmountLabel.text = Localize.string("bonus_unlimited")
    }

    cells.last?.addBorder(.bottom, size: 0.5, rightConstant: 40, leftConstant: 40)
    arg = PrivilegeArg(cells: cells, rowCount: cells.count)
  }

  private func generatePercentageText(_ percentage: Percentage?) -> String {
    percentage == nil ? "" : percentage!.description() + "%"
  }

  private func generateSlot() {
    titleLabel.text = Localize.string("bonus_bonusproducttype_2")
    iconImageView.image = UIImage(named: "lvDetailSlot")

    cells.append(generateDetailTwoRowCell(
      firstRow: Localize.string("level_detail_3_1_title"),
      secondRow: Localize.string("level_detail_3_1_content")))

    let imageCell = tableView
      .dequeueReusableCell(withIdentifier: "LevelDetailImageTableViewCell") as! LevelDetailImageTableViewCell
    if level >= 1, level <= 4 {
      imageCell.slotImageView.image = Theme.shared.getUIImage(name: "group1-4", by: localStorageRepo.getSupportLocale())
    }
    else if level >= 5, level <= 6 {
      imageCell.slotImageView.image = Theme.shared.getUIImage(name: "group5-6", by: localStorageRepo.getSupportLocale())
    }
    else if level >= 7, level <= 8 {
      imageCell.slotImageView.image = Theme.shared.getUIImage(name: "group7-8", by: localStorageRepo.getSupportLocale())
    }
    else {
      imageCell.slotImageView.image = Theme.shared.getUIImage(name: "group9+", by: localStorageRepo.getSupportLocale())
    }

    cells.append(imageCell)
    arg = PrivilegeArg(cells: cells, rowCount: cells.count)
  }

  private func generateInsureance(data: LevelPrivilege.ProductBetInsurance) {
    titleLabel.text = Localize.string("level_producttype_1")
    iconImageView.image = UIImage(named: "lvDetailInsure")

    let titles = [Localize.string("level_detail_3_1_title1"), Localize.string("level_detail_3_1_title2")]
    let contents = [
      data.percentage.description(),
      data.maxBonus.description()
    ]

    for i in 0..<2 {
      cells.append(generateDetailOneRowCell(leftContent: titles[i], RightContent: contents[i]))
    }

    cells.append(UITableViewCell())
    arg = PrivilegeArg(cells: cells, rowCount: cells.count)
  }

  private func generateDepositLevelOneTwo(data: LevelPrivilege.Deposit) -> [UITableViewCell] {
    cells.append(generateDetailOneRowCell(
      leftContent: level == 1
        ? Localize.string("level_detail_5_title1_first")
        : Localize.string("level_detail_5_title1"),
      RightContent: data.percentage.description() + "%"))

    cells.append(generateDetailOneRowCell(
      leftContent: Localize.string("level_detail_5_maxamount"),
      RightContent: data.maxBonus.description()))

    cells.append(generateDetailTwoRowCell(
      firstRow: Localize.string("level_detail_5_title3"),
      secondRow: String(
        format: Localize.string("level_detail_5_content3"),
        data.minCapital.description(),
        String(data.betMultiple))))

    return cells
  }

  private func generateDepositGreaterThanLevelTwo(data: LevelPrivilege.Deposit) -> [UITableViewCell] {
    cells.append(generateDetailOneRowCell(
      leftContent: Localize.string("level_detail_5_title1"),
      RightContent: data.percentage.description() + "%"))

    cells.append(generateDetailOneRowCell(
      leftContent: Localize.string("level_detail_5_maxamount"),
      RightContent: data.maxBonus.description()))

    var frequencyTitle = ""
    var frequencyContent = ""

    switch data.issueFrequency {
    case .daily:
      frequencyTitle = Localize.string("level_detail_5_title2_3")
      frequencyContent = Localize.string("level_detail_5_content2_3")
    case .weekly:
      frequencyTitle = Localize.string("level_detail_5_title2_2")
      frequencyContent = Localize.string("level_detail_5_content2_2")
    case .monthly:
      frequencyTitle = Localize.string("level_detail_5_title2_1")
      frequencyContent = Localize.string("level_detail_5_content2_1")
    default:
      break
    }

    cells.append(generateDetailTwoRowCell(
      firstRow: frequencyTitle,
      secondRow: frequencyContent))

    cells.append(generateDetailTwoRowCell(
      firstRow: Localize.string("level_detail_5_title3"),
      secondRow: String(
        format: Localize.string("level_detail_5_content3"),
        data.minCapital.description(),
        String(data.betMultiple))))

    return cells
  }

  private func generateDetailOneRowCell(leftContent: String, RightContent: String) -> UITableViewCell {
    let detailCell = tableView.dequeueReusableCell(withIdentifier: "LevelDetailTableViewCell") as! LevelDetailTableViewCell
    detailCell.leftLabel.text = leftContent
    detailCell.rightLabel.text = RightContent
    return detailCell
  }

  private func generateDetailTwoRowCell(firstRow: String, secondRow: String) -> UITableViewCell {
    let detail2RowCell = tableView.dequeueReusableCell(withIdentifier: "LevelDetail2TableViewCell") as! LevelDetail2TableViewCell
    detail2RowCell.titleLabel.text = firstRow
    detail2RowCell.secondLabel.text = secondRow
    return detail2RowCell
  }
}

struct PrivilegeArg {
  var cells: [UITableViewCell]
  var rowCount: Int
}

extension LevelPrivilegeDetailViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    arg.rowCount
  }

  func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    arg.cells[indexPath.row]
  }
}

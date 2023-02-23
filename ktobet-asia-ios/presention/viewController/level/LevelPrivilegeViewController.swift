import RxCocoa
import RxDataSources
import RxSwift
import SharedBu
import SwiftUI
import UIKit

class Item {
  enum Collapse: Int {
    case fold
    case unFold
  }

  private(set) var model: LevelOverview
  private(set) var level: Int32 = 0
  private(set) var time = ""
  private(set) var privileges: [LevelPrivilege] = []
  var isFold = false
  var collapse: Collapse {
    isFold ? .fold : .unFold
  }

  init(_ model: LevelOverview) {
    self.model = model
    self.level = model.level
    self.time = model.timeStamp.toDateTimeFormatString()
    self.privileges = model.privileges
  }
}

let TopLevel = 10

class LevelPrivilegeViewController: LobbyViewController {
  var currentLevel: Int32 = 0
  let resource = BehaviorRelay<[Item]>(value: [])

  @IBOutlet weak var headerView: UIView!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var levelLabel: UILabel!
  @IBOutlet weak var accountLabel: UILabel!
  @IBOutlet weak var idLabel: UILabel!
  @IBOutlet weak var expButton: UIButton!
  @IBOutlet weak var expLabel: UILabel!
  @IBOutlet weak var progress: PlainHorizontalProgressBar!
  @IBOutlet weak var bannerContainer: UIView!
  var banner: UIView?
  private var disposeBag = DisposeBag()
  private var viewModel = Injectable.resolve(PlayerViewModel.self)!

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self, title: Localize.string("level_levelprivilege"))
    dataBinding()

    headerView
      .applyGradient(horizontal: [
        UIColor.yellowFFD500.cgColor,
        UIColor(red: 254 / 255, green: 161 / 255, blue: 68 / 255, alpha: 1).cgColor
      ])
    progress.borderWidth = 1
    progress.bordersColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)
    progress.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2)
    levelLabel.layer.masksToBounds = true
    levelLabel.layer.cornerRadius = 16
    levelLabel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewModel.loadPlayerInfo().subscribe(onNext: { [weak self] player in
      self?.accountLabel.text = "\(AccountMask.maskAccount(account: player.playerInfo.displayId))"
      self?.idLabel.text = player.playerInfo.gameId
      self?.progress.progress = CGFloat(player.playerInfo.exp.percent / 100)
      self?.expLabel.text = player.playerInfo.exp.description() + "%"
      self?.levelLabel.text = String(format: Localize.string("common_level_2"), String(player.playerInfo.level))
    }).disposed(by: disposeBag)
  }

  @IBAction
  func showExpInfo(_: UIButton) {
    Alert.shared.show(
      Localize.string("level_experience_title"),
      Localize.string("level_experience_desc"),
      confirm: { },
      cancel: nil)
  }

  deinit {
    print("\(type(of: self)) deinit")
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

  private func dataBinding() {
    self.rx.viewWillAppear.flatMap({ [unowned self] _ in
      Observable.combineLatest(self.viewModel.getPrivilege().asObservable(), self.viewModel.loadPlayerInfo())
    })
    .flatMap({ [unowned self] (levelOverview: [LevelOverview], player: Player) -> BehaviorRelay<[Item]> in
      self.currentLevel = player.playerInfo.level
      let items = levelOverview.map({ Item($0) })
      self.mappingItem(items)
      return self.resource
    }).catchError({ [weak self] error -> Observable<[Item]> in
      self?.handleErrors(error)
      return Observable<[Item]>.just([])
    }).bind(to: tableView.rx.items) { [weak self] tableView, row, item in
      let collapseHandler: (Observable<Void>, DisposeBag) -> Void = { [weak self] collapse, disposeBag in
        self?.updateCollapse(tableView: tableView, item: item, collapse: collapse, disposeBag: disposeBag)
      }
      let tapPrivilegeHandler: (LevelPrivilege) -> Void = { [weak self] privilege in
        self?.clickPrivilege(level: item.level, privilege)
      }
      if self?.isPreviewLevel(row) == true {
        return tableView.dequeueReusableCell(
          withIdentifier: "NextLevelTableViewCell",
          cellType: NextLevelTableViewCell.self).configure(item, callback: collapseHandler)
      }
      else if self?.isTopLevel(row) == true {
        return tableView
          .dequeueReusableCell(withIdentifier: "TopLevelTableViewCell", cellType: TopLevelTableViewCell.self)
          .configure(item, callback: collapseHandler, tapPrivilegeHandler: tapPrivilegeHandler)
      }
      else if self?.isZeroLevel(row) == true {
        return tableView.dequeueReusableCell(
          withIdentifier: "ZeroLevelTableViewCell",
          cellType: ZeroLevelTableViewCell.self).configure(item)
      }
      else {
        return tableView.dequeueReusableCell(withIdentifier: "LevelTableViewCell", cellType: LevelTableViewCell.self)
          .configure(item, callback: collapseHandler, tapPrivilegeHandler: tapPrivilegeHandler)
      }
    }.disposed(by: disposeBag)
  }

  func updateCollapse(tableView: UITableView, item: Item, collapse: Observable<Void>, disposeBag: DisposeBag) {
    collapse.bind(onNext: {
      item.isFold.toggle()
      tableView.reloadData()
    }).disposed(by: disposeBag)
  }

  func clickPrivilege(level: Int32, _ privilege: LevelPrivilege) {
    self.performSegue(withIdentifier: LevelPrivilegeDetailViewController.segueIdentifier, sender: (level, privilege))
  }

  private func mappingItem(_ newData: [Item]) {
    let copyValue = self.resource.value
    newData.forEach({ theNew in
      if let theOld = copyValue.first(where: { $0.level == theNew.level }) {
        theNew.isFold = theOld.isFold
      }
    })
    self.resource.accept(newData)
  }

  private func getItem(_ row: Int) -> Item {
    self.resource.value[row]
  }

  private func isTopLevel(_ row: Int) -> Bool {
    row == 0 && getItem(row).level == TopLevel
  }

  private func isPreviewLevel(_ row: Int) -> Bool {
    row == 0 && getItem(row).level != currentLevel
  }

  private func isZeroLevel(_ row: Int) -> Bool {
    row == self.resource.value.count - 1
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == LevelPrivilegeDetailViewController.segueIdentifier {
      if let dest = segue.destination as? LevelPrivilegeDetailViewController {
        let tuple = sender as! (Int32, LevelPrivilege)
        dest.levelPrivilege = tuple.1
        dest.level = tuple.0
      }
    }
  }
}

import RxCocoa
import RxSwift
import SharedBu
import UIKit

class CustomerServiceMainViewController: LobbyViewController {
  private let viewModel = Injectable.resolveWrapper(CustomerServiceHistoryViewModel.self)
  private let mainViewModel = Injectable.resolveWrapper(CustomerServiceMainViewModel.self)
  private var disposeBag = DisposeBag()

  let padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
  let edit = UIBarButtonItem.kto(.text(text: Localize.string("common_edit")))

  @IBOutlet weak var callinBtn: CallinButton!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var emptyView: UIView!

  var barButtonItems: [UIBarButtonItem] = []
  var records: [ChatHistory] = [] {
    didSet {
      self.tableView.reloadData()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self, title: Localize.string("customerservice_online"))
    initUI()
    binding()
    viewModel.refreshData()
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func initUI() {
    callinBtn.btn.rx.touchUpInside
      .throttle(.seconds(3), latest: false, scheduler: MainScheduler.instance)
      .flatMap({ [unowned self] () -> Completable in
        if NetworkStateMonitor.shared.isNetworkConnected == true {
          return CustomServicePresenter.shared
            .startCustomerService(from: self)
            .catch({
              self.handleErrors($0)
              self.callinBtn.isEnable = true
              return Completable.empty()
            })
        }
        else {
          return networkLostToast()
        }
      })
      .subscribe()
      .disposed(by: self.disposeBag)

    tableView.dataSource = self
    tableView.delegate = self
    tableView.setHeaderFooterDivider()
    tableView.rowHeight = UITableView.automaticDimension
  }

  private func binding() {
    mainViewModel
      .getIsChatRoomExist()
      .subscribe(onNext: { [weak self] in
        self?.callinBtn.isEnable = !$0
      })
      .disposed(by: disposeBag)

    mainViewModel
      .leftCustomerService()
      .subscribe(onNext: { [weak self] _ in
        self?.viewModel.refreshData()
      })
      .disposed(by: disposeBag)

    viewModel.getChatHistories()
      .catch({ [weak self] error in
        switch error {
        case KTOError.EmptyData:
          self?.switchContent()
        default:
          self?.handleErrors(error)
        }
        return Observable.just(self?.records ?? [])
      })
      .subscribe(onNext: { [weak self] data in
        self?.switchContent(data)
        self?.records = data
      })
      .disposed(by: disposeBag)
  }

  private func switchContent(_ element: [ChatHistory]? = nil) {
    self.tableView.isHidden = element?.isEmpty ?? true
    self.emptyView.isHidden = !(element?.isEmpty ?? true)
    if let items = element?.isEmpty ?? true ? nil : [padding, edit] {
      self.bind(position: .right, barButtonItems: items)
    }
    else {
      self.navigationItem.rightBarButtonItems?.removeAll()
    }
  }

  private func networkLostToast() -> Completable {
    Completable.create { [weak self] completable -> Disposable in
      self?.showToastOnBottom(Localize.string("common_unknownhostexception"), img: UIImage(named: "Failed"))
      completable(.completed)
      return Disposables.create { }
    }
  }
}

extension CustomerServiceMainViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    self.records.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "MainChatHistoryCell", cellType: MainChatHistoryCell.self)
      .configure(self.records[indexPath.row])
    cell.removeBorder()
    if indexPath.row != 0 {
      cell.addBorder()
    }

    return cell
  }

  func tableView(_ tableView: UITableView, willDisplay _: UITableViewCell, forRowAt indexPath: IndexPath) {
    if isLoadingIndexPath(tableView, indexPath), viewModel.hasNext(indexPath.row) {
      self.viewModel.fetchNext(from: indexPath.row)
    }
  }

  func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    let vc = UIStoryboard(name: "CustomService", bundle: nil)
      .instantiateViewController(withIdentifier: "ChatHistoryViewController") as! ChatHistoryViewController
    vc.roomId = self.records[indexPath.row].roomId
    NavigationManagement.sharedInstance.pushViewController(vc: vc)
  }

  private func isLoadingIndexPath(_ tableView: UITableView, _ indexPath: IndexPath) -> Bool {
    let lastSectionIndex = tableView.numberOfSections - 1
    let lastRowIndex = tableView.numberOfRows(inSection: lastSectionIndex) - 1
    return indexPath.section == lastSectionIndex && indexPath.row == lastRowIndex
  }
}

extension CustomerServiceMainViewController: BarButtonItemable {
  func pressedRightBarButtonItems(_: UIBarButtonItem) {
    self.performSegue(withIdentifier: CustomerServiceHistoryEditViewController.segueIdentifier, sender: nil)
  }
}

extension CustomerServiceMainViewController: CustomServiceDelegate {
  func customServiceBarButtons() -> [UIBarButtonItem]? {
    nil
  }
}

class CallinButton: UIView {
  @IBOutlet weak var btn: UIButton!
  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var icon: UIImageView!
  var isEnable = true {
    didSet {
      if isEnable {
        immediatelyStyle()
      }
      else {
        connectedStyle()
      }
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    self.immediatelyStyle()
  }

  func onPressed(_ callback: ((Observable<Void>) -> Void)?) {
    callback?(btn.rx.touchUpInside.asObservable())
  }

  private func immediatelyStyle() {
    self.backgroundColor = .redF20000
    self.borderWidth = 1
    self.bordersColor = .redF20000
    self.cornerRadius = 6
    self.label.text = Localize.string("customerservice_call_immediately")
    self.label.textColor = .whitePure
    self.icon.image = UIImage(named: "CS_immediately")
    self.btn.isEnabled = true
  }

  private func connectedStyle() {
    self.backgroundColor = .clear
    self.borderWidth = 1
    self.bordersColor = .gray9B9B9B
    self.cornerRadius = 6
    self.label.text = Localize.string("customerservice_call_connected")
    self.label.textColor = .gray9B9B9B
    self.icon.image = UIImage(named: "CS_connected")
    self.btn.isEnabled = false
  }
}

class MainChatHistoryCell: UITableViewCell {
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var messageLabel: UILabel!

  func configure(_ item: ChatHistory) -> Self {
    dateLabel.text = item.createDate.toDateTimeFormatString()
    messageLabel.text = item.title
    return self
  }
}

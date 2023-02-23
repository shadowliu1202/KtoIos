import RxCocoa
import RxSwift
import SharedBu
import SwiftUI
import UIKit

class NotificationViewController: LobbyViewController {
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var emptyViewContainer: UIView!

  private let viewModel = Injectable.resolve(NotificationViewModel.self)!
  private let disposeBag = DisposeBag()

  var barButtonItems: [UIBarButtonItem] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self, title: Localize.string("notification_title"))
    self.bind(position: .right, barButtonItems: .kto(.search))
    tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: CoomonUISetting.bottomSpace, right: 0)
    tableView.tableFooterView = UIView()
    tableView.setHeaderFooterDivider(headerHeight: 1, footerHeight: 1)
    addEmptyView()
    dateBinding()
  }

  private func dateBinding() {
    disposeBag.insert(
      rx.sentMessage(#selector(UIViewController.viewWillAppear(_:))).map { _ in () }
        .bind(to: viewModel.input.refreshTrigger),
      tableView.rx.modelSelected(NotificationItem.self).bind(onNext: navigateToDetail),
      tableView.rx.reachedBottom.bind(to: viewModel.input.loadNextPageTrigger),
      viewModel.output.isHiddenEmptyView.startWith(true).drive(emptyViewContainer.rx.isHidden),
      viewModel.output.notifications.drive(tableView.rx.items(
        cellIdentifier: String(describing: NotificationTableViewCell.self),
        cellType: NotificationTableViewCell.self))
      { row, element, cell in
        cell.setUp(element)
        cell.selectionStyle = .none
        cell.removeBorder()
        if row != 0 {
          cell.addBorder()
        }
      })
  }

  private func navigateToDetail(data: ControlEvent<NotificationItem>.Element) {
    performSegue(withIdentifier: NotificationDetailViewController.segueIdentifier, sender: data)
  }

  private func addEmptyView() {
    let emptyView = UIHostingController(rootView: EmptyNotificationView()).view
    emptyView?.addBorder()
    self.emptyViewContainer.addSubview(emptyView!, constraints: .fill())
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if
      segue.identifier == NotificationDetailViewController.segueIdentifier,
      let dest = segue.destination as? NotificationDetailViewController,
      let notificationItem = sender as? NotificationItem
    {
      dest.data = notificationItem
    }
  }
}

extension NotificationViewController: BarButtonItemable {
  func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
    switch sender {
    case is SearchButtonItem:
      guard
        let searchViewController = UIStoryboard(name: "Notification", bundle: nil)
          .instantiateViewController(withIdentifier: "NotificationSearchViewController") as? NotificationSearchViewController
      else { return }
      NavigationManagement.sharedInstance.pushViewController(vc: searchViewController)
    default: break
    }
  }
}

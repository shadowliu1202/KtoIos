import UIKit
import SharedBu
import RxSwift
import RxCocoa
import SwiftUI

class NotificationViewController: APPViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyViewContainer: UIView!

    var barButtonItems: [UIBarButtonItem] = []

    private let viewModel = DI.resolve(NotificationViewModel.self)!
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self, title: Localize.string("notification_title"))
        self.bind(position: .right, barButtonItems: .kto(.search))
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: CoomonUISetting.bottomSpace, right: 0)
        tableView.tableFooterView = UIView()
        addEmptyView()
        dateBinding()
    }

    private func dateBinding() {
        disposeBag.insert(
            rx.sentMessage(#selector(UIViewController.viewWillAppear(_:))).map { _ in () }.bind(to: viewModel.input.refreshTrigger),
            tableView.rx.modelSelected(NotificationItem.self).bind(onNext: navigateToDetail),
            tableView.rx_reachedBottom.bind(to: viewModel.input.loadNextPageTrigger),
            viewModel.output.isHiddenEmptyView.drive(emptyViewContainer.rx.isHidden),
            viewModel.output.notifications.drive(tableView.rx.items(cellIdentifier: String(describing: NotificationTableViewCell.self), cellType: NotificationTableViewCell.self)) {(row, element, cell) in
                cell.setUp(element)
                cell.selectionStyle = .none
            }
        )
    }
    
    private func navigateToDetail(data: ControlEvent<NotificationItem>.Element) {
        performSegue(withIdentifier: NotificationDetailViewController.segueIdentifier, sender: data)
    }
    
    private func addEmptyView() {
        let emptyView = UIHostingController(rootView: EmptyNotificationView()).view
        emptyView?.addBorder(.top, size: 0.5, color: UIColor.dividerCapeCodGray2)
        self.emptyViewContainer.addSubview(emptyView!, constraints: .fill())
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == NotificationDetailViewController.segueIdentifier,
           let dest = segue.destination as? NotificationDetailViewController,
           let notificationItem = sender as? NotificationItem {
            dest.data = notificationItem
        }
    }
}

extension NotificationViewController: BarButtonItemable {
    func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
        switch sender {
        case is SearchButtonItem:
            guard let searchViewController = UIStoryboard(name: "Notification", bundle: nil).instantiateViewController(withIdentifier: "NotificationSearchViewController") as? NotificationSearchViewController else { return }
            NavigationManagement.sharedInstance.pushViewController(vc: searchViewController)
            break
        default: break
        }
    }
}

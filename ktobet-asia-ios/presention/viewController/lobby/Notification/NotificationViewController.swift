import UIKit
import SharedBu
import RxSwift
import RxCocoa

class NotificationViewController: APPViewController {
    @IBOutlet weak var tableView: UITableView!

    var barButtonItems: [UIBarButtonItem] = []

    private let viewModel = DI.resolve(NotificationViewModel.self)!
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self, title: Localize.string("notification_title"))
        self.bind(position: .right, barButtonItems: .kto(.search))
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: CoomonUISetting.bottomSpace, right: 0)
        tableView.tableFooterView = UIView()
        dateBinding()
    }

    private func dateBinding() {
        viewModel.output.notifications.drive(tableView.rx.items(cellIdentifier: String(describing: NotificationTableViewCell.self), cellType: NotificationTableViewCell.self)) {[unowned self] (row, element, cell) in
            cell.setUp(element, supportLocale: viewModel.output.supportLocale)
            cell.selectionStyle = .none
        }.disposed(by: disposeBag)

        tableView.rx.modelSelected(SharedBu.Notification.self).bind { [weak self] (data) in
            self?.performSegue(withIdentifier: NotificationDetailViewController.segueIdentifier, sender: data)
        }.disposed(by: disposeBag)

        rx.sentMessage(#selector(UIViewController.viewWillAppear(_:)))
            .map { _ in () }
            .bind(to: viewModel.input.refreshTrigger)
            .disposed(by: disposeBag)

        tableView.rx_reachedBottom
            .bind(to: viewModel.input.loadNextPageTrigger)
            .disposed(by: disposeBag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == NotificationDetailViewController.segueIdentifier,
           let dest = segue.destination as? NotificationDetailViewController,
           let notification = sender as? SharedBu.Notification {
            let item: NotifyContentItem = NotifyContentItem(notification, supportLocale: viewModel.output.supportLocale)
            dest.data = item
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

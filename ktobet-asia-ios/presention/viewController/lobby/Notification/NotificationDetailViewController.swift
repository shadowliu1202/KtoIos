import UIKit
import RxSwift
import RxCocoa
import SharedBu

protocol NotificationNavigate: UIViewController {}

class NotificationDetailViewController: LobbyViewController, NotificationNavigate {
    static let segueIdentifier = "toNotificationDetail"
    var data: NotificationItem!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var contentLable: UILabel!
    @IBOutlet weak var maintenTimeLabel: UILabel!
    @IBOutlet weak var goToArrowHight: NSLayoutConstraint!
    @IBOutlet weak var goToBtn: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var goTobtnHight: NSLayoutConstraint!
    @IBOutlet weak var csLabel: UILabel!
    @IBOutlet weak var deleteBtnHight: NSLayoutConstraint!
    private var navigateToDestination: (() -> ())?
    private let viewModel = Injectable.resolve(NotificationViewModel.self)!
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        initUI(data)
        dateBinding()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    private func dateBinding() {
        viewModel.input.selectedMessageId.onNext(data.messageId)

        disposeBag.insert(
            viewModel.output.customerServiceEmail.drive(onNext: { [weak self] csEmail in
                if self?.data.displayCsContact == true {
                    self?.csLabel.text = csEmail
                }
            }),

            deleteButton.rx.touchUpInside.subscribe(onNext: {
                Alert.shared.show(Localize.string("notification_delete_title"), Localize.string("notification_delete_content"), confirm: { [weak self] in
                    self?.viewModel.input.deleteTrigger.onNext(())
                }, confirmText: Localize.string("common_yes"), cancel: { }, cancelText: Localize.string("common_no"))

            }),

            viewModel.output.deletedMessage.drive(onNext: { [weak self] in
                self?.popThenToastSuccess()
            }),

            viewModel.errors().subscribe(onNext: { [weak self] in
                self?.handleErrors($0)
            })
        )
    }
    
    private func initUI(_ item: NotificationItem) {
        titleLabel.text = item.title
        dateTimeLabel.text = item.dateTime
        contentLable.text = item.content
        if let starTime = item.maintenanceTime, let endTime = item.maintenanceEndTime {
            maintenTimeLabel.text = Localize.string("notification_maintenancetime", starTime.toDateTimeString(), endTime.toDateTimeString())
        }
        setGoToUI(item.activityType)
        setNavigationFactory(item.activityType)
        deleteBtnHight.constant = item.deletable == true ? 48 : 0
    }
    
    private func setGoToUI(_ type: MyActivityType?) {
        guard type != nil else {
            goToBtn.setTitle(nil, for: .normal)
            goToArrowHight.constant = 0
            goTobtnHight.constant = 0
            return
        }
        goToBtn.setTitle(Localize.string("notification_goto"), for: .normal)
    }
    
    private func setNavigationFactory(_ type: MyActivityType?) {
        guard let type = type else {
            return
        }
        switch type {
        case .depositneedsverifieddoc:
            self.navigateToDestination = { [unowned self] in
                let storyboard = UIStoryboard(name: "Deposit", bundle: Bundle.main)
                let vc = storyboard.instantiateViewController(withIdentifier: "DepositRecordContainer") as! DepositRecordContainer
                vc.displayId = self.data.transactionId ?? ""
                NavigationManagement.sharedInstance.pushViewController(vc: vc, unwindNavigate: self)
            }
        case .paymentgroupchanged, .offlinecardschange:
            self.navigateToDestination = {
                let vc = OfflinePaymentViewController()
                vc.offlineConfirmUnwindSegueId = "unwindToNotificationDetail"
                NavigationManagement.sharedInstance.pushViewController(vc: vc)
            }
        case .withdrawalrejected, .withdrawalneedsverifieddoc:
            self.navigateToDestination = { [unowned self] in
                let storyboard = UIStoryboard(name: "Withdrawal", bundle: Bundle.main)
                let vc = storyboard.instantiateViewController(withIdentifier: "WithdrawlRecordContainer") as! WithdrawlRecordContainer
                vc.displayId = self.data.transactionId ?? ""
                vc.transactionTransactionType = TransactionType.withdrawal
                NavigationManagement.sharedInstance.pushViewController(vc: vc)
            }
        case .onlinecardschange:
            self.navigateToDestination = {
                NavigationManagement.sharedInstance.goTo(storyboard: "Deposit", viewControllerId: "DepositNavigation")
            }
        case .registercompleted, .levelup:
            self.navigateToDestination = {
                NavigationManagement.sharedInstance.goTo(storyboard: "LevelPrivilege", viewControllerId: "LevelPrivilegeNavigationController")
            }
        default:
            break
        }
    }

    private func popThenToastSuccess() {
        NavigationManagement.sharedInstance.popViewController({ [weak self] in
            self?.showToastOnBottom(Localize.string("notification_deleted"), img: UIImage(named: "Success"))
        })
    }
    
    @IBAction func pressGoToBtn(_ sender: Any) {
        self.navigateToDestination?()
    }
    
    @IBAction func backToNotificationDetail(segue: UIStoryboardSegue) {
        NavigationManagement.sharedInstance.viewController = self
        if let vc = segue.source as? DepositOfflineConfirmViewController {
            if vc.confirmSuccess {
                let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48))
                toastView.show(on: self.view, statusTip: Localize.string("common_request_submitted"), img: UIImage(named: "Success"))
            }
        }
    }
}

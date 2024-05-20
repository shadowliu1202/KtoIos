import RxCocoa
import RxSwift
import sharedbu
import UIKit

protocol NotificationNavigate: UIViewController { }

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
    private var navigateToDestination: (() -> Void)?
    private let disposeBag = DisposeBag()

    var viewModel = Injectable.resolveWrapper(NotificationViewModel.self)

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        initUI(data)
        dateBinding()
    }

    private func dateBinding() {
        viewModel.setup()
        viewModel.input.selectedMessageId.onNext(data.messageId)

        disposeBag.insert(
            viewModel.output.customerServiceEmail.drive(onNext: { [weak self] csEmail in
                if self?.data.displayCsContact == true {
                    self?.csLabel.text = csEmail
                }
            }),

            deleteButton.rx.touchUpInside.subscribe(onNext: {
                Alert.shared.show(
                    Localize.string("notification_delete_title"),
                    Localize.string("notification_delete_content"),
                    confirm: { [weak self] in
                        self?.viewModel.input.deleteTrigger.onNext(())
                    },
                    confirmText: Localize.string("common_yes"),
                    cancel: { },
                    cancelText: Localize.string("common_no"))

            }),

            viewModel.output.deletedMessage.drive(onNext: { [weak self] in
                self?.popThenToastSuccess()
            }),

            viewModel.errors().subscribe(onNext: { [weak self] in
                self?.handleErrors($0)
            }))
    }

    private func initUI(_ item: NotificationItem) {
        titleLabel.text = item.title
        dateTimeLabel.text = item.dateTime
        contentLable.text = item.content
        if let starTime = item.maintenanceTime, let endTime = item.maintenanceEndTime {
            maintenTimeLabel.text = Localize.string(
                "notification_maintenancetime",
                starTime.toDateTimeString(),
                endTime.toDateTimeString())
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
        goToBtn.setTitle(type?.goToBtnTitle, for: .normal)
    }

    private func setNavigationFactory(_ type: MyActivityType?) {
        guard let type else {
            return
        }
        switch type {
        case .depositNeedsVerifiedDoc:
            self.navigateToDestination = { [unowned self] in
                let detailMainViewController = DepositRecordDetailMainViewController(
                    displayId: self.data.transactionId ?? "")

                NavigationManagement.sharedInstance
                    .pushViewController(vc: detailMainViewController)
            }
        case .onlineCardsChange,
             .paymentGroupChanged:
            self.navigateToDestination = {
                NavigationManagement.sharedInstance.goTo(storyboard: "Deposit", viewControllerId: "DepositNavigation")
            }
        case .offlineCardsChange:
            self.navigateToDestination = {
                let vc = OfflinePaymentViewController()
                NavigationManagement.sharedInstance.pushViewController(vc: vc)
            }
        case .withdrawalNeedsVerifiedDoc,
             .withdrawalRejected:
            self.navigateToDestination = { [unowned self] in
                let detailMainViewController = WithdrawalRecordDetailMainViewController(
                    displayId: self.data.transactionId ?? "")

                NavigationManagement.sharedInstance
                    .pushViewController(
                        vc: detailMainViewController,
                        unwindNavigate: self)
            }
        case .levelUp,
             .registerCompleted:
            self.navigateToDestination = {
                NavigationManagement.sharedInstance.goTo(
                    storyboard: "LevelPrivilege",
                    viewControllerId: "LevelPrivilegeNavigationController")
            }
        case .balanceModified,
             .bonusObtained,
             .changeRealNameApproved,
             .changeRealNameNeedsVerifiedDoc,
             .changeRealNameReject,
             .depositApproved,
             .depositFailed,
             .depositFeeRefund,
             .logIn,
             .logout,
             .specialFeature,
             .unknown,
             .withdrawalApproved,
             .withdrawalCanceled,
             .withdrawalPromotionAmount,
             .withdrawalPromotionAmountAndCount,
             .withdrawalPromotionCount:
            break
        }
    }

    private func popThenToastSuccess() {
        NavigationManagement.sharedInstance.popViewController({ [weak self] in
            self?.showToast(Localize.string("notification_deleted"), barImg: .success)
        })
    }

    @IBAction
    func pressGoToBtn(_: Any) {
        self.navigateToDestination?()
    }

    @IBAction
    func backToNotificationDetail(segue _: UIStoryboardSegue) {
        NavigationManagement.sharedInstance.viewController = self
    }
}

extension MyActivityType {
    fileprivate var goToBtnTitle: String {
        var destination = ""
        switch self {
        case .depositNeedsVerifiedDoc:
            destination = Localize.string("deposit_detail_title")
        case .onlineCardsChange,
             .paymentGroupChanged:
            destination = Localize.string("deposit_title")
        case .offlineCardsChange:
            destination = Localize.string("deposit_offline_step1_title")
        case .withdrawalNeedsVerifiedDoc,
             .withdrawalRejected:
            destination = Localize.string("withdrawal_detail_title")
        case .levelUp,
             .registerCompleted:
            destination = Localize.string("bonus_levelprivilege")
        case .balanceModified,
             .bonusObtained,
             .changeRealNameApproved,
             .changeRealNameNeedsVerifiedDoc,
             .changeRealNameReject,
             .depositApproved,
             .depositFailed,
             .depositFeeRefund,
             .logIn,
             .logout,
             .specialFeature,
             .unknown,
             .withdrawalApproved,
             .withdrawalCanceled,
             .withdrawalPromotionAmount,
             .withdrawalPromotionAmountAndCount,
             .withdrawalPromotionCount:
            break
        }
        return Localize.string("notification_goto", [destination])
    }
}

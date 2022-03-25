import Foundation
import RxSwift
import RxCocoa
import SharedBu

class NotificationViewModel: KTOViewModel, ViewModelType {
    private(set) var input: Input!
    private(set) var output: Output!
    private var useCase: NotificationUseCase!
    private var configurationUseCase: ConfigurationUseCase!
    private var systemStatusUseCase: GetSystemStatusUseCase!

    var notificationsPagination: Pagination<SharedBu.Notification>!
    lazy var supportLocale: SupportLocale = configurationUseCase.locale()
    lazy var getCustomerServiceEmail = systemStatusUseCase.getCustomerServiceEmail()
    private let refreshTrigger = PublishSubject<Void>()
    private var pagination: Pagination<SharedBu.Notification>!
    private let keyword = BehaviorSubject<String>(value: "")

    init(useCase: NotificationUseCase, configurationUseCase: ConfigurationUseCase, systemStatusUseCase: GetSystemStatusUseCase) {
        super.init()
        self.useCase = useCase
        self.configurationUseCase = configurationUseCase
        self.systemStatusUseCase = systemStatusUseCase

        initPagination()

        let notifications = getNotifications()
        let isHiddenEmptyView = isHiddenEmptyView(notifications)

        self.input = Input(refreshTrigger: refreshTrigger.asObserver(),
                           loadNextPageTrigger: pagination.loadNextPageTrigger.asObserver(),
                           keywod: keyword.asObserver())
        self.output = Output(notifications: notifications,
                             isHiddenEmptyView: isHiddenEmptyView,
                             supportLocale: configurationUseCase.locale())
    }

    private func initPagination() {
        pagination = Pagination<SharedBu.Notification>(pageIndex: 1, offset: 1, callBack: { [unowned self] (page) -> Observable<[SharedBu.Notification]> in
            self.searchNotification(page: page)
        })
    }

    private func getNotifications() -> Driver<[SharedBu.Notification]> {
        refreshTrigger.flatMapLatest { [unowned self] _ -> Driver<[SharedBu.Notification]> in
            self.pagination.refreshTrigger.onNext(())
            return Driver.combineLatest(getActivityNotification(), self.pagination.elements.asDriver(onErrorJustReturn: []))
                .map { (activityNnotificationSummary, playerNotifications) -> [SharedBu.Notification] in
                    self.sortedNotifications(activityNotifications: activityNnotificationSummary.notifications,
                                             playerNotifications: playerNotifications)
                }
        }.asDriver(onErrorJustReturn: [])
    }

    private func sortedNotifications(activityNotifications: [SharedBu.Notification], playerNotifications: [SharedBu.Notification]) -> [SharedBu.Notification] {
        let allNotification = activityNotifications + playerNotifications
        let sortedNotification = allNotification.sorted(by: { $0.displayTime.compareTo(other: $1.displayTime) > 0 })
        return sortedNotification
    }

    private func isHiddenEmptyView(_ notifications: Driver<[SharedBu.Notification]>) -> Driver<Bool> {
        Driver.combineLatest(notifications, keyword.map { $0.count >= 3 }.asDriver(onErrorJustReturn: false))
            .map({ (notifications, isValidKeyword) in
                if notifications.count == 0 && isValidKeyword {
                    return false
                } else {
                    return true
                }
            })
    }

    private func searchNotification(page: Int) -> Observable<[SharedBu.Notification]> {
        useCase.searchNotification(keyword: try! keyword.value(), page: page)
            .map { $0.notifications }
            .compose(self.applySingleErrorHandler()).asObservable()
    }

    private func getActivityNotification() -> Driver<NotificationSummary> {
        useCase.getActivityNotification(keyword: try! keyword.value())
            .compose(self.applySingleErrorHandler())
            .asDriver(onErrorJustReturn: NotificationSummary(totalCount: 0, notifications: []))
    }
}

extension NotificationViewModel {
    struct Input {
        let refreshTrigger: AnyObserver<Void>
        let loadNextPageTrigger: AnyObserver<Void>
        let keywod: AnyObserver<String>
    }

    struct Output {
        let notifications: Driver<[SharedBu.Notification]>
        let isHiddenEmptyView: Driver<Bool>
        let supportLocale: SupportLocale
    }
    
    func deleteMessage(messageId: String) -> Completable {
        return useCase.deleteNotification(messageId: messageId)
    }
    
    static func createActivityTitle(notification: SharedBu.Notification) -> String {
        guard let notify = notification as? SharedBu.Notification.Activity else {
            return notification.title
        }
        let type = notify.myActivityType
        switch type {
        case .registercompleted:
            return Localize.string("notify_10")
        case .depositneedsverifieddoc:
            return Localize.string("notify_20")
        case .withdrawalneedsverifieddoc:
            return Localize.string("notify_30")
        case .offlinecardschange:
            return Localize.string("notify_50")
        case .paymentgroupchanged:
            return Localize.string("notify_110")
        case .onlinecardschange:
            return Localize.string("notify_51")
        case .withdrawalrejected:
            return Localize.string("notify_100")
        case .levelup:
            return Localize.string("notify_150")
        default:
            return ""
        }
    }
    
    static func createActivityContent(notification: SharedBu.Notification, supportLocale: SupportLocale) -> String {
        guard let item = notification as? SharedBu.Notification.Activity else {
            return notification.message
        }
        switch item.myActivityType {
        case .registercompleted:
            return Localize.string("notify_content_10")
        case .depositneedsverifieddoc:
            return Localize.string("notify_content_20",
                                   FiatFactory().create(supportLocale: supportLocale, amount_: item.value ?? "").amount(),
                                   item.transactionId)
        case .withdrawalneedsverifieddoc:
            return Localize.string("notify_content_30",
                                   FiatFactory().create(supportLocale: supportLocale, amount_: item.value ?? "").amount(),
                                   item.transactionId)
        case .offlinecardschange:
            return Localize.string("notify_content_50")
        case .paymentgroupchanged:
            return Localize.string("notify_content_110")
        case .onlinecardschange:
            return Localize.string("notify_content_51")
        case .withdrawalrejected:
            return Localize.string("notify_content_100",
                                   FiatFactory().create(supportLocale: supportLocale, amount_: item.value ?? "").amount(),
                                   item.transactionId)
        case .levelup:
            return Localize.string("notify_content_150", item.value ?? "")
        default:
            return ""
        }
    }
}

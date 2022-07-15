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

    private let keyword = BehaviorSubject<String>(value: "")
    private let selectedMessageId = BehaviorSubject<String>(value: "")
    private let refreshTrigger = PublishSubject<Void>()
    private let deleteTrigger = PublishSubject<Void>()
    private var pagination: Pagination<SharedBu.Notification>!

    init(useCase: NotificationUseCase, configurationUseCase: ConfigurationUseCase, systemStatusUseCase: GetSystemStatusUseCase) {
        super.init()
        self.useCase = useCase
        self.configurationUseCase = configurationUseCase
        self.systemStatusUseCase = systemStatusUseCase

        initPagination()

        let notifications = getNotifications()
        let isHiddenEmptyView = isHiddenEmptyView(notifications)
        let customerServiceEmail = getCustomerServiceEmail()
        let deletedMessage = deleteNotification()

        self.input = Input(refreshTrigger: refreshTrigger.asObserver(),
                           loadNextPageTrigger: pagination.loadNextPageTrigger.asObserver(),
                           keywod: keyword.asObserver(),
                           deleteTrigger: deleteTrigger.asObserver(),
                           selectedMessageId: selectedMessageId.asObserver())
        self.output = Output(notifications: notifications,
                             isHiddenEmptyView: isHiddenEmptyView,
                             customerServiceEmail: customerServiceEmail,
                             deletedMessage: deletedMessage)
    }

    private func initPagination() {
        pagination = Pagination<SharedBu.Notification>(pageIndex: 1, offset: 1, callBack: { [unowned self] (page) -> Observable<[SharedBu.Notification]> in
            self.searchNotification(page: page)
        })
    }

    private func deleteNotification() -> Driver<Void> {
        deleteTrigger.withLatestFrom(selectedMessageId)
            .flatMapLatest { [unowned self] id in
                self.useCase.deleteNotification(messageId: id)
                    .andThen(Single.just(()))
                    .compose(self.applySingleErrorHandler())
            }.asDriverLogError()
    }

    private func getCustomerServiceEmail() -> Driver<String> {
        systemStatusUseCase.getCustomerServiceEmail()
            .compose(self.applySingleErrorHandler())
            .asDriver(onErrorJustReturn: "")
    }

    private func getNotifications() -> Driver<[NotificationItem]> {
        refreshTrigger.flatMapLatest { [unowned self] _ -> Driver<[NotificationItem]> in
            self.pagination.refreshTrigger.onNext(())
            return Driver.combineLatest(getActivityNotification(), self.pagination.elements.asDriver(onErrorJustReturn: []))
                .map({self.sortedNotifications(activityNotifications: $0.notifications, playerNotifications: $1)})
        }.asDriver(onErrorJustReturn: [])
    }

    private func sortedNotifications(activityNotifications: [SharedBu.Notification], playerNotifications: [SharedBu.Notification]) -> [NotificationItem] {
        let supportLocale = configurationUseCase.locale()
        let allNotification = activityNotifications + playerNotifications
        let sortedNotification = allNotification.sorted(by: { $0.displayTime.compareTo(other: $1.displayTime) > 0 }).map { NotificationItem($0, supportLocale: supportLocale) }
        return filterKeyword(notificationItem: sortedNotification)
    }

    private func filterKeyword(notificationItem: [NotificationItem]) -> [NotificationItem] {
        let keyword = try! keyword.value()
        return notificationItem.filter { notificationItem in
            if keyword.isEmpty {
                return true
            } else {
                return isNotificationItemContainedKeyword(item: notificationItem, keyword: keyword)
            }
        }
    }
    
    private func isNotificationItemContainedKeyword(item: NotificationItem, keyword: String) -> Bool {
        isStringContainedKeyword(item.title, keyword) || isStringContainedKeyword(item.content, keyword)
    }
    
    private func isStringContainedKeyword(_ item: String, _ keyword: String) -> Bool {
        item.removeAccent().localizedCaseInsensitiveContains(keyword.removeAccent())
    }

    private func isHiddenEmptyView(_ notifications: Driver<[NotificationItem]>) -> Driver<Bool> {
        Driver.combineLatest(notifications, keyword.map { $0.count >= 3 }.asDriver(onErrorJustReturn: false))
            .map({ (notifications, isValidKeyword) in
            if notifications.count == 0 && isValidKeyword {
                return false
            } else if notifications.count == 0 {
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
        useCase.getActivityNotification()
            .compose(self.applySingleErrorHandler())
            .asDriver(onErrorJustReturn: NotificationSummary(totalCount: 0, notifications: []))
    }
}

extension NotificationViewModel {
    struct Input {
        let refreshTrigger: AnyObserver<Void>
        let loadNextPageTrigger: AnyObserver<Void>
        let keywod: AnyObserver<String>
        let deleteTrigger: AnyObserver<Void>
        var selectedMessageId: AnyObserver<String>
    }

    struct Output {
        let notifications: Driver<[NotificationItem]>
        let isHiddenEmptyView: Driver<Bool>
        let customerServiceEmail: Driver<String>
        let deletedMessage: Driver<Void>
    }
}



class NotificationItem {
    var messageId: String
    var typeTitle: String?
    var title: String!
    var dateTime: String?
    var content: String!
    var deletable: Bool?
    var maintenanceTime: OffsetDateTime?
    var maintenanceEndTime: OffsetDateTime?
    var activityType: MyActivityType?
    var transactionId: String?
    var displayCsContact: Bool?

    init(_ bean: SharedBu.Notification, supportLocale: SupportLocale) {
        self.messageId = bean.messageId
        self.title = createActivityTitle(notification: bean)
        self.dateTime = bean.displayTime.toDateTimeString()
        self.content = createActivityContent(notification: bean, supportLocale: supportLocale)
        self.deletable = bean.deletable
        if let maintenanceNotification = bean as? SharedBu.Notification.Maintenance {
            self.maintenanceTime = maintenanceNotification.maintenanceStart
            self.maintenanceEndTime = maintenanceNotification.maintenanceEnd
        } else if let activityNotification = bean as? SharedBu.Notification.Activity {
            self.activityType = activityNotification.myActivityType
            self.transactionId = activityNotification.transactionId
        }
        self.displayCsContact = bean is SharedBu.Notification.Activity ? false : true
        self.typeTitle = createTypeTitle(bean)
    }

    private func createTypeTitle(_ element: SharedBu.Notification) -> String {
        switch element {
        case is SharedBu.Notification.Maintenance:
            return Localize.string("notification_type_0")
        case is SharedBu.Notification.Activity:
            return Localize.string("notification_type_activity")
        case is SharedBu.Notification.General:
            return Localize.string("notification_type_1")
        case is SharedBu.Notification.Personal:
            return Localize.string("notification_type_2")
        default:
            return ""
        }
    }

    private func createActivityTitle(notification: SharedBu.Notification) -> String {
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

    private func createActivityContent(notification: SharedBu.Notification, supportLocale: SupportLocale) -> String {
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

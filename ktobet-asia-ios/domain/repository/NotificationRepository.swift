import Foundation
import SharedBu

protocol NotificationRepository {
  func getActivityNotification() -> Single<NotificationSummary>
  func searchNotification(keyword: String, page: Int) -> Single<NotificationSummary>
  func deleteNotification(messageId: String) -> Completable
}

class NotificationRepositoryImpl: NotificationRepository {
  private var api: NotificationApi!

  init(_ api: NotificationApi) {
    self.api = api
  }

  func searchNotification(keyword: String, page: Int) -> Single<NotificationSummary> {
    api.getPlayerAllNotification(page: page, keyword: keyword).flatMap { response in
      guard let data = response.data else { return Single.error(KTOError.EmptyData) }
      let notifications = try data.documents.map { internalMessageBean -> SharedBu.Notification? in
        switch internalMessageBean.messageType {
        case 0:
          return SharedBu.Notification.Maintenance(
            messageId: internalMessageBean.messageId,
            title: internalMessageBean.title,
            message: internalMessageBean.message,
            displayTime: try internalMessageBean.showTime?
              .toOffsetDateTime() ?? OffsetDateTime.companion.NotDefine,
            maintenanceStart: try internalMessageBean.maintenanceStartTime
              .toShareOffsetDateTime(),
            maintenanceEnd: try internalMessageBean.maintenanceEndTime
              .toShareOffsetDateTime())
        case 1:
          return SharedBu.Notification.General(
            messageId: internalMessageBean.messageId,
            title: internalMessageBean.title,
            message: internalMessageBean.message,
            displayTime: try internalMessageBean.showTime.toShareOffsetDateTime())
        case 2:
          return SharedBu.Notification.Personal(
            messageId: internalMessageBean.messageId,
            title: internalMessageBean.title,
            message: internalMessageBean.message,
            displayTime: try internalMessageBean.showTime.toShareOffsetDateTime())
        default:
          return nil
        }
      }

      return Single.just(NotificationSummary(totalCount: data.totalCount, notifications: notifications.compactMap { $0 }))
    }
  }

  func getActivityNotification() -> Single<NotificationSummary> {
    api.getActivityNotification().flatMap { response in
      guard let data = response.data else { return Single.error(KTOError.EmptyData) }
      let notifications = try data.documents.map { activityMessageBean in
        SharedBu.Notification.Activity(
          messageId: activityMessageBean.itemId,
          title: activityMessageBean.notifyTitle,
          message: activityMessageBean.notifyContent.replacingOccurrences(
            of: "{value}",
            with: activityMessageBean.value ?? ""),
          displayTime: try activityMessageBean.dateInfo.toOffsetDateTime(),
          myActivityType: MyActivityType.companion
            .create(type: activityMessageBean.myActivityType),
          transactionId: activityMessageBean.displayId,
          amount: activityMessageBean.afterBalance?.toAccountCurrency() ?? AccountCurrency
            .zero(),
          value: activityMessageBean.value)
      }

      return Single.just(NotificationSummary(totalCount: data.totalCount, notifications: notifications))
    }
  }

  func deleteNotification(messageId: String) -> Completable {
    api.deleteNotification(messageId: messageId)
  }
}

import Foundation
import sharedbu

protocol NotificationUseCase {
  func getActivityNotification() -> Single<NotificationSummary>
  func searchNotification(keyword: String, page: Int) -> Single<NotificationSummary>
  func deleteNotification(messageId: String) -> Completable
}

class NotificationUseCaseImpl: NotificationUseCase {
  private var repo: NotificationRepository!

  init(_ repo: NotificationRepository) {
    self.repo = repo
  }

  func searchNotification(keyword: String, page: Int) -> Single<NotificationSummary> {
    repo.searchNotification(keyword: keyword, page: page)
  }

  func getActivityNotification() -> Single<NotificationSummary> {
    repo.getActivityNotification().map { summary in
      let notifications = summary.notifications.filter({ [unowned self] notification in
        self.isShown(myActivityType: (notification as! sharedbu.Notification.Activity).myActivityType)
      })

      return NotificationSummary(totalCount: Int32(notifications.count), notifications: notifications)
    }
  }

  private func isShown(myActivityType: MyActivityType) -> Bool {
    switch myActivityType {
    case .depositneedsverifieddoc,
         .levelup,
         .offlinecardschange,
         .onlinecardschange,
         .paymentgroupchanged,
         .registercompleted,
         .withdrawalneedsverifieddoc,
         .withdrawalrejected: return true
    default:
      return false
    }
  }

  func deleteNotification(messageId: String) -> Completable {
    repo.deleteNotification(messageId: messageId)
  }
}

import Mockingbird
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class NotificationDetailViewControllerTests: XCTestCase {
  func buildNotificationItem(type: MyActivityType) -> SharedBu.Notification {
    SharedBu.Notification.Activity(
      messageId: "",
      title: "",
      message: "",
      displayTime: Date().toUTCOffsetDateTime(),
      myActivityType: type,
      transactionId: "",
      amount: "0".toAccountCurrency(),
      value: "")
  }

  func test_ReceivePaymentRickGroupChanged_ClickGoToBtn_GoDepositPage_KTO_TC_102() {
    let stubNotificationItem = buildNotificationItem(type: .paymentgroupchanged)
    let mockNavigator = mock(Navigator.self)

    NavigationManagement.sharedInstance = mockNavigator

    let sut = NotificationDetailViewController.initFrom(storyboard: "Notification")
    sut.data = .init(stubNotificationItem, supportLocale: .China())

    sut.loadViewIfNeeded()
    sut.goToBtn.sendActions(for: .touchUpInside)

    verify(
      mockNavigator.goTo(
        storyboard: "Deposit",
        viewControllerId: "DepositNavigation")
    )
    .wasCalled()
  }
  
  func test_ReceiveOnlineCardsChanged_ClickGoToBtn_GoDepositPage_KTO_TC_103() {
    let stubNotificationItem = buildNotificationItem(type: .onlinecardschange)
    let mockNavigator = mock(Navigator.self)

    NavigationManagement.sharedInstance = mockNavigator

    let sut = NotificationDetailViewController.initFrom(storyboard: "Notification")
    sut.data = .init(stubNotificationItem, supportLocale: .China())

    sut.loadViewIfNeeded()
    sut.goToBtn.sendActions(for: .touchUpInside)

    verify(
      mockNavigator.goTo(
        storyboard: "Deposit",
        viewControllerId: "DepositNavigation")
    )
    .wasCalled()
  }
  
  func test_ReceiveOfflineBanksChanged_ClickGoToBtn_GoOfflinePaymentPage_KTO_TC_104() {
    let stubNotificationItem = buildNotificationItem(type: .offlinecardschange)
    let mockNavigator = mock(Navigator.self)

    NavigationManagement.sharedInstance = mockNavigator

    let sut = NotificationDetailViewController.initFrom(storyboard: "Notification")
    sut.data = .init(stubNotificationItem, supportLocale: .China())

    sut.loadViewIfNeeded()
    sut.goToBtn.sendActions(for: .touchUpInside)

    verify(
      mockNavigator.pushViewController(
        vc: any(OfflinePaymentViewController.self))
    )
    .wasCalled()
  }
}

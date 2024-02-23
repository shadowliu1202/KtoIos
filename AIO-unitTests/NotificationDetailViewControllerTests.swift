import Mockingbird
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

final class NotificationDetailViewControllerTests: XCBaseTestCase {
  private func buildNotificationItem(type: MyActivityType) -> sharedbu.Notification {
    sharedbu.Notification.Activity(
      messageId: "",
      title: "",
      message: "",
      displayTime: Date().toUTCOffsetDateTime(),
      myActivityType: type,
      transactionId: "",
      amount: "0".toAccountCurrency(),
      value: "")
  }

  private func getStubViewModel() -> NotificationViewModel {
    let notificationViewModel = mock(NotificationViewModel.self)
      .initialize(
        useCase: mock(NotificationUseCase.self),
        configurationUseCase: mock(ConfigurationUseCase.self),
        systemStatusUseCase: mock(ISystemStatusUseCase.self))
    given(notificationViewModel.setup()) ~> { }
    given(notificationViewModel.input) ~> .init(
      refreshTrigger: .init(eventHandler: { _ in }),
      loadNextPageTrigger: .init(eventHandler: { _ in }),
      keywod: .init(eventHandler: { _ in }),
      deleteTrigger: .init(eventHandler: { _ in }),
      selectedMessageId: .init(eventHandler: { _ in }))
    given(notificationViewModel.output) ~> .init(
      notifications: .never(),
      isHiddenEmptyView: .never(),
      customerServiceEmail: .never(),
      deletedMessage: .never())
    given(notificationViewModel.errors()) ~> .never()

    return notificationViewModel
  }

  func test_ReceivePaymentRickGroupChanged_ClickGoToBtn_GoDepositPage_KTO_TC_102() {
    let stubNotificationItem = buildNotificationItem(type: .paymentGroupChanged)
    let mockNavigator = mock(Navigator.self)

    NavigationManagement.sharedInstance = mockNavigator

    let sut = NotificationDetailViewController.initFrom(storyboard: "Notification")
    sut.viewModel = getStubViewModel()
    sut.data = .init(stubNotificationItem, supportLocale: .China())

    sut.loadViewIfNeeded()
    sut.goToBtn.sendActions(for: .touchUpInside)

    verify(
      mockNavigator.goTo(
        storyboard: "Deposit",
        viewControllerId: "DepositNavigation"))
      .wasCalled()
  }

  func test_ReceiveOnlineCardsChanged_ClickGoToBtn_GoDepositPage_KTO_TC_103() {
    let stubNotificationItem = buildNotificationItem(type: .onlineCardsChange)
    let mockNavigator = mock(Navigator.self)

    NavigationManagement.sharedInstance = mockNavigator

    let sut = NotificationDetailViewController.initFrom(storyboard: "Notification")
    sut.viewModel = getStubViewModel()
    sut.data = .init(stubNotificationItem, supportLocale: .China())

    sut.loadViewIfNeeded()
    sut.goToBtn.sendActions(for: .touchUpInside)

    verify(
      mockNavigator.goTo(
        storyboard: "Deposit",
        viewControllerId: "DepositNavigation"))
      .wasCalled()
  }

  func test_ReceiveOfflineBanksChanged_ClickGoToBtn_GoOfflinePaymentPage_KTO_TC_104() {
    let stubNotificationItem = buildNotificationItem(type: .offlineCardsChange)
    let mockNavigator = mock(Navigator.self)

    NavigationManagement.sharedInstance = mockNavigator

    let sut = NotificationDetailViewController.initFrom(storyboard: "Notification")
    sut.viewModel = getStubViewModel()
    sut.data = .init(stubNotificationItem, supportLocale: .China())

    sut.loadViewIfNeeded()
    sut.goToBtn.sendActions(for: .touchUpInside)

    verify(
      mockNavigator.pushViewController(
        vc: any(OfflinePaymentViewController.self)))
      .wasCalled()
  }
}

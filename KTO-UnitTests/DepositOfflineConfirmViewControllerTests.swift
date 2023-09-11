import Mockingbird
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class DepositOfflineConfirmViewControllerTests: XCBaseTestCase {
  let bankCard: PaymentsDTO.BankCard =
    .init(
      identity: "",
      bankId: "1",
      name: "Test selected bank",
      verifier: .init())

  let memo: OfflineDepositDTO.Memo =
    .init(
      identity: "",
      remitter: .init(name: "Test remiiter", account: "", bankName: ""),
      remittance: "123".toAccountCurrency(),
      beneficiary: .init(
        name: "",
        branch: "Test branch",
        account: .init(accountName: "Test receiver", accountNumber: "1234-5678-9011")),
      expiredHour: 3)

  func test_givenDepositCountOverLimit_InDepositOfflineConfirmPage_thenAlertRequestLater() {
    injectStubCultureCode(.CN)

    let playerDepositCountOverLimit = ExceptionFactory.companion.create(message: "", statusCode: "10101")

    let stubViewModel = mock(DepositOfflineConfirmViewModel.self)
      .initialize(
        depositService: mock(AbsDepositAppService.self),
        locale: .China())

    given(stubViewModel.depositSuccessDriver) ~> .just(())
    given(stubViewModel.expiredDriver) ~> .just(())
    given(stubViewModel.errors()) ~> .just(playerDepositCountOverLimit)

    let stubAlert = mock(AlertProtocol.self)

    let sut = DepositOfflineConfirmViewController(
      viewModel: stubViewModel,
      memo: memo,
      selectedBank: bankCard,
      alert: stubAlert)

    sut.loadViewIfNeeded()

    verify(
      stubAlert.show(
        any(),
        "您有五个待处理的充值请求，请您过三分钟后再试",
        confirm: any(),
        confirmText: any(),
        cancel: any(),
        cancelText: any(),
        tintColor: any()))
      .wasCalled()
  }
}

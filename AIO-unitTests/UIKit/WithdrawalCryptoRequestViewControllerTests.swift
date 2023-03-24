import Mockingbird
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class WithdrawalCryptoRequestViewControllerTests: XCTestCase {
  private func injectStubSupportLocale(_ supportLocale: SupportLocale) {
    let stubLocalStorageRepository = mock(LocalStorageRepository.self)

    given(stubLocalStorageRepository.getSupportLocale()) ~> supportLocale

    Injectable
      .register(LocalStorageRepository.self) { _ in
        stubLocalStorageRepository
      }
  }

  override func tearDown() {
    Injection.shared.registerAllDependency()
  }

  func test_givenVNLocale_whenInWithdrawalCryptoRequestPage_thenDisplayCurrencyRatioHint_KTO_TC_107() {
    injectStubSupportLocale(.Vietnam())

    let sut = WithdrawalCryptoRequestViewController.initFrom(storyboard: "Withdrawal")
    sut.bankcardId = ""
    sut.cryptoNewrok = .erc20
    sut.supportCryptoType = .usdt

    sut.loadViewIfNeeded()

    XCTAssertFalse(sut.currencyRatioLabel.isHidden)
  }

  func test_givenCNLocale_whenInWithdrawalCryptoRequestPage_thenNotDisplayCurrencyRatioHint_KTO_TC_108() {
    injectStubSupportLocale(.China())

    let sut = WithdrawalCryptoRequestViewController.initFrom(storyboard: "Withdrawal")
    sut.bankcardId = ""
    sut.cryptoNewrok = .erc20
    sut.supportCryptoType = .usdt

    sut.loadViewIfNeeded()

    XCTAssertTrue(sut.currencyRatioLabel.isHidden)
  }
}

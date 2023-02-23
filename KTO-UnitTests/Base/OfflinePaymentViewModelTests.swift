import Mockingbird
import RxSwift
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class OfflinePaymentViewModelTests: XCTestCase {
  private func buildSUT() -> OfflinePaymentViewModel {
    let dummyHttpClient = getFakeHttpClient()
    let stubBankApi = mock(BankApi.self).initialize(dummyHttpClient)

    given(stubBankApi.getDepositTypesString()) ~>
      .just(
        "{\"statusCode\":\"\",\"errorMsg\":\"\",\"node\":\"1069e0061c30\",\"data\":[{\"depositTypeId\":0,\"depositTypeName\":\"Offline\",\"isFavorite\":false,\"depositLimitMaximum\":100.0,\"depositLimitMinimum\":50.0}]}")

    given(stubBankApi.getDepositOfflineBankAccounts()) ~>
      .just(
        "{\"statusCode\":\"\",\"errorMsg\":\"\",\"node\":\"1069e0061c30\",\"data\":{\"paymentGroupPaymentCards\":{\"1\":{\"paymentTokenId\":\"TokenIDTokenIDTokenI\",\"bankId\":1,\"branch\":\"\",\"accountName\":\"12345678901234567890\",\"accountNumber\":\"test-Acc No.\"}}}}")

    given(stubBankApi.getBanks()) ~>
      .just(
        "{\"statusCode\":\"\",\"errorMsg\":\"\",\"node\":\"1069e0061c30\",\"data\":[{\"bankId\":1,\"shortName\":\"ICBC\",\"name\":\"工商银行\"}]}")

    let stubNetworkFactory = mock(NetworkFactory.self).initialize(dummyHttpClient)

    given(stubNetworkFactory.getDeposit()) ~> DepositAdapter(stubBankApi, CPSApi(dummyHttpClient))
    given(stubNetworkFactory.getCash()) ~> CashAdapter(PlayerApi(dummyHttpClient))
    given(stubNetworkFactory.getImage()) ~> ImageAdapter(ImageApi(dummyHttpClient))
    given(stubNetworkFactory.getCommon()) ~> CommonAdapter(stubBankApi)

    Injectable
      .register(ExternalProtocolService.self) { _ in
        stubNetworkFactory
      }

    let dummyPlayerUseCase = mock(PlayerDataUseCase.self)
    let dummyLocalStorageRepo = mock(LocalStorageRepository.self)

    given(dummyLocalStorageRepo.getCultureCode()) ~> "zh-cn"

    return OfflinePaymentViewModel(
      depositService: Injectable.resolveWrapper(ApplicationFactory.self).deposit(),
      playerUseCase: dummyPlayerUseCase,
      localStorageRepo: dummyLocalStorageRepo)
  }

  override func setUp() {
    injectStubCultureCode(.CN)
  }

  override func tearDown() {
    Injection.shared.registerAllDependency()
  }

  func test_givenRemitAmountLimitRangeIs10To100_whenRemittanceIs101_thenSubmitRemittanceButtonDisableAndDisplayedErrorMessage_KTO_TC_51(
  ) {
    let stubRemittanceInfo = OfflinePaymentDataModel.RemittanceInfo(
      selectedGatewayId: "1test-Acc No.",
      bankName: "testBank",
      remitterName: "testRemitter",
      bankCardNumber: nil,
      amount: "101")

    let sut = buildSUT()

    sut.fetchGatewayData()
    sut.verifyRemitInfo(info: stubRemittanceInfo)

    let expect = OfflinePaymentDataModel.RemittanceInfoError(
      bankName: "",
      remitterName: "",
      bankCardNumber: "",
      amount: "请在单笔限额范围内。")

    let actual = sut.remitInfoErrorMessage

    XCTAssertEqual(expect, actual)
    XCTAssertTrue(sut.submitButtonDisable)
  }

  func test_givenRemitAmountLimitRangeIs10To100_whenRemittanceInRange_thenSubmitRemittanceButtonEnableAndNoDisplayedErrorMessage_KTO_TC_52(
  ) {
    let stubRemittanceInfo = OfflinePaymentDataModel.RemittanceInfo(
      selectedGatewayId: "1test-Acc No.",
      bankName: "testBank",
      remitterName: "testRemitter",
      bankCardNumber: nil,
      amount: "90")

    let sut = buildSUT()

    sut.fetchGatewayData()
    sut.verifyRemitInfo(info: stubRemittanceInfo)

    let expect = OfflinePaymentDataModel.RemittanceInfoError(
      bankName: "",
      remitterName: "",
      bankCardNumber: "",
      amount: "")

    let actual = sut.remitInfoErrorMessage

    XCTAssertEqual(expect, actual)
    XCTAssertFalse(sut.submitButtonDisable)
  }
}

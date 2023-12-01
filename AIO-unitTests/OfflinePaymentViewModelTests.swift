import Mockingbird
import RxSwift
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

final class OfflinePaymentViewModelTests: XCBaseTestCase {
  private func buildSUT() -> OfflinePaymentViewModel {
    let dummyHttpClient = getFakeHttpClient()
    let stubDepositAPI = mock(DepositAPI.self).initialize(dummyHttpClient)
    let stubCommonAPI = mock(CommonAPI.self).initialize(dummyHttpClient)

    given(stubDepositAPI.getDepositTypesString()) ~>
      .just(
        "{\"statusCode\":\"\",\"errorMsg\":\"\",\"node\":\"1069e0061c30\",\"data\":[{\"depositTypeId\":0,\"depositTypeName\":\"Offline\",\"isFavorite\":false,\"depositLimitMaximum\":100.0,\"depositLimitMinimum\":50.0}]}")

    given(stubDepositAPI.getDepositOfflineBankAccounts()) ~>
      .just(
        "{\"statusCode\":\"\",\"errorMsg\":\"\",\"node\":\"1069e0061c30\",\"data\":{\"paymentGroupPaymentCards\":{\"1\":{\"paymentTokenId\":\"TokenIDTokenIDTokenI\",\"bankId\":1,\"branch\":\"\",\"accountName\":\"12345678901234567890\",\"accountNumber\":\"test-Acc No.\"}}}}")

    given(stubCommonAPI.getBanks()) ~>
      .just(
        "{\"statusCode\":\"\",\"errorMsg\":\"\",\"node\":\"1069e0061c30\",\"data\":[{\"bankId\":1,\"shortName\":\"ICBC\",\"name\":\"工商银行\"}]}")

    let stubNetworkFactory = mock(ExternalProtocolServiceFactory.self).initialize(dummyHttpClient)

    given(stubNetworkFactory.getDeposit()) ~> DepositAdapter(stubDepositAPI)
    given(stubNetworkFactory.getCash()) ~> CashAdapter(dummyHttpClient)
    given(stubNetworkFactory.getImage()) ~> ImageAdapter(ImageApi(dummyHttpClient))
    given(stubNetworkFactory.getCommon()) ~> CommonAdapter(stubCommonAPI)

    let dummyPlayerUseCase = mock(PlayerDataUseCase.self)
    let dummyLocalStorageRepo = mock(LocalStorageRepository.self)

    given(dummyLocalStorageRepo.getCultureCode()) ~> "zh-cn"

    let applicationFactory: ApplicationFactory = .init(
      playerConfiguration: Injectable.resolveWrapper(PlayerConfiguration.self),
      externalProtocolService: stubNetworkFactory,
      stringServiceFactory: Injectable.resolveWrapper(ExternalStringService.self),
      stringSupporter: Injectable.resolveWrapper(StringSupporter.self))

    return OfflinePaymentViewModel(
      depositService: applicationFactory.deposit(),
      playerUseCase: dummyPlayerUseCase,
      localStorageRepo: dummyLocalStorageRepo)
  }

  override func setUp() {
    injectStubCultureCode(.CN)
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

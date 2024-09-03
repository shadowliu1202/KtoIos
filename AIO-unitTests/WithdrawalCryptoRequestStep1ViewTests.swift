import Combine
import Mockingbird
import sharedbu
import ViewInspector
import XCTest

@testable import ktobet_asia_ios

extension WithdrawalCryptoRequestStep1View.RequestInput: Inspecting { }
extension WithdrawalCryptoRequestStep1ViewModelProtocolMock: ObservableObject { }

final class WithdrawalCryptoRequestStep1ViewTests: XCBaseTestCase {
    private let publisher = PassthroughSubject<Void, Never>()
    private let stubWallet: WithdrawalDto.CryptoWallet =
        .init(
            name: "WalletName",
            walletId: "walletId",
            isDeletable: false,
            verifyStatus: .verified,
            type: .eth,
            network: .erc20,
            address: "walletAdress",
            limitation: .init(
                maxCount: 10,
                maxAmount: "5000".toAccountCurrency(),
                currentCount: 2,
                currentAmount: "100".toAccountCurrency(),
                oneOffMinimumAmount: "20".toAccountCurrency(),
                oneOffMaximumAmount: "600".toAccountCurrency()),
            remainTurnOver: "333".toAccountCurrency())

    private let stubRate = ObjectHelperKt
        .createExchangeRate(
            from: .eth,
            to: .China(),
            cryptoExchangeRate: "2")
  
    private func injectLocalStorageRepository(_ supportLocale: SupportLocale) {
        let stubLocalStorageRepository = mock(LocalStorageRepository.self)
        given(stubLocalStorageRepository.getCultureCode()) ~> supportLocale.cultureCode()
    
        Injectable.register(LocalStorageRepository.self) { _ in
            stubLocalStorageRepository
        }
    }

    private func getViewModelProtocol(supportLocale: SupportLocale) -> WithdrawalCryptoRequestStep1ViewModelProtocolMock {
        let stubViewModel = mock(WithdrawalCryptoRequestStep1ViewModelProtocol.self)
        given(stubViewModel.supportLocale) ~> supportLocale
        given(stubViewModel.requestInfo) ~> .init(
            fiat: "0".toAccountCurrency(),
            crypto: "0".toCryptoCurrency(supportCryptoType: .eth),
            singleCashMinimum: "25",
            singleCashMaximum: "150")
        given(stubViewModel.outPutCryptoAmount) ~> ""
        given(stubViewModel.outPutFiatAmount) ~> ""
        given(stubViewModel.inputErrorText) ~> ""

        return stubViewModel
    }

    private func getWithdrawalCryptoRequestStep1ViewModel() -> WithdrawalCryptoRequestStep1ViewModel {
        let stubService = mock(AbsWithdrawalAppService.self)
        given(stubService.getCryptoCurrencyExchangeRate(walletId: any())) ~> Single<IExchangeRate>
            .just(self.stubRate)
            .asWrapper()
        given(stubService.verifyWithdrawalAmount(walletId: firstArg(any()), verifyAmount: secondArg(any()))) ~>
            Observable<__AmountVerification>
            .just(.valid._bridgeToObjectiveC())
            .asWrapper()
        given(stubService.calculateCryptoFulfillment(walletId: firstArg(any()), exchangeRate: secondArg(any()))) ~>
            Observable<WithdrawalDto.FulfillmentRecipe>
            .just(.init(
                type: .allBalance,
                from: "2".toAccountCurrency(),
                to: "1".toCryptoCurrency(supportCryptoType: .eth),
                exchangeRate: self.stubRate))
            .asWrapper()

        return WithdrawalCryptoRequestStep1ViewModel(
            stubService,
            PlayerConfigurationImpl(SupportLocale.China().cultureCode()))
    }
  
    func test_givenLocaleIsVietnam_whenInCryptoWithdrawalPage_thenDisplayCurrencyRatioNotify_KTO_TC_107() {
        injectLocalStorageRepository(.Vietnam())
        let stubViewModel = getViewModelProtocol(supportLocale: .Vietnam())

        let sut = WithdrawalCryptoRequestStep1View<WithdrawalCryptoRequestStep1ViewModelProtocolMock>.RequestInput()

        let expectation = sut.inspection.inspect { view in
            let text = try? view.find(viewWithId: "currencyRatioNotify")

            XCTAssertNotNil(text)
        }

        ViewHosting.host(
            view: sut.environmentObject(stubViewModel)
                .environment(\.playerLocale, .Vietnam()))

        wait(for: [expectation], timeout: 30)
    }

    func test_givenLocaleIsChina_whenInCryptoWithdrawalPage_thenHideCurrencyRatioNotify_KTO_TC_108() {
        injectLocalStorageRepository(.China())
        let stubViewModel = getViewModelProtocol(supportLocale: .China())

        let sut = WithdrawalCryptoRequestStep1View<WithdrawalCryptoRequestStep1ViewModelProtocolMock>.RequestInput()

        let expectation = sut.inspection.inspect { view in
            let isHide = view.isExist(viewWithId: "currencyRatioNotify")

            XCTAssertTrue(isHide)
        }

        ViewHosting.host(
            view: sut
                .environmentObject(stubViewModel)
                .environment(\.playerLocale, .China()))

        wait(for: [expectation], timeout: 30)
    }

    func test_givenExchangeRate2_whenInputCryptoAmount1_thenOutPutFiatAmount2_177() {
        injectLocalStorageRepository(.China())
    
        let stubViewModel = getWithdrawalCryptoRequestStep1ViewModel()
        stubViewModel.fetchExchangeRate(cryptoWallet: stubWallet)
        stubViewModel.setup()

        let sut = WithdrawalCryptoRequestStep1View<WithdrawalCryptoRequestStep1ViewModel>.RequestInput()

        let expectation1 = sut.inspection.inspect { _ in
            stubViewModel.inputCryptoAmount = "1"
            self.publisher.send()
        }

        let expectation2 = sut.inspection.inspect(onReceive: publisher) { _ in
            let expect = "2"
            let actual = stubViewModel.outPutFiatAmount

            XCTAssertEqual(expect, actual)
        }

        ViewHosting.host(
            view: sut.environmentObject(stubViewModel))

        wait(for: [expectation1, expectation2], timeout: 30)
    }

    func test_givenExchangeRate2_whenInputFiatAmount2_thenOutPutCryptoAmount1_178() {
        injectLocalStorageRepository(.China())
    
        let stubViewModel = getWithdrawalCryptoRequestStep1ViewModel()
        stubViewModel.fetchExchangeRate(cryptoWallet: stubWallet)
        stubViewModel.setup()

        let sut = WithdrawalCryptoRequestStep1View<WithdrawalCryptoRequestStep1ViewModel>.RequestInput()

        let expectation1 = sut.inspection.inspect { _ in
            stubViewModel.inputFiatAmount = "2"
            self.publisher.send()
        }

        let expectation2 = sut.inspection.inspect(onReceive: publisher) { _ in
            let expect = "1"
            let actual = stubViewModel.outPutCryptoAmount

            XCTAssertEqual(expect, actual)
        }

        ViewHosting.host(
            view: sut.environmentObject(stubViewModel))

        wait(for: [expectation1, expectation2], timeout: 30)
    }

    func test_givenExchangeRate2_whenTapAutoFill_thenOutPutCryptoAmount1OutPutFiatAmount2_179() {
        injectLocalStorageRepository(.China())
    
        let stubViewModel = getWithdrawalCryptoRequestStep1ViewModel()
        stubViewModel.setup()

        let sut = WithdrawalCryptoRequestStep1ViewController(viewModel: stubViewModel, wallet: stubWallet)

        sut.tapAutoFill(recipe: .init(
            type: .allBalance,
            from: "2".toAccountCurrency(),
            to: "1".toCryptoCurrency(supportCryptoType: .eth),
            exchangeRate: stubRate))

        let expect1 = "1"
        let actual1 = stubViewModel.outPutCryptoAmount
        XCTAssertEqual(expect1, actual1)

        let expect2 = "2"
        let actual2 = stubViewModel.outPutFiatAmount
        XCTAssertEqual(expect2, actual2)
    }
}

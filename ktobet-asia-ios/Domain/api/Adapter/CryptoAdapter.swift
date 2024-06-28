import Foundation
import sharedbu

class CryptoAdapter: CryptoProtocol {
    private let cryptoAPI: CryptoAPI

    init(_ cryptoAPI: CryptoAPI) {
        self.cryptoAPI = cryptoAPI
    }

    func deleteCryptoBankCards(bankCardId: [String: String]) -> CompletableWrapper {
        cryptoAPI.deleteBankCards(bankCardId)
    }

    func getCryptoBankCard() -> SingleWrapper<ResponsePayload<CryptoBankCardBean>> {
        cryptoAPI.getCryptoBankCard()
    }

    func getCryptoCurrencyExchangeRate(cryptoCurrency: Int32) -> SingleWrapper<ResponseItem<NSString>> {
        cryptoAPI.getCryptoExchangeRate(cryptoCurrency)
    }

    func getWithdrawalEachCryptoLimit() -> SingleWrapper<ResponseList<CryptoLimitBean>> {
        cryptoAPI.getCryptoLimitations()
    }

    func postCryptoBankCard(createBankCardRequest: CryptoBankCardRequest) -> SingleWrapper<ResponseItem<NSString>> {
        cryptoAPI.createCryptoBankCard(request: createBankCardRequest)
    }

    func postCryptoResendOTP(accountType: Int32) -> CompletableWrapper {
        cryptoAPI.resendOTP(accountType)
    }

    func postCryptoSendOTP(verifyRequest: AccountVerifyRequest) -> SingleWrapper<sharedbu.Response<KotlinNothing>> {
        cryptoAPI.sendAccountVerifyOTP(request: verifyRequest)
    }

    func postCryptoVerifyOTP(verifyOtp: OTPVerifyRequest) -> SingleWrapper<sharedbu.Response<KotlinNothing>> {
        cryptoAPI.verifyOTP(request: verifyOtp)
    }

    func getCryptoAvailable() -> SingleWrapper<ResponseItem<KotlinBoolean>> {
        cryptoAPI.getCryptoAvailable()
    }
}

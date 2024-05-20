import Foundation
import sharedbu

class CryptoAdapter: CryptoProtocol {
    private let cryptoAPI: CryptoAPI

    init(_ cryptoAPI: CryptoAPI) {
        self.cryptoAPI = cryptoAPI
    }

    func deleteCryptoBankCards(bankCardId: [String: String]) -> CompletableWrapper {
        cryptoAPI
            .deleteBankCards(bankCardId)
            .asReaktiveCompletable()
    }

    func getCryptoBankCard() -> SingleWrapper<ResponsePayload<CryptoBankCardBean>> {
        cryptoAPI
            .getCryptoBankCard()
            .asReaktiveResponsePayload(serial: CryptoBankCardBean.companion.serializer())
    }

    func getCryptoCurrencyExchangeRate(cryptoCurrency: Int32) -> SingleWrapper<ResponseItem<NSString>> {
        cryptoAPI
            .getCryptoExchangeRate(cryptoCurrency)
            .asReaktiveResponseItem { (number: NSNumber) -> NSString in
                NSString(string: number.stringValue)
            }
    }

    func getWithdrawalEachCryptoLimit() -> SingleWrapper<ResponseList<CryptoLimitBean>> {
        cryptoAPI
            .getCryptoLimitations()
            .asReaktiveResponseList(serial: CryptoLimitBean.companion.serializer())
    }

    func postCryptoBankCard(createBankCardRequest: CryptoBankCardRequest) -> SingleWrapper<ResponseItem<NSString>> {
        cryptoAPI
            .createCryptoBankCard(request: createBankCardRequest)
            .asReaktiveResponseItem()
    }

    func postCryptoResendOTP(accountType: Int32) -> CompletableWrapper {
        cryptoAPI
            .resendOTP(accountType)
            .asReaktiveCompletable()
    }

    func postCryptoSendOTP(verifyRequest: AccountVerifyRequest) -> SingleWrapper<sharedbu.Response<KotlinNothing>> {
        cryptoAPI
            .sendAccountVerifyOTP(request: verifyRequest)
            .asReaktiveResponseNothing()
    }

    func postCryptoVerifyOTP(verifyOtp: OTPVerifyRequest) -> SingleWrapper<sharedbu.Response<KotlinNothing>> {
        cryptoAPI
            .verifyOTP(request: verifyOtp)
            .asReaktiveResponseNothing()
    }
  
    func getCryptoAvailable() -> SingleWrapper<ResponseItem<KotlinBoolean>> {
        cryptoAPI.getCryptoAvailable()
            .asReaktiveResponseItem()
    }
}

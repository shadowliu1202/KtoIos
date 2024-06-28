import Foundation
import RxSwift
import sharedbu

class CryptoAPI {
    private let httpClient: HttpClient

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func deleteBankCards(_ bankCardId: [String: String]) -> CompletableWrapper {
        httpClient.request(
            path: "api/crypto-bank-card",
            method: .delete,
            task: .urlParameters(bankCardId)
        )
        .asReaktiveCompletable()
    }

    func getCryptoBankCard() -> SingleWrapper<ResponsePayload<CryptoBankCardBean>> {
        httpClient.request(
            path: "api/crypto-bank-card",
            method: .get
        )
        .asReaktiveResponsePayload(serial: CryptoBankCardBean.companion.serializer())
    }

    func getCryptoExchangeRate(_ cryptoCurrencyID: Int32) -> SingleWrapper<ResponseItem<NSString>> {
        httpClient.request(
            path: "api/crypto-currency-rate/\(cryptoCurrencyID)",
            method: .get
        )
        .asReaktiveResponseItem { (number: NSNumber) -> NSString in
            NSString(string: number.stringValue)
        }
    }

    func getCryptoLimitations() -> SingleWrapper<ResponseList<CryptoLimitBean>> {
        httpClient.request(
            path: "api/withdrawal/each-crypto-limit",
            method: .get
        )
        .asReaktiveResponseList(serial: CryptoLimitBean.companion.serializer())
    }

    func createCryptoBankCard(request: CryptoBankCardRequest) -> SingleWrapper<ResponseItem<NSString>> {
        let codable = CryptoBankCardRequestCodable(
            cryptoCurrency: request.cryptoCurrency,
            cryptoWalletName: request.cryptoWalletName,
            cryptoWalletAddress: request.cryptoWalletAddress,
            cryptoNetwork: request.cryptoNetwork
        )

        return httpClient.request(
            path: "api/crypto-bank-card",
            method: .post,
            task: .requestJSONEncodable(codable)
        )
        .asReaktiveResponseItem()
    }

    func resendOTP(_ accountType: Int32) -> CompletableWrapper {
        httpClient.request(
            path: "api/crypto-bank-card/resend-otp/\(accountType)",
            method: .post
        )
        .asReaktiveCompletable()
    }

    func sendAccountVerifyOTP(request: AccountVerifyRequest) -> SingleWrapper<sharedbu.Response<KotlinNothing>> {
        let codable = AccountVerifyRequestCodable(
            playerCryptoBankCardId: request.playerCryptoBankCardId,
            accountType: Int(request.accountType)
        )

        return httpClient.request(
            path: "api/crypto-bank-card/send-otp",
            method: .post,
            task: .requestJSONEncodable(codable)
        )
        .asReaktiveResponseNothing()
    }

    func verifyOTP(request: OTPVerifyRequest) -> SingleWrapper<sharedbu.Response<KotlinNothing>> {
        let codable = OTPVerifyRequestCodable(
            verifyCode: request.verifyCode,
            accountType: Int(request.accountType)
        )

        return httpClient.request(
            path: "api/crypto-bank-card/verify-otp",
            method: .post,
            task: .requestJSONEncodable(codable)
        )
        .asReaktiveResponseNothing()
    }

    func getCryptoAvailable() -> SingleWrapper<ResponseItem<KotlinBoolean>> {
        httpClient.request(path: "api/withdrawal/crypto-available", method: .get).asReaktiveResponseItem()
    }
}

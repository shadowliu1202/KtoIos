import Foundation
import RxSwift
import sharedbu

protocol WithdrawalCryptoRequestStep1ViewModelProtocol: AnyObject {
    var supportLocale: SupportLocale { get }
    var cryptoWallet: WithdrawalDto.CryptoWallet? { get }
    var exchangeRateInfo: WithdrawalCryptoRequestDataModel.ExchangeRateInfo? { get }
    var requestInfo: WithdrawalCryptoRequestDataModel.RequestInfo? { get }
    var inputErrorText: String { get }
    var submitButtonDisable: Bool { get }

    var inputFiatAmount: String { set get }
    var outPutFiatAmount: String { get }
    var inputCryptoAmount: String { set get }
    var outPutCryptoAmount: String { get }

    func setup()
    func fetchExchangeRate(cryptoWallet: WithdrawalDto.CryptoWallet)
    func autoFill(recipe: @escaping (WithdrawalDto.FulfillmentRecipe) -> Void)
    func fillAmounts(accountCurrency: AccountCurrency, cryptoAmount: CryptoCurrency)
    func generateRequestConfirmModel() -> WithdrawalCryptoRequestConfirmDataModel.SetupModel?
}

struct WithdrawalCryptoRequestDataModel {
    struct ExchangeRateInfo {
        let icon: UIImage?
        let typeNetwork: String
        let rate: String
        let ratio: String
    }

    struct RequestInfo {
        let fiat: CryptoUIResource
        let crypto: CryptoUIResource
        let singleCashMinimum: String
        let singleCashMaximum: String
    }
}

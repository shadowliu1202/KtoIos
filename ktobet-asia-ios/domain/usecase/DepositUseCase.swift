import Foundation
import SharedBu
import RxSwift

protocol DepositUseCase {
    func getDepositTypes() -> Single<[DepositType]>
    func getPaymentGayway(depositType: DepositType) -> Single<[PaymentGateway]>
    func getDepositRecords() -> Single<[DepositRecord]>
    func getDepositOfflineBankAccounts() -> Single<[OfflineBank]>
    func depositOffline(depositRequest: DepositRequest_, depositTypeId: Int32) -> Single<String>
    func depositOnline(paymentGateway: PaymentGateway, depositRequest: DepositRequest_, provider: PaymentProvider, depositTypeId: Int32, toBank: String) -> Single<String>
    func getDepositRecordDetail(transactionId: String) -> Single<DepositDetail>
    func bindingImageWithDepositRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable
    func getDepositRecords(page: String, dateBegin: Date, dateEnd: Date, status: [TransactionStatus]) -> Single<[DepositRecord]>
    func requestCryptoDeposit(cryptoDepositRequest: CryptoDepositRequest) -> Single<String>
    func requestCryptoDetailUpdate(displayId: String) -> Single<String>
    func getDepositTakingCryptos() -> Single<[TakingCrypto]>
}

class DepositUseCaseImpl: DepositUseCase {
    var depositRepository : DepositRepository!
    
    init(_ depositRepository : DepositRepository) {
        self.depositRepository = depositRepository
    }
    
    func getDepositTypes() -> Single<[DepositType]> {
        return depositRepository.getDepositTypes()
    }
    
    func getDepositRecords() -> Single<[DepositRecord]> {
        return depositRepository.getDepositRecords().map{ $0.filter { !$0.isFee } }
    }
    
    func getDepositOfflineBankAccounts() -> Single<[OfflineBank]> {
        return depositRepository.getDepositOfflineBankAccounts()
    }
    
    func depositOffline(depositRequest: DepositRequest_, depositTypeId: Int32) -> Single<String> {
        return depositRepository.depositOffline(depositRequest: depositRequest, depositTypeId: depositTypeId)
    }
    
    func depositOnline(paymentGateway: PaymentGateway, depositRequest: DepositRequest_, provider: PaymentProvider, depositTypeId: Int32, toBank: String) -> Single<String> {
        return depositRepository.depositOnline(remitter: depositRequest.remitter, paymentTokenId: depositRequest.paymentToken, depositAmount: depositRequest.amount, providerId: provider.id, depositTypeId: depositTypeId, toBank: toBank).map { (transaction) -> String in
            let webParams = paymentGateway.createOnlineDepositLink(host: HttpClient().host, depositRequest: depositRequest, transaction: transaction)
            return webParams.description()
        }
    }
    
    func getPaymentGayway(depositType: DepositType) -> Single<[PaymentGateway]> {
        return depositRepository.getDepositMethods(depositType: depositType.paymentType.id)
    }
    
    func getDepositRecordDetail(transactionId: String) -> Single<DepositDetail> {
        return depositRepository.getDepositRecordDetail(transactionId: transactionId)
    }

    func bindingImageWithDepositRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable {
        return depositRepository.bindingImageWithDepositRecord(displayId: displayId, transactionId: transactionId, portalImages: portalImages)
    }
    
    func getDepositRecords(page: String, dateBegin: Date, dateEnd: Date, status: [TransactionStatus]) -> Single<[DepositRecord]> {
        return depositRepository.getDepositRecords(page: page, dateBegin: dateBegin, dateEnd: dateEnd, status: status).map{ $0.filter { !$0.isFee } }
    }
    
    func requestCryptoDeposit(cryptoDepositRequest: CryptoDepositRequest) -> Single<String> {
        depositRepository.requestCryptoDeposit(cryptoDepositRequest: cryptoDepositRequest)
    }
    
    func requestCryptoDetailUpdate(displayId: String) -> Single<String> {
        return depositRepository.requestCryptoDetailUpdate(displayId: displayId)
    }
    
    //TODO: depositSystem
    func getDepositTakingCryptos() -> Single<[TakingCrypto]> {
        depositRepository.getDepositTakingCryptos().map { $0.map {[weak self] info in
            if let type = self?.supportCryptoType(id: info.cryptoCurrency),
               let promotionString = self?.promotionString(currencyInfo: info) {
                return TakingCrypto(type: type, promotion: promotionString)
            }
            
            return TakingCrypto()
        }}
    }
    
    private func promotionString(currencyInfo: CryptoCurrencyInfo) -> String {
        Localize.string("cps_crypto_currency_deposit_hint", [String(currencyInfo.feePercentage), currencyInfo.maximumFee.toAccountCurrency().formatString()])
    }
    
    private func supportCryptoType(id: Int) -> SupportCryptoType? {
        switch id {
        case 1001:
            return SupportCryptoType.eth
        case 1002:
            return SupportCryptoType.usdt
        case 1003:
            return SupportCryptoType.usdc
        default:
            return nil
        }
    }
}

struct TakingCrypto {
    var type: SupportCryptoType? = nil
    var promotion: String = ""
}

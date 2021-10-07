import Foundation
import SharedBu
import RxSwift

protocol DepositUseCase {
    func getDepositTypes() -> Single<[DepositType]>
    func getPaymentGayway(depositType: DepositType) -> Single<[PaymentGateway]>
    func getDepositRecords() -> Single<[DepositRecord]>
    func getDepositOfflineBankAccounts() -> Single<[FullBankAccount]>
    func depositOffline(depositRequest: DepositRequest, depositTypeId: Int32) -> Single<String>
    
    func depositOnline(paymentGateway: PaymentGateway, depositRequest: DepositRequest_, provider: PaymentProvider, depositTypeId: Int32) -> Single<String>
    func getDepositRecordDetail(transactionId: String) -> Single<DepositDetail>
    func bindingImageWithDepositRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable
    func getDepositRecords(page: String, dateBegin: Date, dateEnd: Date, status: [TransactionStatus]) -> Single<[DepositRecord]>
    func requestCryptoDeposit() -> Single<String>
    func requestCryptoDetailUpdate(displayId: String) -> Single<String>
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
    
    func getDepositOfflineBankAccounts() -> Single<[FullBankAccount]> {
        return depositRepository.getDepositOfflineBankAccounts()
    }
    
    func depositOffline(depositRequest: DepositRequest, depositTypeId: Int32) -> Single<String> {
        return depositRepository.depositOffline(depositRequest: depositRequest, depositTypeId: depositTypeId)
    }
    
    func depositOnline(paymentGateway: PaymentGateway, depositRequest: DepositRequest_, provider: PaymentProvider, depositTypeId: Int32) -> Single<String> {
        return depositRepository.depositOnline(remitter: depositRequest.remitter, paymentTokenId: depositRequest.paymentToken, depositAmount: depositRequest.currency, providerId: provider.id, depositTypeId: depositTypeId).map { (transaction) -> String in
            let webParams = paymentGateway.createWebParameters(depositRequest: depositRequest, transaction: transaction, bankCode: "")
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
    
    func requestCryptoDeposit() -> Single<String> {
        depositRepository.requestCryptoDeposit()
    }
    
    func requestCryptoDetailUpdate(displayId: String) -> Single<String> {
        return depositRepository.requestCryptoDetailUpdate(displayId: displayId)
    }
}

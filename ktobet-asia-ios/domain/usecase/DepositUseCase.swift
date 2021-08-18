import Foundation
import SharedBu
import RxSwift

protocol DepositUseCase {
    func getDepositTypes() -> Single<[DepositRequest.DepositType]>
    func getDepositRecords() -> Single<[DepositRecord]>
    func getDepositOfflineBankAccounts() -> Single<[FullBankAccount]>
    func depositOffline(depositRequest: DepositRequest, depositTypeId: Int32) -> Single<String>
    func getDepositMethods(depositType: Int32) -> Single<[DepositRequest.DepositTypeMethod]>
    func depositOnline(depositRequest: DepositRequest, depositTypeId: Int32) -> Single<String>
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
    
    func getDepositTypes() -> Single<[DepositRequest.DepositType]> {
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
    
    func depositOnline(depositRequest: DepositRequest, depositTypeId: Int32) -> Single<String> {
        return depositRepository.depositOnline(depositRequest: depositRequest, depositTypeId: depositTypeId).map { (transaction) -> String in
            let cashAmount = CashAmount(amount: depositRequest.cashAmount.amount)
            let remitter: DepositRequest.Remitter = depositRequest.remitter
            let url = HttpClient().getHost() + "payment-gateway" + "?" + transaction.queryParameter(payAmount: cashAmount, remiiter: remitter)
            
            return url
        }
    }
    
    func getDepositMethods(depositType: Int32) -> Single<[DepositRequest.DepositTypeMethod]> {
        return depositRepository.getDepositMethods(depositType: depositType)
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

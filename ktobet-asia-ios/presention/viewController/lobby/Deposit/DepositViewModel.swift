import Foundation
import RxSwift
import SharedBu
import RxCocoa

class DepositViewModel: CollectErrorViewModel,
                        ObservableObject {
    
    private let depositService: IDepositAppService
    private let depositUseCase: DepositUseCase
    
    private let disposeBag = DisposeBag()
    
    @Published private (set) var selections: [DepositSelection]? = nil
    
    lazy var payments = getPayments()
        
    //FIXME: depositUseCase 等withdrawal refactor後移除
    init(
        depositService: IDepositAppService,
        depositUseCase: DepositUseCase
    ) {
        self.depositService = depositService
        self.depositUseCase = depositUseCase
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

// MARK: - API

extension DepositViewModel {
    
    func fetchMethods() {
        payments
            .map { [unowned self] in
                self.buildSelections($0)
            }
            .catchAndReturn([])
            .subscribe(onNext: { [unowned self] in
                self.selections = $0
            })
            .disposed(by: disposeBag)
    }
    
    func getPayments() -> Observable<PaymentsDTO> {
        Observable
            .from(depositService.getPayments())
            .compose(applyObservableErrorHandle())
    }
    
    func requestCryptoDepositUpdate(displayId: String) -> Single<String> {
        depositUseCase.requestCryptoDetailUpdate(displayId: displayId)
    }
}

// MARK: - Data Handle

extension DepositViewModel {
    
    func buildSelections(_ payments: PaymentsDTO) -> [DepositSelection] {
        var list: [DepositSelection] = []
        
        if let offline = payments.offline {
            list.append(OfflinePayment(offline))
        }
        
        let online = payments.fiat.compactMap { OnlinePayment($0) }
        list.append(contentsOf: online)
        
        if let crypto = payments.crypto {
            list.append(CryptoPayment(crypto))
        }
        
        if let cryptoMarket = payments.cryptoMarket {
            list.append(CryptoMarket(cryptoMarket))
        }
        
        return list
    }
}

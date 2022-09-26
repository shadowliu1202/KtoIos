import Foundation
import RxSwift
import RxCocoa
import SharedBu

 protocol CryptoGuideVNDViewModel: ObservableObject {
     var exchanges: [CryptoMarketExchange]? { get set }
     
     func getCryptoGuidance()
 }

class CryptoGuideVNDViewModelImpl: CryptoGuideVNDViewModel {
    private var localizationPolicyUseCase: LocalizationPolicyUseCase!
    
    @Published var exchanges: [CryptoMarketExchange]? = nil
    let disposeBag = DisposeBag()
    
    init(localizationPolicyUseCase: LocalizationPolicyUseCase) {
        self.localizationPolicyUseCase = localizationPolicyUseCase
    }
    
    func getCryptoGuidance() {
        if exchanges == nil {
            localizationPolicyUseCase.getCryptoGuidance().subscribe(onSuccess: { [weak self] (data: [CryptoDepositGuidance]) in
                self?.exchanges = data.map({ CryptoMarketExchange($0.title, $0.links.map({Guide(name: $0.title, link: $0.link)}))})
            }).disposed(by: disposeBag)
        }
    }
}

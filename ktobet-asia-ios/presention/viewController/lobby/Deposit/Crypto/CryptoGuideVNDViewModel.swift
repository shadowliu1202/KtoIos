import Foundation
import RxSwift
import RxCocoa
import SharedBu

 protocol CryptoGuideVNDViewModel: ObservableObject {
     var guidances: [CryptoDepositGuidance] { get }
     
     func getCryptoGuidance()
 }

class CryptoGuideVNDViewModelImpl: CryptoGuideVNDViewModel {
    @Published private(set) var guidances: [CryptoDepositGuidance] = []
    
    private let localizationPolicyUseCase: LocalizationPolicyUseCase
    private let disposeBag = DisposeBag()
    
    init(localizationPolicyUseCase: LocalizationPolicyUseCase) {
        self.localizationPolicyUseCase = localizationPolicyUseCase
    }
    
    func getCryptoGuidance() {
        if guidances.isEmpty {
            localizationPolicyUseCase.getCryptoGuidance()
                .subscribe(onSuccess: { cryptoDepositGuidances in
                    self.guidances = cryptoDepositGuidances
                })
                .disposed(by: disposeBag)
        }
    }
}

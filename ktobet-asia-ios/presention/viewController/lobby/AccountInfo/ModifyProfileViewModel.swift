import Foundation
import RxSwift
import RxCocoa
import SharedBu

class ModifyProfileViewModel {
    private var playerDataUseCase: PlayerDataUseCase!
    lazy var isAffiliateMember = playerDataUseCase.isAffiliateMember()
    
    init(_ playerDataUseCase: PlayerDataUseCase) {
        self.playerDataUseCase = playerDataUseCase
    }
}

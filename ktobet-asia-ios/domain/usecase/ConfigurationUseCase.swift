import Foundation
import SharedBu
import RxSwift

protocol ConfigurationUseCase {
    func defaultProduct()->Single<ProductType>
    func saveDefaultProduct(_ productType: ProductType)->Completable
    func getPlayerInfo()->Single<Player>
}

class ConfigurationUseCaseImpl : ConfigurationUseCase{
    
    var playerRepo : PlayerRepository!
    
    init(_ playerRepo : PlayerRepository) {
        self.playerRepo = playerRepo
    }
    
    func defaultProduct()->Single<ProductType>{
        return playerRepo.getDefaultProduct()
    }
    
    func saveDefaultProduct(_ productType: ProductType)->Completable{
        return playerRepo.saveDefaultProduct(productType)
    }
    
    func getPlayerInfo()->Single<Player>{
        return playerRepo.loadPlayer()
    }
}

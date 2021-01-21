//
//  IConfigurationUseCase.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/3.
//

import Foundation
import share_bu
import RxSwift

protocol IConfigurationUseCase {
    func defaultProduct()->Single<ProductType>
    func saveDefaultProduct(_ productType: ProductType)->Completable
    func getPlayerInfo()->Single<Player>
}

class IConfigurationUseCaseImpl : IConfigurationUseCase{
    
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

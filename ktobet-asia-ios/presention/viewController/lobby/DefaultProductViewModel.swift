//
//  DefaultSettingViewModel.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/3.
//

import UIKit
import RxSwift
import RxCocoa
import share_bu

class DefaultProductViewModel {
    
    private var disposeBag = DisposeBag()
    private var usecaseConfig : IConfigurationUseCase!

    init(_ usecaseConfig : IConfigurationUseCase) {
        self.usecaseConfig = usecaseConfig
    }
    
    func saveDefaultProduct(_ type : ProductType)-> Completable{
        return usecaseConfig.saveDefaultProduct(type)
    }
    
    func getPlayerInfo()-> Single<Player>{
        return usecaseConfig.getPlayerInfo()
    }
}

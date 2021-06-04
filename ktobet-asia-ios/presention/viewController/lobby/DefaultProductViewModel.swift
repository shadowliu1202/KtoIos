//
//  DefaultSettingViewModel.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/3.
//

import UIKit
import RxSwift
import RxCocoa
import SharedBu

class DefaultProductViewModel {
    
    private var disposeBag = DisposeBag()
    private var usecaseConfig : ConfigurationUseCase!

    init(_ usecaseConfig : ConfigurationUseCase) {
        self.usecaseConfig = usecaseConfig
    }
    
    func saveDefaultProduct(_ type : ProductType)-> Completable{
        return usecaseConfig.saveDefaultProduct(type)
    }
    
    func getPlayerInfo()-> Single<Player>{
        return usecaseConfig.getPlayerInfo()
    }
}

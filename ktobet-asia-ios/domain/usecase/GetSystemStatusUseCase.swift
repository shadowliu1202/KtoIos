//
//  GetSystemStatusUseCase.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/12/15.
//

import Foundation
import RxSwift

protocol GetSystemStatusUseCase {
    func getOtpStatus()-> Single<OtpStatus>
}


class GetSystemStatusUseCaseImpl : GetSystemStatusUseCase {
    
    var repoSystem : SystemRepository!
    
    init(_ repoSystem : SystemRepository) {
        self.repoSystem = repoSystem
    }
    
    func getOtpStatus() -> Single<OtpStatus> {
        repoSystem.getPortalMaintenance()
    }
}

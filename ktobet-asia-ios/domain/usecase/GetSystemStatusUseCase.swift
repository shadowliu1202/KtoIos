//
//  GetSystemStatusUseCase.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/12/15.
//

import Foundation
import RxSwift
import SharedBu

protocol GetSystemStatusUseCase {
    func getOtpStatus()-> Single<OtpStatus>
    func observePortalMaintenanceState() -> Single<MaintenanceStatus>
}


class GetSystemStatusUseCaseImpl : GetSystemStatusUseCase {
    
    var repoSystem : SystemRepository!
    
    init(_ repoSystem : SystemRepository) {
        self.repoSystem = repoSystem
    }
    
    func getOtpStatus() -> Single<OtpStatus> {
        repoSystem.getPortalMaintenance()
    }
    
    func observePortalMaintenanceState() -> Single<MaintenanceStatus> {
        repoSystem.observePortalMaintenanceState()
    }
    
}

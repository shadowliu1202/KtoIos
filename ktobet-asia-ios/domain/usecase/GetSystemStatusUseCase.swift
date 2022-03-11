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
    func observePortalMaintenanceState() -> Observable<MaintenanceStatus>
    func getCustomerServiceEmail() -> Single<String>
    func refreshMaintenanceState()
    func getYearOfCopyRight() -> Single<String>
}


class GetSystemStatusUseCaseImpl: GetSystemStatusUseCase {
    var repoSystem: SystemRepository!
    
    init(_ repoSystem: SystemRepository) {
        self.repoSystem = repoSystem
    }
    
    func getOtpStatus() -> Single<OtpStatus> {
        repoSystem.getPortalMaintenance()
    }
    
    func observePortalMaintenanceState() -> Observable<MaintenanceStatus> {
        repoSystem.observePortalMaintenanceState()
    }
    
    func getCustomerServiceEmail() -> Single<String> {
        repoSystem.getCustomerService()
    }
    
    func refreshMaintenanceState() {
        repoSystem.refreshPortalMaintenanceState()
    }
    
    func getYearOfCopyRight() -> Single<String> {
        repoSystem.getYearOfCopyRight()
    }
}

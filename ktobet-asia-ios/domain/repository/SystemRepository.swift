//
//  SystemRepository.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/12/15.
//

import Foundation
import RxSwift
import SharedBu


protocol SystemRepository {
    func getPortalMaintenance() -> Single<OtpStatus>
    func observePortalMaintenanceState() -> Single<MaintenanceStatus>
}

class SystemRepositoryImpl : SystemRepository{
    
    private var portalApi : PortalApi
    private var productStatusChange = BehaviorSubject<MaintenanceStatus>(value: MaintenanceStatus.init())
    
    init(_ portalApi : PortalApi) {
        self.portalApi = portalApi
    }
    
    func getPortalMaintenance()->Single<OtpStatus>{
        return portalApi
            .getPortalMaintenance()
            .map { (response) -> OtpStatus in
                return response.data ?? OtpStatus(isMailActive: false, isSmsActive: false)
            }
    }
    
    func observePortalMaintenanceState() -> Single<MaintenanceStatus> {
        portalApi.getProductStatus().map { $0.data?.toMaintenanceStatus() ?? MaintenanceStatus.init()}
        .do(onSuccess: { self.productStatusChange.onNext($0) })
    }
}

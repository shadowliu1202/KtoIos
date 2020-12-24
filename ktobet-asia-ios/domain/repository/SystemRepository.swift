//
//  SystemRepository.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/12/15.
//

import Foundation
import RxSwift

protocol SystemRepository {
    func getPortalMaintenance()->Single<OtpStatus>
}

class SystemRepositoryImpl : SystemRepository{
    
    private var portalApi : PortalApi
    
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
}

//
//  SystemRepository.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/12/15.
//

import Foundation
import RxSwift
import SharedBu
import Moya

protocol SystemRepository {
    func getPortalMaintenance() -> Single<OtpStatus>
    func observePortalMaintenanceState() -> Observable<MaintenanceStatus>
    func getCustomerService() -> Single<String>
    func refreshPortalMaintenanceState()
}

class SystemRepositoryImpl : SystemRepository{
    let csMailCookieName = "csm"
    let maintenanceTimeCookieName = "dist"
    private var portalApi : PortalApi
    private var productStatusChange = BehaviorSubject<MaintenanceStatus>(value: MaintenanceStatus.init())
    private var maintenanceStatus: Observable<MaintenanceStatus>!
    private let portalMaintenanceStateRefresh = PublishSubject<()>()

    init(_ portalApi : PortalApi) {
        self.portalApi = portalApi
        
        maintenanceStatus = portalMaintenanceStateRefresh.startWith(()).flatMap{[unowned self] in
            self.updateMaintenanceStatus().asObservable()
        }
    }
    
    func getPortalMaintenance()->Single<OtpStatus>{
        return portalApi
            .getPortalMaintenance()
            .map { (response) -> OtpStatus in
                return response.data ?? OtpStatus(isMailActive: false, isSmsActive: false)
            }
    }
    
    func observePortalMaintenanceState() -> Observable<MaintenanceStatus> {
        maintenanceStatus.concat(productStatusChange.asObservable())
    }
    
    func refreshPortalMaintenanceState() {
        portalMaintenanceStateRefresh.onNext(())
    }
    
    func getCustomerService() -> Single<String> {
        portalApi.getCustomerServiceEmail().map{ $0.data ?? "" }
        .catchError {[weak self] error in
            guard let self = self else { return Single.error(error)}
            if error.isMaintenance() {
                return Single.just(self.maintainCsEmail())
            } else {
                return Single.error(error)
            }
        }
    }
    
    private func updateMaintenanceStatus() -> Single<MaintenanceStatus> {
        portalApi.getProductStatus().map { $0.data?.toMaintenanceStatus() ?? MaintenanceStatus.init() }
            .do(onSuccess: { self.productStatusChange.onNext($0) })
            .catchError({ [weak self] error in
            guard let self = self else { return Single.error(error) }
            if error.isMaintenance() {
                return Single.just(MaintenanceStatus.AllPortal(remainingSeconds: Int32(self.getMaintenanceTimeFromCookies())))
            } else {
                return Single.error(error)
            }
        })
    }
    
    private func getMaintenanceTimeFromCookies() -> Int {
        let str = (HttpClient().getCookies().first(where: { $0.name == maintenanceTimeCookieName })?.value) ?? "0"
        return Int(ceil(Double(str) ?? 0))
    }
    
    private func maintainCsEmail() -> String {
        HttpClient().getCookies().first(where: { $0.name == csMailCookieName })?.value ?? ""
    }
}


extension Error {
    func isMaintenance() -> Bool {
        if let error = (self as? MoyaError) {
            switch error {
            case .statusCode(let response):
                return response.statusCode == 410
            default:
                return false
            }
        }

        return false
    }
}

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
    func observePortalMaintenanceState() -> Observable<MaintenanceStatus>
    func getCustomerService() -> Single<String>
    func refreshPortalMaintenanceState()
    func getYearOfCopyRight() -> Single<String>
}

class SystemRepositoryImpl : SystemRepository{
    let csMailCookieName = "csm"
    let maintenanceTimeCookieName = "dist"
    let workaroundDefaultTime: Int32 = 359999
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
                return Single.just(MaintenanceStatus.AllPortal(remainingSeconds: self.getMaintenanceTimeFromCookies()))
            } else {
                return Single.error(error)
            }
        })
    }
    
    private func getMaintenanceTimeFromCookies() -> Int32 {
        if let str = HttpClient().getCookies().first(where: { $0.name == maintenanceTimeCookieName })?.value, let doubleValue = Double(str) {
            return Int32(ceil(doubleValue))
        }
        return workaroundDefaultTime
    }
    
    private func maintainCsEmail() -> String {
        HttpClient().getCookies().first(where: { $0.name == csMailCookieName })?.value ?? ""
    }
    
    func getYearOfCopyRight() -> Single<String> {
        portalApi.getYearOfCopyRight().map({$0.data})
    }
}

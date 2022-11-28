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

class SystemRepositoryImpl: SystemRepository{

    private let portalMaintenanceStateRefresh = PublishSubject<()>()
    private let portalApi : PortalApi
    private let httpClient: HttpClient
    private let productStatusChange = BehaviorSubject<MaintenanceStatus>(value: MaintenanceStatus.AllPortal(duration: nil))
  
    private var maintenanceStatus: Observable<MaintenanceStatus>!

    let csMailCookieName = "csm"
    let maintenanceTimeCookieName = "dist"

    init(_ portalApi : PortalApi, httpClient: HttpClient) {
        self.portalApi = portalApi
        self.httpClient = httpClient
        
        maintenanceStatus = portalMaintenanceStateRefresh
            .startWith(())
            .flatMap{ [unowned self] in
                self.updateMaintenanceStatus().asObservable()
            }
    }
    
    func getPortalMaintenance() -> Single<OtpStatus>{
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
        portalApi.getCustomerServiceEmail()
            .map{ $0.data ?? "" }
            .catch({ [weak self] error in
                guard let self = self else { return Single.error(error)}
                if error.isMaintenance() {
                    return Single.just(self.maintainCsEmail())
                } else {
                    return Single.error(error)
                }
            })
    }
    
    // FIXME: use concat in wrong way.
    private func updateMaintenanceStatus() -> Single<MaintenanceStatus> {
        portalApi.getProductStatus()
            .map { try $0.data?.toMaintenanceStatus() ?? MaintenanceStatus.AllPortal(duration: nil) }
            .do(onSuccess: { self.productStatusChange.onNext($0) })
            .catch({ [weak self] error in
                guard let self = self else { return Single.error(error) }
                if error.isMaintenance() {
                    self.productStatusChange.onNext(MaintenanceStatus.AllPortal(remainingSeconds: self.getMaintenanceTimeFromCookies()))
                } else {
                    return Single.error(error)
                }
                
                return Single.just(MaintenanceStatus.AllPortal(remainingSeconds: self.getMaintenanceTimeFromCookies()))
            })
    }
    
    private func getMaintenanceTimeFromCookies() -> KotlinInt? {
        if let str = httpClient.getCookies().first(where: { $0.name == maintenanceTimeCookieName })?.value, let doubleValue = Double(str) {
            return KotlinInt.init(value: Int32(ceil(doubleValue)))
        }
        return nil
    }
    
    private func maintainCsEmail() -> String {
        httpClient.getCookies().first(where: { $0.name == csMailCookieName })?.value ?? ""
    }
    
    func getYearOfCopyRight() -> Single<String> {
        portalApi.getYearOfCopyRight().map({$0.data})
    }
}

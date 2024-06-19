import Foundation
import RxSwift
import sharedbu

protocol SystemRepository {
    func isOTPBlocked() -> Single<OtpStatus>
    func isOTPServiceAvaliable() -> Single<OtpStatus>
    func observePortalMaintenanceState() -> Observable<MaintenanceStatus>
    func fetchCustomerServiceEmail() -> Single<String>
    func refreshPortalMaintenanceState()
    func fetchCopyRight() -> Single<String>
    func fetchMaintenanceStatus() -> Single<MaintenanceStatus>
}

class SystemRepositoryImpl: SystemRepository {
    private let portalMaintenanceStateRefresh = PublishSubject<Void>()
    private let portalApi: PortalApi
    private let httpClient: HttpClient
    private let cookieManager: CookieManager
    private let productStatusChange = BehaviorSubject<MaintenanceStatus>(value: MaintenanceStatus.AllPortal(duration: nil))

    private var maintenanceStatus: Observable<MaintenanceStatus>!

    let csMailCookieName = "csm"
    let maintenanceTimeCookieName = "dist"

    init(_ portalApi: PortalApi, _ httpClient: HttpClient, _ cookieManager: CookieManager) {
        self.portalApi = portalApi
        self.httpClient = httpClient
        self.cookieManager = cookieManager

        maintenanceStatus = portalMaintenanceStateRefresh
            .startWith(())
            .flatMap { [unowned self] in
                self.updateMaintenanceStatus().asObservable()
            }
    }

    func isOTPBlocked() -> Single<OtpStatus> {
        portalApi
            .getPortalMaintenance()
            .map { response -> OtpStatus in
                response.data ?? OtpStatus(isMailActive: false, isSmsActive: false)
            }
    }
    
    func isOTPServiceAvaliable() -> RxSwift.Single<OtpStatus> {
        portalApi
            .getOtpMaintenance()
            .map { response -> OtpStatus in
                response.data ?? OtpStatus(isMailActive: false, isSmsActive: false)
            }
    }

    func observePortalMaintenanceState() -> Observable<MaintenanceStatus> {
        maintenanceStatus.concat(productStatusChange.asObservable())
    }

    func refreshPortalMaintenanceState() {
        portalMaintenanceStateRefresh.onNext(())
    }

    func fetchCustomerServiceEmail() -> Single<String> {
        portalApi.getCustomerServiceEmail()
            .map { $0.data ?? "" }
            .catch { [weak self] error in
                guard let self else { return Single.error(error) }
                if error.isMaintenance() {
                    return Single.just(self.maintainCsEmail())
                }
                else {
                    return Single.error(error)
                }
            }
    }

    func fetchMaintenanceStatus() -> Single<MaintenanceStatus> {
        portalApi.getProductStatus()
            .map {
                try $0.data?.toMaintenanceStatus() ?? MaintenanceStatus.AllPortal(duration: nil)
            }
            .catch { [weak self] error in
                guard
                    let self,
                    error.isMaintenance()
                else {
                    return Single.error(error)
                }

                return Observable
                    .just(MaintenanceStatus.AllPortal(remainingSeconds: self.getMaintenanceTimeFromCookies()))
                    .asSingle()
            }
    }

    // FIXME: use concat in wrong way.
    private func updateMaintenanceStatus() -> Single<MaintenanceStatus> {
        portalApi.getProductStatus()
            .map { try $0.data?.toMaintenanceStatus() ?? MaintenanceStatus.AllPortal(duration: nil) }
            .do(onSuccess: { self.productStatusChange.onNext($0) })
            .catch { [weak self] error in
                guard let self else { return Single.error(error) }
                if error.isMaintenance() {
                    self.productStatusChange
                        .onNext(MaintenanceStatus.AllPortal(remainingSeconds: self.getMaintenanceTimeFromCookies()))
                }
                else {
                    return Single.error(error)
                }

                return Single.just(MaintenanceStatus.AllPortal(remainingSeconds: self.getMaintenanceTimeFromCookies()))
            }
    }

    private func getMaintenanceTimeFromCookies() -> KotlinInt? {
        if
            let str = cookieManager.cookies.first(where: { $0.name == maintenanceTimeCookieName })?.value,
            let doubleValue = Double(str)
        {
            return KotlinInt(value: Int32(ceil(doubleValue)))
        }
        return nil
    }

    private func maintainCsEmail() -> String {
        cookieManager.cookies.first(where: { $0.name == csMailCookieName })?.value ?? ""
    }

    func fetchCopyRight() -> Single<String> {
        portalApi.getYearOfCopyRight().map { $0.data }
    }
}

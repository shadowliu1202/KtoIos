import Mockingbird
import SharedBu
import RxSwift

@testable import ktobet_asia_ios_qat

class DepositGatewayViewControllerTest: XCTestCase {
    
    private let stubOnlinePayment = mock(PaymentsDTO.Online.self)
    private let stubLocalRepo = mock(LocalStorageRepository.self)
    
    private var vc: DepositGatewayViewController!
    
    override func setUp() {
        injectStubPlayerLoginStatus()
        
        let storyboard = UIStoryboard(name: "Deposit", bundle: nil)
        vc = (storyboard.instantiateViewController(identifier: "DepositGatewayViewController") as! DepositGatewayViewController)
    }
    
    override func tearDown() {
        clearStubs(on: stubOnlinePayment)
        clearStubs(on: stubLocalRepo)
        Injection.shared.registerAllDependency()
    }
    
    func test_givenVietnameseUser_whenNavigationPopBack_thenAlertMessageContainsPaymentName() {
        given(stubOnlinePayment.hint) ~> ""
        given(stubOnlinePayment.identity) ~> "9"
        given(stubOnlinePayment.name) ~> "Thẻ Cào Điện Thoại"
        given(stubOnlinePayment.isRecommend) ~> false
        
        given(stubLocalRepo.getCultureCode()) ~> Language.VN.rawValue
        given(stubLocalRepo.getSupportLocale()) ~> .Vietnam()
        
        let mockAlert = mock(AlertProtocol.self)
        
        vc.localStorageRepo = stubLocalRepo
        vc.alert = mockAlert
        vc.paymentIdentity = ""
        vc.depositType = OnlinePayment(stubOnlinePayment)
        vc.loadViewIfNeeded()
        
        vc.back()
        
        verify(
            mockAlert.show(
                any(),
                any(
                    String.self,
                    where: { $0.contains("Thẻ Cào Điện Thoại")}
                ),
                confirm: any(),
                confirmText: any(),
                cancel: any(),
                cancelText: any(),
                tintColor: any()
            )
        ).wasCalled()
    }
    
    func test_givenChinaUser_whenNavigationPopback_thenAlertOnlinePaymentTerminate() {
        given(stubOnlinePayment.hint) ~> ""
        given(stubOnlinePayment.identity) ~> "9"
        given(stubOnlinePayment.name) ~> "Thẻ Cào Điện Thoại"
        given(stubOnlinePayment.isRecommend) ~> false
        
        given(stubLocalRepo.getCultureCode()) ~> Language.CN.rawValue
        given(stubLocalRepo.getSupportLocale()) ~> .China()
        
        let mockAlert = mock(AlertProtocol.self)
        
        vc.localStorageRepo = stubLocalRepo
        vc.alert = mockAlert
        vc.paymentIdentity = ""
        vc.depositType = OnlinePayment(stubOnlinePayment)
        vc.loadViewIfNeeded()
        
        vc.back()
        
        verify(
            mockAlert.show(
                any(),
                any(
                    String.self,
                    where: { $0.contains("在线充值将中断并结束。")}
                ),
                confirm: any(),
                confirmText: any(),
                cancel: any(),
                cancelText: any(),
                tintColor: any()
            )
        ).wasCalled()
    }
}

import Mockingbird
import SharedBu
import RxSwift

@testable import ktobet_asia_ios_qat

class DepositGatewayViewControllerTest: XCTestCase {
    private var vc: DepositGatewayViewController!
    private let stubOnlinePayment = mock(PaymentsDTO.Online.self)
    
    override func setUp() {
        injectStubPlayerLoginStatus()
        
        let storyboard = UIStoryboard(name: "Deposit", bundle: nil)
        vc = (storyboard.instantiateViewController(identifier: "DepositGatewayViewController") as! DepositGatewayViewController)
    }
    
    override func tearDown() {
        clearStubs(on: stubOnlinePayment)
    }
    
    func test_givenVietnameseUser_whenNavigationPopBack_thenAlertMessageContainsPaymentName() {
        given(stubOnlinePayment.hint) ~> ""
        given(stubOnlinePayment.identity) ~> "9"
        given(stubOnlinePayment.name) ~> "Thẻ Cào Điện Thoại"
        given(stubOnlinePayment.isRecommend) ~> false
        
        let stubPlayerLocaleConfiguration = FakePlayerLocaleConfiguration(stubSupportLocale: .Vietnam.init())
        let mockAlert = mock(AlertProtocol.self)
        
        vc.localStorageRepo = stubPlayerLocaleConfiguration
        vc.alert = mockAlert
        vc.paymentIdentity = ""
        vc.depositType = OnlinePayment(stubOnlinePayment)
        vc.loadViewIfNeeded()
        
        vc.back()
        
        verify(mockAlert.show(any(), any(String.self, where: { $0.contains("Thẻ Cào Điện Thoại")}), confirm: any(), confirmText: any(), cancel: any(), cancelText: any(), tintColor: any())).wasCalled()
    }
    
    func test_givenChinaUser_whenNavigationPopback_thenAlertOnlinePaymentTerminate() {
        given(stubOnlinePayment.hint) ~> ""
        given(stubOnlinePayment.identity) ~> "9"
        given(stubOnlinePayment.name) ~> "Thẻ Cào Điện Thoại"
        given(stubOnlinePayment.isRecommend) ~> false
        
        let stubPlayerLocaleConfiguration = FakePlayerLocaleConfiguration(stubSupportLocale: .China.init())
        let mockAlert = mock(AlertProtocol.self)
        
        vc.localStorageRepo = stubPlayerLocaleConfiguration
        vc.alert = mockAlert
        vc.paymentIdentity = ""
        vc.depositType = OnlinePayment(stubOnlinePayment)
        vc.loadViewIfNeeded()
        
        vc.back()
        
        verify(mockAlert.show(any(), any(String.self, where: { $0.contains("在线充值将中断并结束。")}), confirm: any(), confirmText: any(), cancel: any(), cancelText: any(), tintColor: any())).wasCalled()
    }
}

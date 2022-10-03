import XCTest
import SwiftUI
import ViewInspector
import SharedBu
import RxSwift
import Combine
@testable import ktobet_asia_ios_qat

class OnlinePaymentViewTest: XCTestCase {
    private let onlinePayment = PaymentsDTO.Online.init(identity: "24", name: "数字人民币", hint: "", isRecommend: false, beneficiaries: RxSwift.Single<NSArray>.just([PaymentsDTO.Gateway(identity: "70", name: "JinYi_Digital", cash: CashType.Input.init(limitation: AmountRange.init(min: FiatFactory.shared.create(supportLocale: SupportLocale.China.init(), amount_: "200"), max: FiatFactory.shared.create(supportLocale: SupportLocale.China.init(), amount_: "2000")), isFloatAllowed: false), remitType: PaymentsDTO.RemitType.normal, remitBank: [], verifier: CompositeVerification<RemitApplication, PaymentError>(), hint: "", isAccountNumberDenied: true, isInstructionDisplayed: true)] as NSArray).asNSArray())
    
    private let gateway = PaymentsDTO.Gateway(identity: "70", name: "JinYi_Digital", cash: CashType.Input.init(limitation: AmountRange.init(min: FiatFactory.shared.create(supportLocale: SupportLocale.China.init(), amount_: "200"), max: FiatFactory.shared.create(supportLocale: SupportLocale.China.init(), amount_: "2000")), isFloatAllowed: false), remitType: PaymentsDTO.RemitType.normal, remitBank: [], verifier: CompositeVerification<RemitApplication, PaymentError>(), hint: "", isAccountNumberDenied: true, isInstructionDisplayed: true)
    
    private var mockViewModel: MockOnlinePaymentViewModel!

    override func setUpWithError() throws {
        mockViewModel = MockOnlinePaymentViewModel(selectedOnlinePayment: onlinePayment)
    }
    
    func test_Remit_Button_Enable_When_No_Remittance_Error_Occurred() {
        mockViewModel.applicationErrors = []
        
        let sut = OnlinePaymentView(viewModel: self.mockViewModel, selectedGateway: gateway, amount: "200")
        
        let exp = sut.inspection.inspect { view in
            let remitButton = try view.find(viewWithId: "RemitButton").button()
            
            XCTAssertFalse(remitButton.isDisabled())
        }
        
        ViewHosting.host(view: sut)
        wait(for: [exp], timeout: 10)
    }
    
    func test_Remit_Button_Disable_When_Remittance_Out_Of_Limit_Range() {
        mockViewModel.applicationErrors = [PaymentError.RemittanceOutOfRange()]
        
        let sut = OnlinePaymentView(viewModel: self.mockViewModel, selectedGateway: gateway, amount: "200")
        
        let exp = sut.inspection.inspect { view in
            let remitButton = try view.find(viewWithId: "RemitButton").button()
            
            XCTAssertTrue(remitButton.isDisabled())
        }
        
        ViewHosting.host(view: sut)
        wait(for: [exp], timeout: 10)
    }
    
    func test_Remit_Button_Disable_When_Remittance_is_Empty() {
        mockViewModel.applicationErrors = [PaymentError.RemittanceIsEmpty()]
        
        let sut = OnlinePaymentView(viewModel: self.mockViewModel, selectedGateway: gateway, amount: "200")
        
        let exp = sut.inspection.inspect { view in
            let remitButton = try view.find(viewWithId: "RemitButton").button()
            
            XCTAssertTrue(remitButton.isDisabled())
        }
        
        ViewHosting.host(view: sut)
        wait(for: [exp], timeout: 10)
    }
    
    func test_Error_Text_When_Remittance_Error_Occurred() {
        mockViewModel.applicationErrors = [PaymentError.RemittanceOutOfRange()]
        
        let sut = OnlinePaymentView(viewModel: self.mockViewModel, selectedGateway: gateway)
        
        let exp = sut.inspection.inspect { view in
            let textField = try view.find(viewWithId: "RemittanceInputTextField")
            let errorText = try textField.find(viewWithId: "ErrorHint").text().string()

            XCTAssertFalse(errorText.isEmpty)
        }
        
        ViewHosting.host(view: sut)
        wait(for: [exp], timeout: 10)
    }
    
    func test_Error_Text_When_No_Remittance_Error_Occurred() {
        mockViewModel.applicationErrors = []
        
        let sut = OnlinePaymentView(viewModel: self.mockViewModel, selectedGateway: gateway)
        
        let exp = sut.inspection.inspect { view in
            let textField = try view.find(viewWithId: "RemittanceInputTextField")
            let errorText = try? textField.find(viewWithId: "ErrorHint").text()

            XCTAssertNil(errorText)
        }
        
        ViewHosting.host(view: sut)
        wait(for: [exp], timeout: 10)
    }
    
    func test_Remit_Button_On_Click() {
        mockViewModel.applicationErrors = []
        
        let sut = OnlinePaymentView(viewModel: self.mockViewModel, selectedGateway: gateway, amount: "200")
        
        let exp = sut.inspection.inspect { view in
            let remitButton = try view.find(viewWithId: "RemitButton").button()
            XCTAssertFalse(remitButton.isDisabled())
            
            XCTAssertFalse(self.mockViewModel.isSubmit)
            try remitButton.tap()
            XCTAssertTrue(self.mockViewModel.isSubmit)
        }
        
        ViewHosting.host(view: sut)
        wait(for: [exp], timeout: 10)
    }
}

extension OnlinePaymentView: UITestable {}

class MockOnlinePaymentViewModel: KTOViewModel, OnlineDepositViewModel, ObservableObject {
    @Published var applicationErrors: [PaymentError] = []

    @Published private(set) var gateways: [PaymentsDTO.Gateway] = []
    
    var isSubmit = false
    
    let selectedOnlinePayment: PaymentsDTO.Online

    private(set) var remitApplication: OnlineRemitApplication!
    
    private let disposeBag = DisposeBag()
    
    init(selectedOnlinePayment: PaymentsDTO.Online) {
        self.selectedOnlinePayment = selectedOnlinePayment
    }
    
    func getRemitterName() -> RxSwift.Single<String> {
        RxSwift.Single<String>.just("")
    }
    
    func verifyRemitInput(gateway: PaymentsDTO.Gateway?, remitterName: String, remittance: String) {
        //do nothing.
    }
    
    func submitRemittance(gatewayIdentity: String, remitterName: String, remittance: String) -> RxSwift.Single<CommonDTO.WebPath> {
        isSubmit = true
        return RxSwift.Single.just(CommonDTO.WebPath.init(path: ""))
    }
}

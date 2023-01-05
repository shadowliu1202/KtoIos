import XCTest
import SwiftUI
import ViewInspector
import SharedBu
import RxSwift
import Combine
import Mockingbird

@testable import ktobet_asia_ios_qat

extension OnlinePaymentView: Inspecting { }
extension OnlineDepositViewModelProtocolMock: CollectErrorViewModelProtocol, ObservableObject { } 

class OnlinePaymentViewTest: XCTestCase {
    private let onlinePayment: PaymentsDTO.Online = PaymentsDTO.Online.init(identity: "24", name: "数字人民币", hint: "", isRecommend: false, beneficiaries: RxSwift.Single<NSArray>.just([PaymentsDTO.Gateway(identity: "70", name: "JinYi_Digital", cash: CashType.Input.init(limitation: AmountRange.init(min: FiatFactory.shared.create(supportLocale: SupportLocale.China.init(), amount_: "200"), max: FiatFactory.shared.create(supportLocale: SupportLocale.China.init(), amount_: "2000")), isFloatAllowed: false), remitType: PaymentsDTO.RemitType.normal, remitBank: [], verifier: CompositeVerification<RemitApplication, PaymentError>(), hint: "", isAccountNumberDenied: true, isInstructionDisplayed: true)] as NSArray).asWrapper())
    
    private let gateway = PaymentsDTO.Gateway(identity: "70", name: "JinYi_Digital", cash: CashType.Input.init(limitation: AmountRange.init(min: FiatFactory.shared.create(supportLocale: SupportLocale.China.init(), amount_: "200"), max: FiatFactory.shared.create(supportLocale: SupportLocale.China.init(), amount_: "2000")), isFloatAllowed: false), remitType: PaymentsDTO.RemitType.normal, remitBank: [], verifier: CompositeVerification<RemitApplication, PaymentError>(), hint: "", isAccountNumberDenied: true, isInstructionDisplayed: true)
    
    private var mockViewModel: OnlineDepositViewModelProtocolMock!

    override func setUpWithError() throws {
        mockViewModel = mock(OnlineDepositViewModelProtocol.self)
        
        given(mockViewModel.selectedOnlinePayment) ~> self.onlinePayment
        given(mockViewModel.gateways) ~> [self.gateway]
        given(mockViewModel.getRemitterName()) ~> RxSwift.Single<String>.just("")
        given(mockViewModel.submitRemittance(gatewayIdentity: any(), remitterName: any(), remittance: any())) ~> RxSwift.Single.just(CommonDTO.WebPath.init(path: ""))
    }
    
    func test_Remit_Button_Enable_When_No_Remittance_Error_Occurred() {
        given(mockViewModel.applicationErrors) ~> []
        
        let sut = OnlinePaymentView(viewModel: self.mockViewModel, selectedGateway: gateway, amount: "200")
        
        let exp = sut.inspection.inspect { view in
            let remitButton = try view.find(viewWithId: "RemitButton").button()
            
            XCTAssertFalse(remitButton.isDisabled())
        }
        
        ViewHosting.host(view: sut)
        wait(for: [exp], timeout: 30)
    }
    
    func test_Remit_Button_Disable_When_Remittance_Out_Of_Limit_Range() {
        given(mockViewModel.applicationErrors) ~> [PaymentError.RemittanceOutOfRange()]
        
        let sut = OnlinePaymentView(viewModel: self.mockViewModel, selectedGateway: gateway, amount: "200")
        
        let exp = sut.inspection.inspect { view in
            let remitButton = try view.find(viewWithId: "RemitButton").button()
            
            XCTAssertTrue(remitButton.isDisabled())
        }
        
        ViewHosting.host(view: sut)
        wait(for: [exp], timeout: 30)
    }
    
    func test_Remit_Button_Disable_When_Remittance_is_Empty() {
        given(mockViewModel.applicationErrors) ~> [PaymentError.RemittanceIsEmpty()]
        
        let sut = OnlinePaymentView(viewModel: self.mockViewModel, selectedGateway: gateway, amount: "200")
        
        let exp = sut.inspection.inspect { view in
            let remitButton = try view.find(viewWithId: "RemitButton").button()
            
            XCTAssertTrue(remitButton.isDisabled())
        }
        
        ViewHosting.host(view: sut)
        wait(for: [exp], timeout: 30)
    }
    
    func test_Error_Text_When_Remittance_Error_Occurred() {
        given(mockViewModel.applicationErrors) ~> [PaymentError.RemittanceOutOfRange()]
        
        let sut = OnlinePaymentView(viewModel: self.mockViewModel, selectedGateway: gateway)
        
        let exp = sut.inspection.inspect { view in
            let textField = try view.find(viewWithId: "RemittanceInputTextField")
            let errorText = try textField.find(viewWithId: "ErrorHint").text().string()

            XCTAssertFalse(errorText.isEmpty)
        }
        
        ViewHosting.host(view: sut)
        wait(for: [exp], timeout: 30)
    }
    
    func test_Error_Text_When_No_Remittance_Error_Occurred() {
        given(mockViewModel.applicationErrors) ~> []
        
        let sut = OnlinePaymentView(viewModel: self.mockViewModel, selectedGateway: gateway)
        
        let exp = sut.inspection.inspect { view in
            let textField = try view.find(viewWithId: "RemittanceInputTextField")
            let errorText = try? textField.find(viewWithId: "ErrorHint").text()

            XCTAssertNil(errorText)
        }
        
        ViewHosting.host(view: sut)
        wait(for: [exp], timeout: 30)
    }
    
    func test_Remit_Button_On_Click() {
        given(mockViewModel.applicationErrors) ~> []
        
        let sut = OnlinePaymentView(viewModel: self.mockViewModel, selectedGateway: gateway, amount: "200")
        
        let exp = sut.inspection.inspect { view in
            let remitButton = try view.find(viewWithId: "RemitButton").button()
            XCTAssertFalse(remitButton.isDisabled())
            
            try remitButton.tap()
            verify(self.mockViewModel.submitRemittance(gatewayIdentity: any(), remitterName: any(), remittance: any())).wasCalled()
        }
        
        ViewHosting.host(view: sut)
        wait(for: [exp], timeout: 30)
    }
}

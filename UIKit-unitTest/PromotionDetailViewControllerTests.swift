import XCTest
import Mockingbird
import RxSwift
import SharedBu

@testable import ktobet_asia_ios_qat

final class PromotionDetailViewControllerTests: XCTestCase {
    private var vc: PromotionDetailViewController!
    
    override func setUp() {
        injectStubAuthenticationUseCase()
        
        let storyboard = UIStoryboard(name: "Promotion", bundle: nil)
        vc = (storyboard.instantiateViewController(identifier: "PromotionDetailViewController") as! PromotionDetailViewController)
    }
    
    private func stubLocalDateTime(year: Int32) -> LocalDateTime {
        LocalDateTime(date: .init(year: year, month: .october, dayOfMonth: 4),
                      time: .init(hour: 12, minute: 0, second: 0, nanosecond: 0))
    }
    
    private func stubCouponProperty() -> BonusCoupon.Property {
        return BonusCoupon.Property(
            promotionId: "7",
            bonusId: "7",
            name: "",
            issueNumber: nil,
            percentage: .init(percent: 1),
            amount: "1".toAccountCurrency(),
            endDate: stubLocalDateTime(year: 2122),
            betMultiple: 1,
            fixTurnoverRequirement: 0,
            validPeriod: .Always.shared,
            couponStatus: .usable,
            updatedDate: stubLocalDateTime(year: 2022),
            informPlayerDate: .init(localDateTime: stubLocalDateTime(year: 2022), timeZone: TimeZone.fromFoundation(.current)),
            minCapital: "0".toAccountCurrency())
    }
    
    private func dummyPromotionViewModel() -> PromotionViewModelMock {
        let dummyPromotionUseCase = mock(PromotionUseCase.self)
        let dummyPlayerUseCase = mock(PlayerDataUseCase.self)
        
        let dummyViewModel = mock(PromotionViewModel.self).initialize(promotionUseCase: dummyPromotionUseCase, playerUseCase: dummyPlayerUseCase)
        
        given(dummyPlayerUseCase.loadPlayer())
        ~> RxSwift.Single
            .just(
                Player(
                    gameId: "",
                    playerInfo: .init(
                        gameId: "1",
                        displayId: "1",
                        withdrawalName: "",
                        level: 10,
                        exp: .init(percent: 0),
                        autoUseCoupon: false,
                        contact: .init(email: nil, mobile: nil)
                    ),
                    bindLocale: .China.init(),
                    defaultProduct: nil
                )
            )
        
        given(dummyViewModel.getPromotionDetail(id: any()))
        ~> RxSwift.Single
            .just(
                PromotionDescriptions(content: "",rules: "")
            )
            .asDriver(
                onErrorJustReturn: PromotionDescriptions(content: "",rules: "")
            )
        
        given(dummyViewModel.requestCouponApplication(bonusCoupon: any()))
        ~> RxSwift.Single
            .just(
                ConfirmUseCouponFail(throwable: BonusCouponIsNotExist.init(message: "", errorCode: "0") as ApiException)
            )
        
        given(dummyViewModel.getCashBackSettings(id: any())) ~> .just([])
        
        return dummyViewModel
    }

    func test_manuallyUseCashBackCoupon_haveTurnOver_AlertTurnOverTip_KTO_TC_20() {
    }

    func test_manuallyUseCashBackCoupon_couponExpired_AlertExpiredTip_KTO_TC_21() {
        
    }
    
    func test_manuallyUseCashBackCoupon_couponAvailable_AlertUseCouponTip_KTO_TC_22() {
        
    }
    
    func test_whenCashBackCouponType_thenDisplayCashBackInfo_KTO_TC_23() {
        let stubPromotionVmItem = BonusCoupon.VVIPCashback(property: stubCouponProperty())
        
        vc.item = stubPromotionVmItem
        vc.viewModel = dummyPromotionViewModel()
        
        vc.loadViewIfNeeded()
        
        XCTAssertFalse(vc.cashBackInfoStackView.isHidden)
    }
    
    func test_whenCashBackPromotionEventType_thenDisplayCashBackInfo_KTO_TC_30() {
        let stubPromotionVmItem = PromotionEvent.VVIPCashback(promotionId: "",
                                                              issueNumber: 0,
                                                              informPlayerDate: stubLocalDateTime(year: 2022),
                                                              percentage: .init(percent: 1),
                                                              maxBonus: Promotion.companion.create(amount: "100.0".toAccountCurrency()),
                                                              endDate: .init(
                                                                localDateTime: stubLocalDateTime(year: 2022),
                                                                timeZone: TimeZone.fromFoundation(.current)
                                                              ))
        
        vc.item = stubPromotionVmItem
        vc.viewModel = dummyPromotionViewModel()
        
        vc.loadViewIfNeeded()
        
        XCTAssertFalse(vc.cashBackInfoStackView.isHidden)
    }
}

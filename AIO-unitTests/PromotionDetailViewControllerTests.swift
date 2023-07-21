import Mockingbird
import RxSwift
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class PromotionDetailViewControllerTests: XCBaseTestCase {
  struct CouponForTest {
    enum CouponType {
      case VVIP
    }

    enum CouponStatus {
      case inTimeRange
      case expired
    }
  }

  private var vc: PromotionDetailViewController!

  override func setUp() {
    injectStubCultureCode(.CN)

    let storyboard = UIStoryboard(name: "Promotion", bundle: nil)
    vc = (storyboard.instantiateViewController(identifier: "PromotionDetailViewController") as! PromotionDetailViewController)
  }

  private func getStubCoupon(type: CouponForTest.CouponType, status: CouponForTest.CouponStatus) -> PromotionVmItem {
    switch type {
    case .VVIP:
      return BonusCoupon.VVIPCashback(property: stubCouponProperty(status))
    }
  }

  private func stubCouponProperty(_ status: CouponForTest.CouponStatus) -> BonusCoupon.Property {
    BonusCoupon.Property(
      promotionId: "7",
      bonusId: "7",
      name: "",
      issueNumber: nil,
      percentage: .init(percent: 1),
      amount: "1".toAccountCurrency(),
      endDate: stubLocalDateTime(year: status == .inTimeRange ? 2122 : 2021),
      betMultiple: 1,
      fixTurnoverRequirement: 0,
      validPeriod: .Always.shared,
      couponStatus: .usable,
      updatedDate: stubLocalDateTime(year: 2022),
      informPlayerDate: .init(localDateTime: stubLocalDateTime(year: 2022), timeZone: TimeZone.fromFoundation(.current)),
      minCapital: "0".toAccountCurrency())
  }

  private func stubLocalDateTime(year: Int32) -> LocalDateTime {
    LocalDateTime(
      date: .init(year: year, month: .october, dayOfMonth: 4),
      time: .init(hour: 12, minute: 0, second: 0, nanosecond: 0))
  }

  private func getFakePromotionViewModel() -> PromotionViewModelMock {
    let dummyPromotionUseCase = mock(PromotionUseCase.self)
    let dummyPlayerUseCase = mock(PlayerDataUseCase.self)

    let fakeViewModel = mock(PromotionViewModel.self)
      .initialize(promotionUseCase: dummyPromotionUseCase, playerUseCase: dummyPlayerUseCase)

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
            contact: .init(email: nil, mobile: nil)),
          bindLocale: .China(),
          defaultProduct: nil))

    given(fakeViewModel.getPromotionDetail(id: any()))
      ~> RxSwift.Single
      .just(
        PromotionDescriptions(content: "", rules: ""))
      .asDriver(
        onErrorJustReturn: PromotionDescriptions(content: "", rules: ""))

    given(fakeViewModel.requestCouponApplication(bonusCoupon: any()))
      ~> RxSwift.Single
      .just(
        ConfirmUseCouponFail(throwable: BonusCouponIsNotExist(message: "", errorCode: "0") as ApiException))

    given(fakeViewModel.getCashBackSettings(id: any())) ~> .just([])

    return fakeViewModel
  }

  private func dummyTurnOverDetail() -> TurnOverDetail {
    TurnOverDetail(
      achieved: "0".toAccountCurrency(),
      formula: "",
      informPlayerDate: .init(
        localDateTime: stubLocalDateTime(year: 2022),
        timeZone: TimeZone.fromFoundation(.current)),
      name: "",
      bonusId: "",
      remainAmount: "0".toAccountCurrency(),
      parameters: .init(
        amount: "0".toAccountCurrency(),
        balance: "0".toAccountCurrency(),
        betMultiplier: 1,
        capital: "0".toAccountCurrency(),
        depositRequest: "0".toAccountCurrency(),
        percentage: .init(percent: 0),
        request: "0".toAccountCurrency(),
        requirement: "0".toAccountCurrency(),
        turnoverRequest: "0".toAccountCurrency()))
  }

  func test_manuallyUseCashBackCoupon_haveTurnOver_AlertTurnOverTip_KTO_TC_20() {
    let stubPromotionVmItem = getStubCoupon(type: .VVIP, status: .inTimeRange)
    let stubPromotionViewModel = getFakePromotionViewModel()

    let mockUseCouponPresenter = mock(UseCouponPresenter.self)

    given(stubPromotionViewModel.requestCouponApplication(bonusCoupon: any())) ~>
      .just(ConfirmBonusLocked(turnOver: self.dummyTurnOverDetail()))

    vc.item = stubPromotionVmItem
    vc.viewModel = stubPromotionViewModel
    vc.subUseBonusCoupon = SubUseBonusCoupon(presenter: mockUseCouponPresenter)

    vc.loadViewIfNeeded()

    vc.getPromotionButton.sendActions(for: .touchUpInside)

    verify(mockUseCouponPresenter.presentTurnOverLockedDialog(turnOver: any())).wasCalled()
  }

  func test_manuallyUseCashBackCoupon_couponExpired_AlertExpiredTip_KTO_TC_21() {
    let stubPromotionVmItem = getStubCoupon(type: .VVIP, status: .expired)
    let stubPromotionViewModel = getFakePromotionViewModel()

    let mockUseCouponPresenter = mock(UseCouponPresenter.self)

    given(stubPromotionViewModel.requestCouponApplication(bonusCoupon: any())) ~> .just(
      ConfirmUseCouponFail(throwable: BonusCouponIsNotExist(message: nil, errorCode: "")))

    vc.item = stubPromotionVmItem
    vc.viewModel = stubPromotionViewModel
    vc.subUseBonusCoupon = SubUseBonusCoupon(presenter: mockUseCouponPresenter)

    vc.loadViewIfNeeded()

    vc.getPromotionButton.sendActions(for: .touchUpInside)

    verify(
      mockUseCouponPresenter.showAlert(
        any(String.self, where: { $0.contains("优惠已到期") }),
        any(String.self, where: { $0.contains("很抱歉，本优惠已到期，请您参考其它优惠，造成您不便敬请见谅。") }),
        confirm: any(),
        confirmText: any(),
        cancel: any(),
        cancelText: any())).wasCalled()
  }

  func test_manuallyUseCashBackCoupon_couponAvailable_AlertUseCouponTip_KTO_TC_22() {
    let stubPromotionVmItem = getStubCoupon(type: .VVIP, status: .inTimeRange)
    let stubPromotionViewModel = getFakePromotionViewModel()

    let mockUseCouponPresenter = mock(UseCouponPresenter.self)

    let dummyCouponUseCase = mock(CouponUseCase.self)
    let dummyBonusCoupon = getStubCoupon(type: .VVIP, status: .inTimeRange) as! BonusCoupon.VVIPCashback
    let dummyWaitingConfirm = ConfirmUseBonusCoupon(useCase: dummyCouponUseCase, bonusCoupon: dummyBonusCoupon)

    given(stubPromotionViewModel.requestCouponApplication(bonusCoupon: any())) ~> .just(dummyWaitingConfirm)

    vc.item = stubPromotionVmItem
    vc.viewModel = stubPromotionViewModel
    vc.subUseBonusCoupon = SubUseBonusCoupon(presenter: mockUseCouponPresenter)

    vc.loadViewIfNeeded()

    vc.getPromotionButton.sendActions(for: .touchUpInside)

    verify(
      mockUseCouponPresenter.showAlert(
        any(),
        any(String.self, where: { $0.contains("您是否要领取负盈利返现") }),
        confirm: any(),
        confirmText: any(),
        cancel: any(),
        cancelText: any())).wasCalled()
  }

  func test_whenCashBackCouponType_thenDisplayCashBackInfo_KTO_TC_23() {
    let stubPromotionVmItem = getStubCoupon(type: .VVIP, status: .inTimeRange)
    let dummyViewModel = getFakePromotionViewModel()

    vc.item = stubPromotionVmItem
    vc.viewModel = dummyViewModel

    vc.loadViewIfNeeded()

    XCTAssertFalse(vc.cashBackInfoStackView.isHidden)
  }

  func test_whenCashBackPromotionEventType_thenDisplayCashBackInfo_KTO_TC_30() {
    let stubPromotionVmItem = PromotionEvent.VVIPCashback(
      promotionId: "",
      issueNumber: 0,
      informPlayerDate: stubLocalDateTime(year: 2022),
      percentage: .init(percent: 1),
      maxBonus: Promotion.companion
        .create(amount: "100.0".toAccountCurrency()),
      endDate: .init(
        localDateTime: stubLocalDateTime(year: 2022),
        timeZone: TimeZone.fromFoundation(.current)))
    let dummyViewModel = getFakePromotionViewModel()

    vc.item = stubPromotionVmItem
    vc.viewModel = dummyViewModel

    vc.loadViewIfNeeded()

    XCTAssertFalse(vc.cashBackInfoStackView.isHidden)
  }
}

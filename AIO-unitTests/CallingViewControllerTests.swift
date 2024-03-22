import Combine
import Mockingbird
import RxSwift
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

class CallingViewControllerTests: XCBaseTestCase {
  class DummyChatRoomViewModel: ChatRoomViewModel {
    override func setup(onChatRoomClose _: @escaping (String) -> Void, onChatRoomMaintain _: @escaping () -> Void) { }
    override func readAllMessage(updateToLast _: Bool? = nil, isAuto _: Bool? = nil) { }
  }
  
  private func getStubViewModel() -> CallingViewModelMock {
    let dummyAbsCustomerServiceAppService = mock(AbsCustomerServiceAppService.self)
    given(dummyAbsCustomerServiceAppService.observeChatRoom()) ~> Observable.just(CustomerServiceDTO.ChatRoom.NOT_EXIST)
      .asWrapper()
    
    let viewModel = mock(CallingViewModel.self)
      .initialize(dummyAbsCustomerServiceAppService)

    injectFakeObject(CallingViewModel.self, object: viewModel)

    given(viewModel.getCurrentNumber()) ~> 0
    given(viewModel.setup(surveyAnswers: nil)) ~> ()
    given(viewModel.errors()) ~> Empty(completeImmediately: true, outputType: Error.self, failureType: Never.self)
      .eraseToAnyPublisher()
    
    return viewModel
  }
  
  func test_givenCallingAndNoServiceResponse_thenShowLeaveMessageAlert_KTO_TC_112() {
    let mockAlert = mock(AlertProtocol.self)
    Alert.shared = mockAlert
    
    let sut = CallingViewController(surveyAnswers: nil)
    UINavigationController(rootViewController: sut).loadViewIfNeeded()
    sut.showLeaveMessageAlert()

    verify(
      mockAlert.show(
        Localize.string("customerservice_leave_a_message_title"),
        Localize.string("customerservice_leave_a_message_content"),
        confirm: any(),
        confirmText: Localize.string("customerservice_leave_a_message_confirm"),
        cancel: any(),
        cancelText: Localize.string("common_skip"),
        tintColor: any()))
      .wasCalled()
  }
  
  func test_givenCallingAndNotConnectedYet_whenPlayerDisconnecting_thenShowStopCallingAlert_KTO_TC_898() {
    let mockAlert = mock(AlertProtocol.self)
    Alert.shared = mockAlert
    
    let sut = CallingViewController(surveyAnswers: nil)
    UINavigationController(rootViewController: sut).loadViewIfNeeded()
    sut.showStopCallingAlert()

    verify(
      mockAlert.show(
        Localize.string("customerservice_stop_call_title"),
        Localize.string("customerservice_stop_call_content"),
        confirm: any(),
        confirmText: Localize.string("common_continue"),
        cancel: any(),
        cancelText: Localize.string("common_stop"),
        tintColor: any()))
      .wasCalled()
  }

  func test_givenTapCloseButtonAndShowStopCallingAlert_whenTapStopButton_thenShowLeaveMessageAlert_KTO_TC_899() {
    let mockAlert = mock(AlertProtocol.self)
    Alert.shared = mockAlert
    
    let sut = CallingViewController(surveyAnswers: nil)
    UINavigationController(rootViewController: sut).loadViewIfNeeded()
    sut.showStopCallingAlert()
    
    verify(
      mockAlert.show(
        Localize.string("customerservice_stop_call_title"),
        Localize.string("customerservice_stop_call_content"),
        confirm: any(),
        confirmText: Localize.string("common_continue"),
        cancel: any(),
        cancelText: Localize.string("common_stop"),
        tintColor: any()))
      .wasCalled()
    
    sut.showLeaveMessageAlert()
    
    verify(
      mockAlert.show(
        Localize.string("customerservice_leave_a_message_title"),
        Localize.string("customerservice_leave_a_message_content"),
        confirm: any(),
        confirmText: Localize.string("customerservice_leave_a_message_confirm"),
        cancel: any(),
        cancelText: Localize.string("common_skip"),
        tintColor: any()))
      .wasCalled()
  }

  func test_givenShowLeaveMessageAlert_whenTapLeaveMessageButton_thenToOfflineMessageVC_KTO_TC_900() {
    let mockAlert = mock(AlertProtocol.self)
    Alert.shared = mockAlert
    
    let sut = CallingViewController(surveyAnswers: nil)
    UINavigationController(rootViewController: sut).loadViewIfNeeded()
    
    let fakeViewController = UIViewController()
    let mockNavigationController = FakeNavigationController(rootViewController: fakeViewController)
    sut.toOfflineMessageVC(mockNavigationController)
    
    let actual = mockNavigationController.lastNavigatedViewController
    XCTAssertNotNil(actual)
  }

  func test_givenCalling_whenServiceConnected_thenToChatRoomVC_KTO_TC_901() {
    let viewModel = getStubViewModel()
    given(viewModel.getChatRoomStream()) ~> Just(CustomerServiceDTO.ChatRoom(
      roomId: "",
      readMessage: [],
      unReadMessage: [],
      status: Connection.StatusConnected(),
      isMaintained: false))
      .eraseToAnyPublisher()
    
    let dummyViewModel = DummyChatRoomViewModel(
      mock(AbsCustomerServiceAppService.self),
      mock(AbsCustomerServiceAppService.self),
      PlayerConfigurationImpl(SupportLocale.Vietnam().cultureCode()))
    
    injectFakeObject(CallingViewModel.self, object: viewModel)
    injectFakeObject(ChatRoomViewModel.self, object: dummyViewModel)
    
    let sut = CallingViewController(surveyAnswers: nil)
    let navi = CustomServiceNavigationController(rootViewController: sut)
    makeItVisible(navi)
    
    wait(for: 0.001)
    let presentedPage = "\(type(of: navi.viewControllers.first!))"
    
    XCTAssertEqual(expect: "ChatRoomViewController", actual: presentedPage)
  }
}

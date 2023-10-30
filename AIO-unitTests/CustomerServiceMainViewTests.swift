import Mockingbird
import sharedbu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension CustomerServiceMainView.ServiceButton: Inspecting { }

final class CustomerServiceMainViewTests<ViewModel>: XCBaseTestCase
  where ViewModel:
  CustomerServiceMainViewModelProtocol &
  ObservableObject
{
  func test_whenChatRoomNotCloseYet_thenServiceButtonDisplayChattingAndDisable_KTO_TC_110() {
    let sut = CustomerServiceMainView<ViewModel>.ServiceButton(isChatting: true)
    
    let exp = sut.inspection.inspect { view in
      let serviceButton = try view.find(viewWithId: "serviceButton")
      let actualIcon = try serviceButton.find(viewWithId: "icon").localizedText().string()
      let actualTitle = try serviceButton.find(viewWithId: "title").localizedText().string()
      
      let expectIcon = "CS_connected"
      let expectTitle = Localize.string("customerservice_call_connected")
      
      XCTAssertEqual(expectIcon, actualIcon)
      XCTAssertEqual(expectTitle, actualTitle)
      
      let isButtonDisable = try view
        .find(viewWithId: "serviceButton")
        .find(viewWithId: "asyncButton")
        .button()
        .isDisabled()

      XCTAssertFalse(isButtonDisable)
    }
    
    ViewHosting.host(view: sut)
    
    wait(for: [exp], timeout: 30)
  }
  
  func test_whenChatRoomNotCreated_thenServiceButtonDisplayCallIn_KTO_TC_111() {
    let sut = CustomerServiceMainView<ViewModel>.ServiceButton(isChatting: false)

    let exp = sut.inspection.inspect { view in
      let serviceButton = try view.find(viewWithId: "serviceButton")
      let actualIcon = try serviceButton.find(viewWithId: "icon").localizedText().string()
      let actualTitle = try serviceButton.find(viewWithId: "title").localizedText().string()

      let expectIcon = "CS_immediately"
      let expectTitle = Localize.string("customerservice_call_immediately")

      XCTAssertEqual(expectIcon, actualIcon)
      XCTAssertEqual(expectTitle, actualTitle)
    }

    ViewHosting.host(view: sut)

    wait(for: [exp], timeout: 30)
  }
  
  @MainActor
  func test_givenTapServiceButton_whenNoSurvey_thenToCallingPage_KTO_TC_113() async {
    let stubViewModel = mock(CustomerServiceMainViewModelProtocol.self)
    
    await given(stubViewModel.hasPreChatSurvey()) ~> false
    
    let exp = expectation(description: "ViewController pushed")
    
    let navigationController = UINavigationController(rootViewController: UIViewController())
    let callingVC = CallingViewController()
    navigationController.pushViewController(callingVC, animated: true)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      exp.fulfill()
    }
    
    wait(for: [exp], timeout: 30)

    XCTAssertEqual(navigationController.viewControllers.last, callingVC, "Push operation failed")
  }
  
  @MainActor
  func test_givenTapServiceButton_whenHasSurvey_thenToSurveyPage_KTO_TC_114() async {
    let stubViewModel = mock(CustomerServiceMainViewModelProtocol.self)
    
    await given(stubViewModel.hasPreChatSurvey()) ~> true
    
    let exp = expectation(description: "ViewController pushed")
    
    let navigationController = UINavigationController(rootViewController: UIViewController())
    let callingVC = PrechatServeyViewController()
    navigationController.pushViewController(callingVC, animated: true)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      exp.fulfill()
    }
    
    wait(for: [exp], timeout: 30)

    XCTAssertEqual(navigationController.viewControllers.last, callingVC, "Push operation failed")
  }
}

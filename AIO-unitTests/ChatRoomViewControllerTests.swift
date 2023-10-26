import Mockingbird
import RxSwift
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

final class ChatRoomViewControllerTests: XCBaseTestCase {
  private var vc: ChatRoomViewController!

  override func setUp() {
    let storyboard = UIStoryboard(name: "CustomService", bundle: nil)
    vc = (storyboard.instantiateViewController(identifier: "ChatRoomViewController") as! ChatRoomViewController)
  }

  private func generateCharacters(char: String, count: Int) -> String {
    var characters = ""

    for _ in 1...count {
      characters += char
    }

    return characters
  }

  private func getDummyCustomerServiceViewModel() -> CustomerServiceViewModel {
    let dummyCustomerServiceViewModel = mock(CustomerServiceViewModel.self)
      .initialize(
        mock(AbsCustomerServiceAppService.self),
        mock(PlayerConfiguration.self),
        mock(Loading.self))
    
    given(dummyCustomerServiceViewModel.currentChatRoom()) ~> .never()

    return dummyCustomerServiceViewModel
  }

  func test_inputTextFieldIs500Characters_typeTheCharacter_ignoreTheCharacter_KTO_TC_32() {
    vc.viewModel = getDummyCustomerServiceViewModel()

    vc.loadViewIfNeeded()
    vc.viewWillAppear(true)

    let currentText = generateCharacters(char: "1", count: 500)
    let textField = vc.inputTextField
    textField!.text = currentText

    let typeCharacter = generateCharacters(char: "a", count: 1)

    vc.textChanged(currentText + typeCharacter)

    let expect = currentText
    let actual = vc.inputTextField.text!

    XCTAssertEqual(expect, actual)
  }
}

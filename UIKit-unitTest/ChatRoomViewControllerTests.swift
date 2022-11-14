import XCTest
import RxSwift
import Mockingbird
import SharedBu

@testable import ktobet_asia_ios_qat

final class ChatRoomViewControllerTests: XCTestCase {
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
        let dummyCustomerServiceUseCase = mock(CustomerServiceUseCase.self)
        let dummyCustomerServiceViewModel = mock(CustomerServiceViewModel.self).initialize(customerServiceUseCase: dummyCustomerServiceUseCase)
        
        given(dummyCustomerServiceViewModel.fullscreen())
        ~> RxSwift.Completable
            .create(subscribe: { event in
                event(.completed)
                
                return Disposables.create {}
            })
        
        given(dummyCustomerServiceUseCase.currentChatRoom()) ~> Observable.error(NSError(domain: "", code: 401))
        
        return dummyCustomerServiceViewModel
    }
    
    func test_inputTextFieldIsEmpty_pasteOver500Characters_deleteExcess() {
        vc.viewModel = getDummyCustomerServiceViewModel()
        
        vc.loadViewIfNeeded()
        vc.viewWillAppear(true)
        
        let textField = vc.inputTextField
        let expect = generateCharacters(char: "1", count: 500)
        
        let pasteOver500Characters = generateCharacters(char: "1", count: 500) + generateCharacters(char: "a", count: 10)
        let _ = textField!.delegate!.textField!(textField!, shouldChangeCharactersIn: NSMakeRange(0, 0), replacementString: pasteOver500Characters)
        
        let actual = vc.inputTextField.text!
        
        XCTAssertEqual(expect, actual)
    }
    
    func test_inputTextFieldNotEmpty_pasteOver500Characters_deleteExcess() {
        vc.viewModel = getDummyCustomerServiceViewModel()
        
        vc.loadViewIfNeeded()
        vc.viewWillAppear(true)
        
        let textField = vc.inputTextField
        textField!.text = generateCharacters(char: "1", count: 490)
        
        let expect = generateCharacters(char: "1", count: 490) + generateCharacters(char: "a", count: 10)
        
        let pasteOver500Characters = generateCharacters(char: "a", count: 20)
        let _ = textField!.delegate!.textField!(textField!, shouldChangeCharactersIn: NSMakeRange(490, 0), replacementString: pasteOver500Characters)
        
        let actual = vc.inputTextField.text!
        
        XCTAssertEqual(expect, actual)
    }
    
    func test_inputTextFieldNotEmpty_pasteOver500CharactersInMiddle_deleteExcessPasteSentence() {
        vc.viewModel = getDummyCustomerServiceViewModel()
        
        vc.loadViewIfNeeded()
        vc.viewWillAppear(true)
        
        let textField = vc.inputTextField
        textField!.text = generateCharacters(char: "1", count: 450)
        
        let expect = generateCharacters(char: "1", count: 200) + generateCharacters(char: "a", count: 50) + generateCharacters(char: "1", count: 250)
        
        let pasteOver500Characters = generateCharacters(char: "a", count: 100)
        let _ = textField!.delegate!.textField!(textField!, shouldChangeCharactersIn: NSMakeRange(200, 0), replacementString: pasteOver500Characters)
        
        let actual = vc.inputTextField.text!
        
        XCTAssertEqual(expect, actual)
    }
    
    func test_inputTextFieldIsEmpty_typeTheCharacter_setTheCharacter() {
        vc.viewModel = getDummyCustomerServiceViewModel()
        
        vc.loadViewIfNeeded()
        vc.viewWillAppear(true)
        
        let textField = vc.inputTextField
        let expect = generateCharacters(char: "a", count: 1)
        
        let typeCharacter = generateCharacters(char: "a", count: 1)
        let _ = textField!.delegate!.textField!(textField!, shouldChangeCharactersIn: NSMakeRange(0, 0), replacementString: typeCharacter)
        
        let actual = vc.inputTextField.text!
        
        XCTAssertEqual(expect, actual)
    }
    
    func test_inputTextFieldNotEmpty_typeTheCharacter_setTheCharacter() {
        vc.viewModel = getDummyCustomerServiceViewModel()
        
        vc.loadViewIfNeeded()
        vc.viewWillAppear(true)
        
        let textField = vc.inputTextField
        textField!.text = generateCharacters(char: "1", count: 490)
        let expect = generateCharacters(char: "1", count: 490) + generateCharacters(char: "a", count: 1)
        
        let typeCharacter = generateCharacters(char: "a", count: 1)
        let _ = textField!.delegate!.textField!(textField!, shouldChangeCharactersIn: NSMakeRange(490, 0), replacementString: typeCharacter)
        
        let actual = vc.inputTextField.text!
        
        XCTAssertEqual(expect, actual)
    }
    
    func test_inputTextFieldIs500Characters_typeTheCharacter_ignoreTheCharacter_KTO_TC_32() {
        vc.viewModel = getDummyCustomerServiceViewModel()
        
        vc.loadViewIfNeeded()
        vc.viewWillAppear(true)
        
        let textField = vc.inputTextField
        textField!.text = generateCharacters(char: "1", count: 500)
        let expect = generateCharacters(char: "1", count: 500)
        
        let typeCharacter = generateCharacters(char: "a", count: 1)
        let _ = textField!.delegate!.textField!(textField!, shouldChangeCharactersIn: NSMakeRange(490, 0), replacementString: typeCharacter)
        
        let actual = vc.inputTextField.text!
        
        XCTAssertEqual(expect, actual)
    }
}

import Mockingbird
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

final class RegisterUseCaseTests: XCTestCase {
  func testRegisterBlock() async {
    let stubIAuthRepo = mock(IAuthRepository.self)
    let dummyPlayerRepo = mock(PlayerRepository.self)
    
    given(stubIAuthRepo.register(any(), any(), any())) ~> .error(PlayerRegisterBlock(message: nil, errorCode: ""))
    
    let sut = RegisterUseCaseImpl(stubIAuthRepo, dummyPlayerRepo)
    
    do {
      try await sut.register(account: .init(username: "", type: .Email(email: "")), password: .init(value: ""), locale: .China())
        .value
      
      XCTFail("Error should occur.")
    }
    catch {
      let actual = error as! KtoException
      let expect = KtoPlayerRegisterBlock()
      
      XCTAssertEqual(expect, actual)
    }
  }
}

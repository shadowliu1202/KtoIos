import Mockingbird
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension CallingViewModelProtocolMock: ObservableObject { }

extension CallingView: Inspecting { }

final class CallingViewTests<ViewModel>: XCBaseTestCase
  where ViewModel:
  CallingViewModelProtocol &
  ObservableObject
{
  func test_givenCallingAndNoServiceResponse_thenDisplayPlayersNumber_KTO_TC_902() {
    let stubViewModel = mock(CallingViewModelProtocol.self)
    given(stubViewModel.currentNumber) ~> 10

    let sut = CallingView(viewModel: stubViewModel, surveyAnswers: nil)
    
    let exp = sut.inspection.inspect { view in
      let actualText = try view
        .find(viewWithId: "queueNumber")
        .text()
        .string()

      XCTAssertEqual(expect: "10", actual: actualText)
    }

    ViewHosting.host(view: sut)

    wait(for: [exp], timeout: 30)
  }
}

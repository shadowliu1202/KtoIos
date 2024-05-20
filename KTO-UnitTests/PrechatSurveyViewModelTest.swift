import Mockingbird
import sharedbu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

final class PrechatSurveyViewModelTest: XCBaseTestCase {
    func test_getPrechatSurvey() {
        let dummyPlayerConfiguration = mock(PlayerConfiguration.self)
        let dummyNetworkMonitor = mock(INetworkMonitor.self)
        let stubAppService = mock(AbsCustomerServiceAppService.self)
    
        given(dummyNetworkMonitor.getStatus()) ~> .just(.connected)
    
        given(stubAppService.getPreChatSurvey()) ~> Single.just(CustomerServiceDTO.CSSurvey(
            heading: "",
            description: "",
            surveyId: "",
            questions: []))
            .asWrapper()
    
        let sut = PrechatSurveyViewModel(stubAppService, dummyPlayerConfiguration, dummyNetworkMonitor)
        sut.setup()
    
        wait(for: 1)
    
        XCTAssertNotNil(sut.survey)
    }
}

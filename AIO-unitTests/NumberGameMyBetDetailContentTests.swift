import Mockingbird
import sharedbu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios

final class NumberGameMyBetDetailContentTests: XCBaseTestCase {
    func test_givenGameResultTypeIsPrize_thenDisplayPrizeGameResult_KTO_TC_907() {
        let mybetDetail = NumberGameBetDetail(
            displayId: "12345678901234567890123456789012",
            traceId: "12345678901234567890123456789012",
            gameName: "So de -x - Siêu Tốc 1 phút",
            matchMethod: "(20230913-1074)",
            betContent: ["中三直选跨度 [中三_直选跨度]", "1,2,3,4,5"],
            betTime: Date().toLocalDateTime(.current),
            stakes: "50".toAccountCurrency(),
            status: NumberGameBetDetail.BetStatusSettledWinLose(winLoss: "50".toAccountCurrency()),
            resultType: .prize,
            _result: """
            {
              "Giải ĐB": "00057",
              "Giải nhất": "60930",
              "Giải nhì": "58590-31347",
              "Giải ba": "41010-41582-63910-65482-51356-13561-37591",
              "Giải tư": "5826",
              "Giải năm": "7130-3457-2179",
              "Giải sáu": "863",
              "Giải bảy": "91",
              "Giải tám": "02135",
              "Sequence": "[\\\"Giải ĐB\\\",\\\"Giải nhất\\\",\\\"Giải nhì\\\",\\\"Giải ba\\\",\\\"Giải tư\\\",\\\"Giải năm\\\",\\\"Giải sáu\\\",\\\"Giải bảy\\\",\\\"Giải tám\\\"]"
            }
            """)
    
        let mybetDetailView = InspectWrapper {
            NumberGameMyBetDetailContent(myBetDetail: mybetDetail, page: 1, supportLocale: .Vietnam())
        }
    
        let exp = mybetDetailView.inspection.inspect { view in
            let isPrizeResultExist = view.isExist(viewWithId: "prizeGameResult")
      
            XCTAssertTrue(isPrizeResultExist)
        }
    
        ViewHosting.host(view: mybetDetailView)
        wait(for: [exp], timeout: 5)
    }
  
    func test_givenGameResultTypeIsBall_thenDisplayBallGameResult_KTO_TC_908() {
        let mybetDetail = NumberGameBetDetail(
            displayId: "12345678901234567890123456789012",
            traceId: "12345678901234567890123456789012",
            gameName: "So de -x - Siêu Tốc 1 phút",
            matchMethod: "(20230913-1074)",
            betContent: ["中三直选跨度 [中三_直选跨度]", "1,2,3,4,5"],
            betTime: Date().toLocalDateTime(.current),
            stakes: "50".toAccountCurrency(),
            status: NumberGameBetDetail.BetStatusSettledWinLose(winLoss: "50".toAccountCurrency()),
            resultType: .ball,
            _result: "1-2-3-4-5-6")
    
        let mybetDetailView = InspectWrapper {
            NumberGameMyBetDetailContent(myBetDetail: mybetDetail, page: 1, supportLocale: .Vietnam())
        }
    
        let exp = mybetDetailView.inspection.inspect { view in
            let isBallResultExist = view.isExist(viewWithId: "ballGameResult")
      
            XCTAssertTrue(isBallResultExist)
        }
    
        ViewHosting.host(view: mybetDetailView)
        wait(for: [exp], timeout: 5)
    }
  
    func test_givenGameUseTrackingMechanism_thenDisplayTraceID_KTO_TC_909() {
        let mybetDetail = NumberGameBetDetail(
            displayId: "12345678901234567890123456789012",
            traceId: "testTraceID",
            gameName: "So de -x - Siêu Tốc 1 phút",
            matchMethod: "(20230913-1074)",
            betContent: ["中三直选跨度 [中三_直选跨度]", "1,2,3,4,5"],
            betTime: Date().toLocalDateTime(.current),
            stakes: "50".toAccountCurrency(),
            status: NumberGameBetDetail.BetStatusSettledWinLose(winLoss: "50".toAccountCurrency()),
            resultType: .other,
            _result: "")
    
        let mybetDetailView = InspectWrapper {
            NumberGameMyBetDetailContent(myBetDetail: mybetDetail, page: 1, supportLocale: .Vietnam())
        }
    
        let exp = mybetDetailView.inspection.inspect { view in
            let traceIDText = try view
                .find(viewWithId: "subDescription")
                .localizedText()
                .string()
      
            XCTAssertEqual(expect: "testTraceID", actual: traceIDText)
        }
    
        ViewHosting.host(view: mybetDetailView)
        wait(for: [exp], timeout: 5)
    }
}

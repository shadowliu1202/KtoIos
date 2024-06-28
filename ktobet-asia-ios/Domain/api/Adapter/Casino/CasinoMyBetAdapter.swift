import Foundation
import sharedbu

class CasinoMyBetAdapter: CasinoMyBetProtocol {
    private let casinoMyBetAPI: CasinoMyBetAPI
  
    init(_ casinoMyBetAPI: CasinoMyBetAPI) {
        self.casinoMyBetAPI = casinoMyBetAPI
    }
  
    func getBetSummary() -> SingleWrapper<ResponseItem<BetSummaryBean>> {
        fatalError()
    }
  
    func getDetail(id: String) -> SingleWrapper<ResponseItem<RecordDetailBean>> {
        casinoMyBetAPI .getDetail(id: id)
    }
  
    func getIncompleteBetSummary() -> SingleWrapper<ResponseList<IncompleteDateSummaryBean>> {
        fatalError()
    }
  
    func getIncompleteRecord(date _: String) -> SingleWrapper<ResponseList<IncompleteRecordBean>> {
        fatalError()
    }
  
    func getPeriodSummary(date _: String) -> SingleWrapper<ResponseList<PeriodSummaryBean>> {
        fatalError()
    }
  
    func getRecords(
        lobbyId _: Int32,
        beginDate _: String,
        endDate _: String,
        itemOffset _: Int32,
        itemCount _: Int32)
        -> SingleWrapper<ResponseItem<PageBean>>
    {
        fatalError()
    }
}

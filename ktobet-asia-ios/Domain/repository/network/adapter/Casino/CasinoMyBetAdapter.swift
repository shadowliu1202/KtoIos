import Foundation
import SharedBu

class CasinoMyBetAdapter: CasinoMyBetProtocol {
  func getBetSummary() -> SingleWrapper<ResponseItem<BetSummaryBean>> {
    fatalError()
  }
  
  func getDetail(id _: String) -> SingleWrapper<ResponseItem<RecordDetailBean>> {
    fatalError()
  }
  
  func getIncompleteBetSummary() -> SingleWrapper<ResponseList<IncompleteDateSummaryBean>> {
    fatalError()
  }
  
  func getIncompleteRecord(date_ _: String) -> SingleWrapper<ResponseList<IncompleteRecordBean>> {
    fatalError()
  }
  
  func getPeriodSummary(date_ _: String) -> SingleWrapper<ResponseList<PeriodSummaryBean>> {
    fatalError()
  }
  
  func getRecords(
    lobbyId _: Int32,
    beginDate _: String,
    endDate _: String,
    itemOffset _: Int32,
    itemCount _: Int32) -> SingleWrapper<ResponseItem<PageBean>>
  {
    fatalError()
  }
}

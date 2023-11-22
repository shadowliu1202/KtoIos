import Combine
import RxSwift
import sharedbu
import SwiftUI

protocol IPrechatSurveyViewModel: AnyObject {
  var survey: CustomerServiceDTO.CSSurvey? { get }
  var isSubmitButtonDisable: Bool { get }
  
  func setup()
  func getSupportLocale() -> SupportLocale
}

final class PrechatSurveyViewModel:
  ErrorCollectViewModel,
  IPrechatSurveyViewModel,
  ObservableObject
{
  @Published private(set) var survey: CustomerServiceDTO.CSSurvey?
  @Published private(set) var isSubmitButtonDisable = true
  
  private let surveyAppService: ISurveyAppService
  private let playerConfiguration: PlayerConfiguration
  private let networkMonitor: INetworkMonitor
  
  private let disposeBag = DisposeBag()
  
  init(
    _ surveyAppService: ISurveyAppService,
    _ playerConfiguration: PlayerConfiguration,
    _ networkMonitor: INetworkMonitor)
  {
    self.surveyAppService = surveyAppService
    self.playerConfiguration = playerConfiguration
    self.networkMonitor = networkMonitor
  }
  
  func setup() {
    getPrechatSurvey()
    bindNetworkStatus()
  }
  
  private func getPrechatSurvey() {
    AnyPublisher.from(surveyAppService.getPreChatSurvey())
      .receive(on: DispatchQueue.main)
      .redirectErrors(to: self)
      .assignOptional(to: &$survey)
  }
  
  private func bindNetworkStatus() {
    networkMonitor.status
      .observe(on: MainScheduler.instance)
      .map {
        switch $0 {
        case .connected: return false
        case .disconnect,
             .reconnected: return true
        }
      }
      .subscribe(onNext: { [unowned self] in isSubmitButtonDisable = $0 })
      .disposed(by: disposeBag)
  }
  
  func getSupportLocale() -> SupportLocale {
    playerConfiguration.supportLocale
  }
}

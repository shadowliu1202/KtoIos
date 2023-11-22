import Combine
import sharedbu

protocol IExitSurveyViewModel {
  var survey: CustomerServiceDTO.CSSurvey? { get }
  
  func setup(roomID: String)
  func answerExitSurvey(_ roomID: String, _ answer: CustomerServiceDTO.CSSurveyAnswers?, onSubmitSuccess: () -> Void) async
  func getSupportLocale() -> SupportLocale
}

final class ExitSurveyViewModel:
  ErrorCollectViewModel,
  IExitSurveyViewModel,
  ObservableObject
{
  @Published private(set) var survey: CustomerServiceDTO.CSSurvey?
  
  private let surveyAppService: ISurveyAppService
  private let playerConfiguration: PlayerConfiguration
  
  init(
    _ surveyAppService: ISurveyAppService,
    _ playerConfiguration: PlayerConfiguration)
  {
    self.surveyAppService = surveyAppService
    self.playerConfiguration = playerConfiguration
  }
  
  func setup(roomID: String) {
    getPrechatSurvey(roomID)
  }
  
  private func getPrechatSurvey(_ roomID: String) {
    AnyPublisher.from(
      surveyAppService.getExitSurvey(roomId: roomID))
      .receive(on: DispatchQueue.main)
      .redirectErrors(to: self)
      .assignOptional(to: &$survey)
  }
  
  func answerExitSurvey(
    _ roomID: String,
    _ answer: CustomerServiceDTO.CSSurveyAnswers?,
    onSubmitSuccess: () -> Void) async
  {
    do {
      try await AnyPublisher.from(surveyAppService.answerExitSurvey(roomId: roomID, answer: answer)).value
      await MainActor.run { onSubmitSuccess() }
    }
    catch { collectError(error) }
  }
  
  func getSupportLocale() -> SupportLocale {
    playerConfiguration.supportLocale
  }
}

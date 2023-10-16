import Foundation
import sharedbu

class CSSurveyAdapter: CSSurveyProtocol {
  private let surveyAPI: SurveyAPI
  
  init(_ surveyAPI: SurveyAPI) {
    self.surveyAPI = surveyAPI
  }
  
  func answerSurvey(body: ExitAnswerSurvey) -> CompletableWrapper {
    surveyAPI
      .answerSurvey(bean: body)
      .asReaktiveCompletable()
  }
  
  func createOfflineSurvey(body: CreateOfflineBean_) -> CompletableWrapper {
    surveyAPI
      .createOfflineSurvey(bean: body)
      .asReaktiveCompletable()
  }
  
  func getSkillSurvey(type: Int32) -> SingleWrapper<ResponseItem<Survey_>> {
    surveyAPI
      .getSkillSurvey(type: type)
      .asReaktiveResponseItem(serial: Survey_.companion.serializer())
  }
}

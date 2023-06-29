import Foundation
import RxSwift
import SharedBu

class SurveyAPI: CustomServiceAPIConvertor {
  private let httpClient: HttpClient

  init(_ httpClient: HttpClient) {
    self.httpClient = httpClient
  }

  func getSkillSurvey(type: Int32) -> Single<String> {
    httpClient
      .requestJsonString(
        path: "onlinechat/api/survey/skill-survey",
        method: .get,
        task: .requestParameters(parameters: ["type": type]))
  }

  func createOfflineSurvey(bean: CreateOfflineBean_) -> Single<String> {
    httpClient
      .requestJsonString(
        path: "onlinechat/api/survey/create-offline",
        method: .post,
        task: .requestJSONEncodable(convert(createOfflineBean: bean)))
  }

  private func convert(createOfflineBean: CreateOfflineBean_) -> CustomerMessageData {
    .init(
      content: createOfflineBean.content,
      email: createOfflineBean.email,
      title: createOfflineBean.title)
  }

  func answerSurvey(bean: ExitAnswerSurvey) -> Single<String> {
    httpClient
      .requestJsonString(
        path: "onlinechat/api/survey/answer",
        method: .post,
        task: .requestJSONEncodable(convert(exitAnswerSurvey: bean)))
  }

  private func convert(exitAnswerSurvey: ExitAnswerSurvey) -> ExitAnswerSurveyBean {
    .init(
      questions:
      exitAnswerSurvey
        .questions
        .map {
          convert(question: $0)
        },
      roomId: exitAnswerSurvey.roomId,
      skillId: exitAnswerSurvey.skillId,
      surveyType: exitAnswerSurvey.surveyType)
  }
}

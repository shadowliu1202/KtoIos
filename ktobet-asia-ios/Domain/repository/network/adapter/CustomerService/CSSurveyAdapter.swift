import Foundation
import sharedbu

class CSSurveyAdapter: CSSurveyProtocol, CustomServiceAPIConvertor {
    private let httpClient: HttpClient

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }
  
    func answerSurvey(body: ExitAnswerSurvey) -> CompletableWrapper {
        httpClient
            .requestJsonString(
                path: "onlinechat/api/survey/answer",
                method: .post,
                task: .requestJSONEncodable(convert(exitAnswerSurvey: body)))
            .asReaktiveCompletable()
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

    func createOfflineSurvey(body: CreateOfflineBean_) -> CompletableWrapper {
        httpClient
            .requestJsonString(
                path: "onlinechat/api/survey/create-offline",
                method: .post,
                task: .requestJSONEncodable(convert(createOfflineBean: body)))
            .asReaktiveCompletable()
    }
  
    private func convert(createOfflineBean: CreateOfflineBean_) -> CustomerMessageData {
        .init(
            content: createOfflineBean.content,
            email: createOfflineBean.email,
            title: createOfflineBean.title)
    }
  
    func getSkillSurvey(type: Int32) -> SingleWrapper<ResponseItem<Survey>> {
        httpClient
            .requestJsonString(
                path: "onlinechat/api/survey/skill-survey",
                method: .get,
                task: .requestParameters(parameters: ["type": type]))
            .asReaktiveResponseItem(serial: Survey.companion.serializer())
    }
}

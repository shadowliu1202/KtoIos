import Foundation
import RxSwift
import SharedBu

protocol CustomerServiceSurveyUseCase {
  func getPreChatSurvey() -> Single<Survey>
  func getExitSurvey(skillId: SkillId) -> Single<Survey>
  func answerExitSurvey(roomId: RoomId, survey: Survey, surveyAnswers: SurveyAnswers) -> Completable
  func bindChatRoomWithSurvey(roomId: RoomId, connectId: ConnectId) -> Completable
  func createOfflineSurvey(message: String, email: String) -> Completable
}

class CustomerServiceSurveyUseCaseImpl: CustomerServiceSurveyUseCase {
  private var repo: CustomServiceRepository!
  private var surveyInfraService: SurveyInfraService!

  init(_ customServiceRepository: CustomServiceRepository, surveyInfraService: SurveyInfraService) {
    self.repo = customServiceRepository
    self.surveyInfraService = surveyInfraService
  }

  func getPreChatSurvey() -> Single<Survey> {
    surveyInfraService.getSurveygetChatHistoryQuestion(surveyType: Survey.SurveyType.prechat, skillId: nil)
  }

  func getExitSurvey(skillId: SkillId) -> Single<Survey> {
    surveyInfraService.getSurveygetChatHistoryQuestion(surveyType: Survey.SurveyType.exit, skillId: skillId)
  }

  func answerExitSurvey(roomId: RoomId, survey: Survey, surveyAnswers: SurveyAnswers) -> Completable {
    surveyInfraService.setOfflineSurveyAnswers(roomId: roomId, survey: survey, surveyAnswers: surveyAnswers)
  }

  func bindChatRoomWithSurvey(roomId: RoomId, connectId: ConnectId) -> Completable {
    surveyInfraService.connectSurveyWithChatRoom(surveyConnectionId: connectId, chatRoomId: roomId)
  }

  func createOfflineSurvey(message: String, email: String) -> Completable {
    surveyInfraService.createOfflineSurvey(message: message, email: email)
  }
}

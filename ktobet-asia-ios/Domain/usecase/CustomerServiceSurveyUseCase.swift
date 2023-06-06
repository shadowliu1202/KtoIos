import Foundation
import RxSwift
import SharedBu

protocol CustomerServiceSurveyUseCase {
  func getPreChatSurvey() -> Single<Survey>
  func getExitSurvey() -> Single<Survey>
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
    surveyInfraService.getSurveyGetChatHistoryQuestion(surveyType: Survey.SurveyType.prechat)
  }

  func getExitSurvey() -> Single<Survey> {
    surveyInfraService.getSurveyGetChatHistoryQuestion(surveyType: Survey.SurveyType.exit)
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

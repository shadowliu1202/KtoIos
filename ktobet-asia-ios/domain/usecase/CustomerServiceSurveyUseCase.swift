import Foundation
import SharedBu
import RxSwift

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
    
    init(_ customServiceRepository : CustomServiceRepository, surveyInfraService: SurveyInfraService) {
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
        surveyInfraService.setOfflineSurveyAnswers(roomId:roomId, survey: survey, surveyAnswers: surveyAnswers)
    }
    
    func bindChatRoomWithSurvey(roomId: RoomId, connectId: ConnectId) -> Completable {
        return surveyInfraService.connectSurveyWithChatRoom(surveyConnectionId: connectId, chatRoomId: roomId)
    }
    
    func createOfflineSurvey(message: String, email: String) -> Completable {
        return surveyInfraService.createOfflineSurvey(message: message, email: email)
    }
    
}

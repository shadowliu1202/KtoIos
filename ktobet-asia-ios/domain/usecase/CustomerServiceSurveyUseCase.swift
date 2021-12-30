import Foundation
import SharedBu
import RxSwift

protocol CustomerServiceSurveyUseCase {
//    func getPreChatSurvey(csSkillId: String?) -> Single<SurveyInformation>
    func getPreChatSurvey() -> Single<Survey>
    func answerPreChatSurvey(survey: Survey, surveyAnswers: SurveyAnswers) -> Single<SkillId>
    func getExitSurvey(skillId: SkillId) -> Single<Survey>
    func answerExitSurvey(roomId: RoomId, survey: Survey, surveyAnswers: SurveyAnswers) -> Single<SkillId>
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
    
    func answerPreChatSurvey(survey: Survey, surveyAnswers: SurveyAnswers) -> Single<SkillId> {
        return surveyInfraService.setSurveyAnswers(survey: survey, surveyAnswers: surveyAnswers)
    }
    
    func getExitSurvey(skillId: SkillId) -> Single<Survey> {
        surveyInfraService.getSurveygetChatHistoryQuestion(surveyType: Survey.SurveyType.exit, skillId: skillId)
    }
    
    func answerExitSurvey(roomId: RoomId, survey: Survey, surveyAnswers: SurveyAnswers) -> Single<SkillId> {
        return surveyInfraService.setSurveyAnswers(roomId:roomId, survey: survey, surveyAnswers: surveyAnswers)
    }
    
    func bindChatRoomWithSurvey(roomId: RoomId, connectId: ConnectId) -> Completable {
        return surveyInfraService.connectSurveyWithChatRoom(surveyConnectionId: connectId, chatRoomId: roomId)
    }
    
    func createOfflineSurvey(message: String, email: String) -> Completable {
        return surveyInfraService.createOfflineSurvey(message: message, email: email)
    }
    
}

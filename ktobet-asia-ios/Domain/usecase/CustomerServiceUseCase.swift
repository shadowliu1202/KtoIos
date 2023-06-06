import Foundation
import RxSwift
import SharedBu

protocol CustomerServiceUseCase {
  func currentChatRoom() -> Observable<PortalChatRoom>
  func searchChatRoom() -> Single<PortalChatRoom>
  func createChatRoom(survey: Survey, surveyAnswers: SurveyAnswers?) -> Single<PortalChatRoom>
  func bindChatRoomWithSurvey(roomId: RoomId, connectId: ConnectId) -> Completable
  func checkServiceAvailable() -> Single<Bool>
  func uploadImage(imageData: Data) -> Single<UploadImageDetail>

  func getBelongedSkillId(platform: Int) -> Single<String>
}

protocol ChatRoomHistoryUseCase {
  func deleteChatHistories(chatHistories: [ChatHistory], isExclude: Bool) -> Completable
  func getChatHistories(roomId: RoomId) -> Single<[ChatMessage]>
  func getChatHistorySummaries(page: Int) -> Single<(TotalCount, [ChatHistory])>
  func getChatHistorySummaries(page: Int, pageSize: Int) -> Single<(TotalCount, [ChatHistory])>
}

class CustomerServiceUseCaseImpl: CustomerServiceUseCase, ChatRoomHistoryUseCase {
  private var customServiceRepository: CustomServiceRepository
  private var customerInfraService: CustomerInfraService
  private var surveyInfraService: SurveyInfraService

  init(
    _ customServiceRepository: CustomServiceRepository,
    customerInfraService: CustomerInfraService,
    surveyInfraService: SurveyInfraService)
  {
    self.customServiceRepository = customServiceRepository
    self.customerInfraService = customerInfraService
    self.surveyInfraService = surveyInfraService
  }

  func currentChatRoom() -> Observable<PortalChatRoom> {
    customServiceRepository.currentChatRoom()
  }

  func searchChatRoom() -> Single<PortalChatRoom> {
    customerInfraService.isPlayerInChat().flatMap { [unowned self] chat in
      if chat.token.isEmpty {
        return Single.just(CustomServiceRepositoryImpl.PortalChatRoomNoExist)
      }
      else {
        return self.customServiceRepository.connectChatRoom(chat)
      }
    }
  }

  func createChatRoom(survey: Survey, surveyAnswers: SurveyAnswers?) -> Single<PortalChatRoom> {
    customServiceRepository.createRoom(survey: survey, surveyAnswers: surveyAnswers)
  }

  func bindChatRoomWithSurvey(roomId: RoomId, connectId: ConnectId) -> Completable {
    surveyInfraService.connectSurveyWithChatRoom(surveyConnectionId: connectId, chatRoomId: roomId)
  }

  func checkServiceAvailable() -> Single<Bool> {
    customerInfraService.checkCustomerServiceStatus()
  }

  func uploadImage(imageData: Data) -> Single<UploadImageDetail> {
    customerInfraService.uploadImage(imageData: imageData)
  }

  func getBelongedSkillId(platform _: Int) -> Single<String> {
    customServiceRepository.getBelongedSkillId(platform: 2)
  }

  func deleteChatHistories(chatHistories: [ChatHistory], isExclude: Bool) -> Completable {
    customServiceRepository.deleteSelectedHistories(chatHistory: chatHistories, isExclude: isExclude)
  }

  func getChatHistories(roomId: RoomId) -> Single<[ChatMessage]> {
    customServiceRepository.getChatHistory(roomId: roomId)
  }

  func getChatHistorySummaries(page: Int) -> Single<(TotalCount, [ChatHistory])> {
    getChatHistorySummaries(page: page, pageSize: 20)
  }

  func getChatHistorySummaries(page: Int, pageSize: Int) -> Single<(TotalCount, [ChatHistory])> {
    customerInfraService.queryChatHistory(page: page, pageSize: pageSize)
  }
}

import Combine
import sharedbu
import UIKit

protocol ChatRoomViewModelProtocol {
    var messages: [CustomerServiceDTO.ChatMessage] { get }
    var disableInputView: Bool { get }
  
    func setup(onChatRoomClose: @escaping (String) -> Void, onChatRoomMaintain: @escaping () -> Void)
    func send(message: String)
    func sendPreview(message: String)
    func readAllMessage(updateToLast: Bool?, isAuto: Bool?)
}

class ChatRoomViewModel:
    ErrorCollectViewModel,
    ChatRoomViewModelProtocol,
    ObservableObject
{
    @Published private(set) var messages: [CustomerServiceDTO.ChatMessage] = []
    @Published private(set) var disableInputView = false
  
    private var cancellables = Set<AnyCancellable>()
  
    private let chatAppService: IChatAppService
    private let surveyAppService: ISurveyAppService
    private let playerConfiguration: PlayerConfiguration
  
    init(
        _ chatAppService: IChatAppService,
        _ surveyAppService: ISurveyAppService,
        _ playerConfiguration: PlayerConfiguration)
    {
        self.chatAppService = chatAppService
        self.surveyAppService = surveyAppService
        self.playerConfiguration = playerConfiguration
    }
  
    func setup(onChatRoomClose: @escaping (String) -> Void, onChatRoomMaintain: @escaping () -> Void) {
        getChatRoomStatus(onChatRoomClose, onChatRoomMaintain)
        getMessages()
    }
  
    private func getChatRoomStatus(_ onChatRoomClose: @escaping (String) -> Void, _ onChatRoomMaintain: @escaping () -> Void) {
        AnyPublisher.from(chatAppService.observeChatRoom())
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: RunLoop.main)
            .redirectErrors(to: self)
            .sink(receiveValue: { [unowned self] chatRoom in
                disableInputView = chatRoom.status is sharedbu.Connection.StatusClose
                if chatRoom.status is sharedbu.Connection.StatusClose {
                    onChatRoomClose(chatRoom.roomId)
                }
        
                if chatRoom.isMaintained {
                    onChatRoomMaintain()
                }
            })
            .store(in: &cancellables)
    }
  
    private func getMessages() {
        AnyPublisher.from(chatAppService.observeChatRoom())
            .subscribe(on: DispatchQueue.global(qos: .background))
            .map {
                if $0.unReadMessage.isEmpty {
                    return $0.readMessage
                }
                else {
                    return $0.readMessage + [.unreadSeperator] + $0.unReadMessage
                }
            }
            .receive(on: RunLoop.main)
            .redirectErrors(to: self)
            .assign(to: &$messages)
    }
  
    func send(message: String) {
        AnyPublisher.from(chatAppService.send(message: message))
            .redirectErrors(to: self)
            .sink(receiveValue: { _ in })
            .store(in: &cancellables)
    }
  
    func sendPreview(message: String) {
        AnyPublisher.from(chatAppService.sendTypingMessage(message: message))
            .redirectErrors(to: self)
            .sink(receiveValue: { _ in })
            .store(in: &cancellables)
    }
  
    func readAllMessage(updateToLast: Bool? = nil, isAuto: Bool? = nil) {
        AnyPublisher.from(
            chatAppService.readAllMessage(
                updateToLast: updateToLast.map { KotlinBoolean(bool: $0) },
                isAuto: isAuto.map { KotlinBoolean(bool: $0) }))
            .redirectErrors(to: self)
            .sink(receiveValue: { _ in })
            .store(in: &cancellables)
    }
  
    func sendImages(images: [ImagePickerView.ImageAsset]) {
        AnyPublisher.from(chatAppService.send(images: images.map { ImagePath(uri: $0.asset.localIdentifier, extra: [:]) }))
            .receive(on: DispatchQueue.main)
            .redirectErrors(to: self)
            .sink(receiveValue: { _ in })
            .store(in: &cancellables)
    }
  
    @discardableResult
    func closeChatRoom() async -> String? {
        guard
            let exitChatDTO = await AnyPublisher.from(chatAppService.exit(forceExit: false))
                .redirectErrors(to: self)
                .valueWithoutError
        else { return nil }
    
        return exitChatDTO.roomId
    }
  
    func hasExitSurvey(_ roomID: String) async -> Bool {
        guard
            let hasExitSurvey = await AnyPublisher.from(surveyAppService.hasExitSurvey(roomId: roomID))
                .redirectErrors(to: self)
                .valueWithoutError
        else { return false }
    
        return hasExitSurvey.toBool()
    }
  
    func getSupportLocale() -> SupportLocale {
        playerConfiguration.supportLocale
    }
}

import Foundation
import SharedBu
import RxSwift
import Alamofire

extension ChatRoomSignalRClient: HubConnectionDelegate {
    func connectionDidOpen(hubConnection: HubConnection) { }
    func connectionDidFailToOpen(error: Error) { }
    func connectionDidClose(error: Error?) { }
}

class ChatRoomSignalRClient: PortalChatRoomChatService {
    var token: String
    var repository: CustomServiceRepository
    
    private let disposeBag = DisposeBag()
    private var socketConnect: HubConnection?
    private var onMessage: ((PortalChatRoom.ChatAction) -> ())?
    
    init(token: String, repository: CustomServiceRepository) {
        self.token = token
        self.repository = repository
    }
    
    func close(roomId: String) {
        repository.closeChatRoom(roomId: roomId)
            .andThen(repository.removeToken())
            .andThen(serviceDisconnect())
            .subscribe(onError: { print($0.localizedDescription) })
            .disposed(by: disposeBag)
    }
    
    deinit {
        print("deinit")
    }
    
    func getHistory(roomId: String) -> LoadingStatus<NSArray> {
        var messages: NSArray!
        let group = DispatchGroup()
        group.enter()
        var decodedObject: [InProcessResponse]!
        let url = URL(string: HttpClient().baseUrl.absoluteString + "onlinechat/api/chat-system/in-process/\(roomId)")!
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            decodedObject = try? JSONDecoder().decode(ResponseData<[InProcessResponse]>.self, from: data).data
            group.leave()
        }
        
        task.resume()
        
        group.wait()
        if let object = decodedObject {
            messages = object.map {
                ChatMessage.Message.init(id: $0.messageID,
                                         speaker: self.repository.convertSpeaker(speaker: $0.speaker, speakerType: $0.speakerType),
                                         message: self.repository.covertContentFromInProcess(messageType: $0.messageType,
                                                                                             html: $0.html,
                                                                                             text: $0.text,
                                                                                             speakerType: EnumMapper.convert(speakerType: $0.speakerType),
                                                                                             fileId: $0.fileID),
                                         createTimeTick: $0.createDate.toLocalDateTime())
            } as NSArray
            return LoadingStatus.init(status: .success, data: messages, message: "")
        } else {
            return LoadingStatus.init(status: .failed, data: messages, message: "")
        }
    }
    
    func receive(action: @escaping (PortalChatRoom.ChatAction) -> Void) {
        onMessage = action
    }
    
    func send(roomId: String, image: UploadImageDetail, onError: @escaping (KotlinThrowable) -> Void) {
        repository.send(image.portalImage.imageId, imageName: image.fileName, roomId: roomId)
            .subscribe(onError: { error in onError(KotlinThrowable.init(message: error.localizedDescription)) })
            .disposed(by: disposeBag)
    }
    
    func send(roomId: String, message: String, onError: @escaping (KotlinThrowable) -> Void) {
        repository.send(message, roomId: roomId)
            .subscribe(onError: { error in onError(KotlinThrowable.init(message: error.localizedDescription)) })
            .disposed(by: disposeBag)
    }
    
    func start(isReconnect: Bool) {
        self.socketConnect?.stop()
        self.socketConnect = nil
        
        if let url = URL(string: HttpClient().getHost().replacingOccurrences(of: "https", with: "wss") + "chat-ws?access_token=" + token) {
            self.socketConnect = HubConnectionBuilder.init(url: url)
                .withJSONHubProtocol()
                .withHttpConnectionOptions(configureHttpOptions: { (option) in
                    option.skipNegotiation = true
                })
                .withLogging(minLogLevel: .debug)
                .withAutoReconnect()
                .withHubConnectionDelegate(delegate: self)
                .build()
            
            self.socketConnect!.start()
            subscribeHub()
            if isReconnect {
                onMessage?(PortalChatRoom.ChatActionRefresh.init())
            }
        }
    }
    
    private func subscribeHub() {
        self.socketConnect?.on(method: ChatTarget.Queued.rawValue, callback: {[weak self] (arg: [Argument]) in
            self?.onMessage?(PortalChatRoom.ChatActionWaiting.init(rooms: arg.map{ $0.roomID }))
            print("chat room count: \(arg.count)")
        })
        
        self.socketConnect?.on(method: ChatTarget.Join.rawValue, callback: {[weak self] arg in
            let roomId = try arg.getArgument(type: String.self)
            self?.onMessage?(PortalChatRoom.ChatActionJoin.init(roomId: roomId))
            print("Join : \(roomId)")
        })
        
        self.socketConnect?.on(method: ChatTarget.DuplicateConnect.rawValue, callback: {})
        
        self.socketConnect?.on(method: ChatTarget.Message.rawValue, callback: { [weak self] (para1: String, speakerType: Int32, speaker: String, messageHtml: String, message: String, messageId: Int32, localDateTime: String, messageType: Int32, fieldId: String?, para10: Bool) in
            guard let self = self else { return }
            let message = ChatMessage.Message(
                id: messageId,
                speaker: self.repository.convertSpeaker(speaker: speaker, speakerType: speakerType),
                message: self.repository.covertContentFromInProcess(messageType: messageType,
                                                                    html: messageHtml,
                                                                    text: message,
                                                                    speakerType: EnumMapper.convert(speakerType: speakerType),
                                                                    fileId: fieldId),
                createTimeTick: localDateTime.toLocalDateTime())
            self.onMessage?(PortalChatRoom.ChatActionMessage.init(message: message))
            print("Message : \(message)")
        })
        
        self.socketConnect?.on(method: ChatTarget.Close.rawValue, callback: {[weak self] (roomId: String, message: String, date: String) in
            self?.onMessage?(PortalChatRoom.ChatActionClose.init(message: message, speakerName: roomId, localDateTime: date.toLocalDateTime()))
            print("RoomId : \(roomId)")
            print("Date : \(date)")
            print("Message : \(message)")
        })
        
        self.socketConnect?.on(method: ChatTarget.Dispatched.rawValue, callback: {[weak self] (roomId: String, para2: String, para3: String) in
            self?.onMessage?(PortalChatRoom.ChatActionDispatched.init(roomId: roomId))
            print("Dispatched \(roomId), \(para2), \(para3)")
        })
    }
    
    private func serviceDisconnect() -> Completable {
        Completable.create { completable in
            self.disconnect()
            completable(.completed)
            return Disposables.create {}
        }
    }
    
    func disconnect() {
        self.socketConnect?.stop()
        self.socketConnect = nil
    }
}

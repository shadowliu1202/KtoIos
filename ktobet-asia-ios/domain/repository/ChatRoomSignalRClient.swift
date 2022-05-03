import Foundation
import SharedBu
import RxSwift
import Alamofire
import Moya

extension ChatRoomSignalRClient: HubConnectionDelegate {
    func connectionDidOpen(hubConnection: HubConnection) { }
    func connectionDidFailToOpen(error: Error) { }
    func connectionWillReconnect(error: Error) {
        customerInfraService.isPlayerInChat().asObservable().retry()
        .subscribe(onNext: { [weak self]  in
            self?.refreshChatRoomState($0)
        }).disposed(by: disposeBag)
    }
    func connectionDidClose(error: Error?) { }
}

class ChatRoomSignalRClient: PortalChatRoomChatService {
    var token: String
    var roomId: String
    var skillId: String
    var repository: CustomServiceRepository
    var customerInfraService: CustomerInfraService
    private let disposeBag = DisposeBag()
    private var socketConnect: HubConnection?
    private var onMessage: ((PortalChatRoom.ChatAction) -> ())?
    
    init(token: String, skillId: String, roomId: String, repository: CustomServiceRepository, customerInfraService: CustomerInfraService) {
        self.token = token
        self.skillId = skillId
        self.roomId = roomId
        self.repository = repository
        self.customerInfraService = customerInfraService
    }
    
    convenience init(token: String, repository: CustomServiceRepository, customerInfraService: CustomerInfraService) {
        self.init(token: token, skillId: "", roomId: "", repository: repository, customerInfraService: customerInfraService)
    }

    
    func close(roomId: String, onFinished: @escaping () -> Void) {
        repository.closeChatRoom(roomId: roomId)
            .andThen(repository.removeToken())
            .andThen(serviceDisconnect())
            .subscribe(onCompleted: {
                onFinished()
            }, onError: {
                print($0.localizedDescription)
                onFinished()
            })
            .disposed(by: disposeBag)
    }
    
    deinit {
        print("deinit")
    }
    
    func getHistory(roomId: String) -> LoadingStatus<NSArray> {
        var messages: NSArray?
        if isPlayerInChat() {
            messages = getInProcessChatMessageHistory()
        } else {
            messages = getChatHistory(roomId)
        }
        let status: Status = messages != nil ? .success : .failed
        return  LoadingStatus.init(status: status, data: messages, message: "")
    }
    
    private func isPlayerInChat() -> Bool {
        if let roomId = getPlayerInChat()?.roomId, roomId.isNotEmpty {
            return true
        }
        return false
    }
    
    private func getInProcessChatMessageHistory() -> NSArray? {
        let group = DispatchGroup()
        group.enter()
        var decodedObject: [InProcessBean]!
        let url = URL(string: HttpClient().baseUrl.absoluteString + "onlinechat/api/room/in-process")!
        let urlSession = generateUrlSession()
        let task = urlSession.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            decodedObject = try? JSONDecoder().decode(ResponseData<[InProcessBean]>.self, from: data).data
            group.leave()
        }

        task.resume()
        
        group.wait()
        if let object = decodedObject {
            let messages = object.map {
                ChatMessage.Message(id: $0.messageId,
                                    speaker: self.repository.convertSpeaker(speaker: $0.speaker, speakerType: $0.speakerType),
                                    message: self.repository.covertContentFromInProcess(message: $0.message, speakerType: EnumMapper.convert(speakerType: $0.speakerType)),
                                    createTimeTick: $0.createdDate.toLocalDateTime())
            } as NSArray
            return messages
        } else {
            return nil
        }
    }
    
    private func getChatHistory(_ roomId: String) -> NSArray? {
        let group = DispatchGroup()
        group.enter()
        var decodedObject: [RoomHistory]!
        let url = URL(string: HttpClient().baseUrl.absoluteString + "api/room/record/\(roomId)")!
        let urlSession = generateUrlSession()
        let task = urlSession.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            decodedObject = try? JSONDecoder().decode(ResponseData<ChatHistoryBean>.self, from: data).data?.roomHistories
            group.leave()
        }

        task.resume()
        
        group.wait()
        if let object = decodedObject {
            let messages = object.map {
                ChatMessage.Message(id: $0.messageId,
                                    speaker: self.repository.convertSpeaker(speaker: $0.speaker, speakerType: $0.speakerType),
                                    message: self.repository.covertContentFromInProcess(message: $0.message, speakerType: EnumMapper.convert(speakerType: $0.speakerType)),
                                    createTimeTick: $0.createdDate.toLocalDateTime())
            } as NSArray
            return messages
        } else {
            return nil
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
        repository.send(message, roomId: roomId).subscribe {
            print("Completable")
        } onError: { error in
            print(error)
            let e = ExceptionFactory.create(error)
            onError(e)
        }.disposed(by: disposeBag)
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
            
            if !self.roomId.isEmpty {
                if let object = getQueueNumber() {
                    onMessage?(PortalChatRoom.ChatActionInitChatRoom.init(roomId: self.roomId, skillId: self.skillId, queue: object))
                }
            } else {
                if let number = getQueueNumber(), let bean = getPlayerInChat() {
                    onMessage?(PortalChatRoom.ChatActionInitChatRoom.init(roomId: bean.roomId!, skillId: bean.skillId!, queue: number))
                }
            }
        }
    }
    
    private func getQueueNumber() -> Int32? {
        let group = DispatchGroup()
        group.enter()
        var decodedObject: Int32?
        let url = URL(string: HttpClient().baseUrl.absoluteString + "onlinechat/api/room/queue-number")!
        let urlSession = generateUrlSession()
        let task = urlSession.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            decodedObject = try? JSONDecoder().decode(ResponseData<Int32>.self, from: data).data
            group.leave()
        }
        
        task.resume()
        
        group.wait()
        
        return decodedObject
    }
    
    private func refreshChatRoomState(_ bean: PlayerInChatBean) {
        if let token = bean.token, token.isNotEmpty  {
            skillId = bean.skillId!
            roomId = bean.roomId!
            start(isReconnect: true)
        } else {
            refreshAndDisconnect()
        }
    }
    
    private func refreshAndDisconnect() {
        onMessage?(PortalChatRoom.ChatActionRefresh.init())
        onMessage?(PortalChatRoom.ChatActionClose.init())
    }
    
    private func getPlayerInChat() -> PlayerInChatBean? {
        let group = DispatchGroup()
        group.enter()
        var decodedObject: PlayerInChatBean?
        let url = URL(string: HttpClient().baseUrl.absoluteString + "onlinechat/api/room/player/in-chat")!
        let urlSession = generateUrlSession()
        let task = urlSession.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            decodedObject = try? JSONDecoder().decode(ResponseData<PlayerInChatBean>.self, from: data).data
            group.leave()
        }
        
        task.resume()
        
        group.wait()
        
        return decodedObject
    }
    
    private func generateUrlSession() -> URLSession {
        if Configuration.disableSSL {
            return URLSession(configuration: .default, delegate: NSURLSessionPinningDelegate(), delegateQueue: nil)
        } else {
            return URLSession.shared
        }
    }
    
    private func subscribeHub() {
        self.socketConnect?.on(method: Target.QueueNumberAsync.rawValue, callback: {
            self.onMessage?(PortalChatRoom.ChatActionWaiting.init())
        })

        self.socketConnect?.on(method: Target.UserJoinAsync.rawValue, callback: {
            self.onMessage?(PortalChatRoom.ChatActionCSAnswer.init())
        })

        self.socketConnect?.on(method: Target.SpeakingAsync.rawValue, callback: {[weak self] (bean: SpeakingAsyncBean) in
            self?.onMessage?(PortalChatRoom.ChatActionMessage.init(message: ChatMapper.mapTo(speakingAsyncBean: bean)))
        })

        self.socketConnect?.on(method: Target.StopRoomAsync.rawValue, callback: {[weak self] (id: String) in
            self?.onMessage?(PortalChatRoom.ChatActionClose.init())
        })
        
        self.socketConnect?.on(method: Target.MaintenanceAsync.rawValue, callback: {[weak self] _ in
            self?.onMessage?(PortalChatRoom.ChatActionMaintenance.init())
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
    
    private enum Target: String {
        case UserJoinAsync
        case SpeakingAsync
        case QueueNumberAsync
        case StopRoomAsync
        case MaintenanceAsync
    }

}

struct SpeakingAsyncBean: Codable {
    let createdDate: String
    let message: Message
    let messageId: Int32
    let messageType: Int
    let playerRead: Bool
    let roomId: String
    let speaker: String
    let speakerId: String
    let speakerType: Int32
    let text: String
}

class NSURLSessionPinningDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.host == Configuration.hostName {
            completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

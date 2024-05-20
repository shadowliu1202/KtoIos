import Foundation
import Moya
import RxSwift
import sharedbu

class CSAdapter: CustomerServiceProtocol, CustomServiceAPIConvertor {
    private let httpClient: HttpClient

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func createRoom(bean: PreChatAnswerSurvey?) -> SingleWrapper<ResponseItem<NSString>> {
        var codableBean: Encodable = .empty
        if let bean {
            codableBean = convert(surveyAnswers: bean.answerSurvey)
        }
    
        return httpClient
            .requestJsonString(
                path: "onlinechat/api/room",
                method: .post,
                task: .requestJSONEncodable(codableBean))
            .asReaktiveResponseItem()
    }
  
    private func convert(surveyAnswers: AnswerSurvey_) -> PreChatAnswerSurveyBean {
        PreChatAnswerSurveyBean(
            answerSurvey: AnswerSurveyBean(
                questions: surveyAnswers.questions
                    .map {
                        convert(question: $0)
                    }))
    }

    func getCustomerServiceStatus() -> SingleWrapper<ResponseItem<KotlinBoolean>> {
        httpClient
            .requestJsonString(
                path: "onlinechat/api/room/cs-status",
                method: .get)
            .asReaktiveResponseItem()
    }

    func getInProcess() -> SingleWrapper<ResponseList<InProcessBean_>> {
        httpClient
            .requestJsonString(
                path: "onlinechat/api/room/in-process",
                method: .get)
            .asReaktiveResponseList(serial: InProcessBean_.companion.serializer())
    }

    func getPlayerInChat() -> SingleWrapper<ResponseItem<PlayerInChatBean_>> {
        httpClient
            .requestJsonString(
                path: "onlinechat/api/room/player/in-chat",
                method: .get)
            .asReaktiveResponseItem(serial: PlayerInChatBean_.companion.serializer())
    }

    func getQueueNumber() -> SingleWrapper<ResponseItem<KotlinInt>> {
        httpClient
            .requestJsonString(
                path: "onlinechat/api/room/queue-number",
                method: .get)
            .asReaktiveResponseItem { (number: NSNumber) -> KotlinInt in
                KotlinInt(int: number.int32Value)
            }
    }

    func playerClose() -> SingleWrapper<ResponseItem<NSString>> {
        httpClient
            .requestJsonString(
                path: "onlinechat/api/room/player/close",
                method: .post)
            .asReaktiveResponseItem { (item: Any) -> NSString in
                item is NSNull ? "" : item as! NSString
            }
    }

    func removeChatRoomToken() -> CompletableWrapper {
        httpClient
            .requestJsonString(
                path: "onlinechat/api/common/remove-token",
                method: .post)
            .asReaktiveCompletable()
    }

    func send(bean: SendBean_) -> SingleWrapper<ResponseItem<NSString>> {
        httpClient
            .requestJsonString(
                path: "onlinechat/api/room/send",
                method: .post,
                task: .requestJSONEncodable(convert(sendBean: bean)))
            .asReaktiveResponseItem { (item: Any) -> NSString in
                item is NSNull ? "" : item as! NSString
            }
    }
  
    private func convert(sendBean: SendBean_) -> SendBean {
        .init(
            message: convert(messageBean: sendBean.message),
            roomId: sendBean.roomId)
    }
  
    private func convert(messageBean: MessageBean) -> Message {
        .init(
            quillDeltas: messageBean.quillDeltas.map {
                convert(quillDeltaBean: $0)
            })
    }

    private func convert(quillDeltaBean: QuillDeltaBean) -> QuillDelta {
        .init(
            attributes: convert(attributes: quillDeltaBean.attributes),
            insert: quillDeltaBean.insert)
    }

    private func convert(attributes: Attributes_?) -> Attributes? {
        .init(
            align: attributes?.align?.intValue,
            background: attributes?.background,
            bold: attributes?.bold?.boolValue,
            color: attributes?.color,
            font: attributes?.font,
            image: attributes?.image,
            italic: attributes?.italic?.boolValue,
            link: attributes?.link,
            size: attributes?.size,
            underline: attributes?.underline?.boolValue)
    }

    func send(bean: SendImageBean_) -> SingleWrapper<ResponseItem<NSString>> {
        httpClient
            .requestJsonString(
                path: "onlinechat/api/room/send",
                method: .post,
                task: .requestJSONEncodable(convert(sendImageBean: bean)))
            .asReaktiveResponseItem { (item: Any) -> NSString in
                item is NSNull ? "" : item as! NSString
            }
    }
  
    private func convert(sendImageBean: SendImageBean_) -> SendBean {
        .init(
            message: convert(message: sendImageBean.message),
            roomId: sendImageBean.roomId)
    }

    private func convert(message: SendImageBean_.Message) -> Message {
        .init(
            quillDeltas:
            message.quillDeltas.map {
                convert(quillDelta: $0)
            })
    }

    private func convert(quillDelta: SendImageBean_.QuillDelta) -> QuillDelta {
        .init(
            attributes: convert(attributes: quillDelta.attributes),
            insert: quillDelta.insert)
    }

    private func convert(attributes: SendImageBean_.Attributes) -> Attributes {
        .init(image: attributes.image)
    }
  
    func upload(imagePath: ImagePath) -> SingleWrapper<ImageToken> {
        guard let (chunks, imageSize) = ImageSplitter.processImage(by: imagePath.uri)
        else { return Single<ImageToken>.error(KTOError.EmptyData).asWrapper() }
    
        let imageFileName = UUID().uuidString + ".jpeg"
    
        return Single<ImageToken>.create(subscribe: { single in
            let subscription = Observable.from(Array(chunks.enumerated()))
                .concatMap { index, chunk in
                    let mimiType = "image/jpeg"
                    let totalSize = imageSize
                    let dataLen = imageSize
                    let fullChunks = Int(dataLen / ImageSplitter.chunkSize)
                    let totalChunks = fullChunks + (dataLen % 1024 != 0 ? 1 : 0)
          
                    let chunkImageDetil = ChunkImageDetil(
                        resumableChunkNumber: String(index + 1),
                        resumableChunkSize: String(ImageSplitter.chunkSize),
                        resumableCurrentChunkSize: String(chunk.count),
                        resumableTotalSize: String(totalSize),
                        resumableType: mimiType,
                        resumableIdentifier: imageFileName,
                        resumableFilename: imageFileName,
                        resumableRelativePath: imageFileName,
                        resumableTotalChunks: String(chunks.count),
                        file: chunk)
          
                    let m1 = MultipartFormData(
                        provider: .data(String(index + 1).data(using: .utf8)!),
                        name: "resumableChunkNumber")
                    let m2 = MultipartFormData(
                        provider: .data(String(chunk.count).data(using: .utf8)!),
                        name: "resumableChunkSize")
                    let m3 = MultipartFormData(
                        provider: .data(String(chunk.count).data(using: .utf8)!),
                        name: "resumableCurrentChunkSize")
                    let m4 = MultipartFormData(provider: .data(String(totalSize).data(using: .utf8)!), name: "resumableTotalSize")
                    let m5 = MultipartFormData(provider: .data(mimiType.data(using: .utf8)!), name: "resumableType")
                    let m6 = MultipartFormData(provider: .data(imageFileName.data(using: .utf8)!), name: "resumableIdentifier")
                    let m7 = MultipartFormData(provider: .data(imageFileName.data(using: .utf8)!), name: "resumableFilename")
                    let m8 = MultipartFormData(provider: .data(imageFileName.data(using: .utf8)!), name: "resumableRelativePath")
                    let m9 = MultipartFormData(
                        provider: .data(String(chunks.count).data(using: .utf8)!),
                        name: "resumableTotalChunks")
                    let multiPartData = MultipartFormData(
                        provider: .data(chunk),
                        name: "file",
                        fileName: imageFileName,
                        mimeType: mimiType)
                    let query = try self.createQuery(chunkImageDetil: chunkImageDetil)
          
                    let target = APITarget(
                        baseUrl: self.httpClient.host,
                        path: "onlinechat/api/image/upload",
                        method: .post,
                        task: .uploadCompositeMultipart(
                            [m1, m2, m3, m4, m5, m6, m7, m8, m9, multiPartData],
                            urlParameters: query),
                        header: self.httpClient.headers)
          
                    return self.httpClient.request(target)
                        .map(ResponseData<String>.self)
                        .map { $0.data ?? "" }
                }
                .takeLast(1)
                .do(onNext: {
                    let imageToken: ImageToken = .init(token: $0)
                    single(.success(imageToken))
                })
                .subscribe()

            return Disposables.create { subscription.dispose() }
        })
        .asWrapper()
    }

    private func createQuery(chunkImageDetil: ChunkImageDetil) throws -> [String: Any] {
        let encoder = JSONEncoder()
    
        let data = try encoder.encode(chunkImageDetil)
        var query = try (JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any])!

        if let idx = query.index(forKey: "file") {
            query.remove(at: idx)
        }

        return query
    }
  
    func upload(imagePath _: String) -> SingleWrapper<ImageToken> {
        fatalError("not implemented")
    }
}

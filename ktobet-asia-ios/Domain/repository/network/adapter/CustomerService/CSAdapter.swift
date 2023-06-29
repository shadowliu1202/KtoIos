import Foundation
import Moya
import RxSwift
import SharedBu

class CSAdapter: CustomerServiceProtocol {
  private let customServiceApi: CustomServiceAPI

  init(_ customServiceApi: CustomServiceAPI) {
    self.customServiceApi = customServiceApi
  }

  func createRoom(bean: PreChatAnswerSurvey?) -> SingleWrapper<ResponseItem<NSString>> {
    customServiceApi
      .createRoom(bean)
      .asReaktiveResponseItem()
  }

  func getCustomerServiceStatus() -> SingleWrapper<ResponseItem<KotlinBoolean>> {
    customServiceApi
      .getCustomerServiceStatus()
      .asReaktiveResponseItem()
  }

  func getInProcess() -> SingleWrapper<ResponseList<InProcessBean_>> {
    customServiceApi
      .getInProcess()
      .asReaktiveResponseList(serial: InProcessBean_.companion.serializer())
  }

  func getPlayerInChat() -> SingleWrapper<ResponseItem<PlayerInChatBean_>> {
    customServiceApi
      .getPlayerInChat()
      .asReaktiveResponseItem(serial: PlayerInChatBean_.companion.serializer())
  }

  func getQueueNumber() -> SingleWrapper<ResponseItem<KotlinInt>> {
    customServiceApi
      .getQueueNumber()
      .asReaktiveResponseItem { (number: NSNumber) -> KotlinInt in
        KotlinInt(int: number.int32Value)
      }
  }

  func playerClose() -> SingleWrapper<ResponseItem<NSString>> {
    customServiceApi
      .playerClose()
      .asReaktiveResponseItem { (item: Any) -> NSString in
        item is NSNull ? "" : item as! NSString
      }
  }

  func removeChatRoomToken() -> CompletableWrapper {
    customServiceApi
      .removeChatRoomToken()
      .asReaktiveCompletable()
  }

  func send(bean: SendBean_) -> SingleWrapper<ResponseItem<NSString>> {
    customServiceApi
      .send(bean: bean)
      .asReaktiveResponseItem { (item: Any) -> NSString in
        item is NSNull ? "" : item as! NSString
      }
  }

  func send(bean_: SendImageBean_) -> SingleWrapper<ResponseItem<NSString>> {
    customServiceApi
      .send(bean: bean_)
      .asReaktiveResponseItem { (item: Any) -> NSString in
        item is NSNull ? "" : item as! NSString
      }
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
          
          let m1 = MultipartFormData(provider: .data(String(index + 1).data(using: .utf8)!), name: "resumableChunkNumber")
          let m2 = MultipartFormData(provider: .data(String(chunk.count).data(using: .utf8)!), name: "resumableChunkSize")
          let m3 = MultipartFormData(
            provider: .data(String(chunk.count).data(using: .utf8)!),
            name: "resumableCurrentChunkSize")
          let m4 = MultipartFormData(provider: .data(String(totalSize).data(using: .utf8)!), name: "resumableTotalSize")
          let m5 = MultipartFormData(provider: .data(mimiType.data(using: .utf8)!), name: "resumableType")
          let m6 = MultipartFormData(provider: .data(imageFileName.data(using: .utf8)!), name: "resumableIdentifier")
          let m7 = MultipartFormData(provider: .data(imageFileName.data(using: .utf8)!), name: "resumableFilename")
          let m8 = MultipartFormData(provider: .data(imageFileName.data(using: .utf8)!), name: "resumableRelativePath")
          let m9 = MultipartFormData(provider: .data(String(chunks.count).data(using: .utf8)!), name: "resumableTotalChunks")
          let multiPartData = MultipartFormData(provider: .data(chunk), name: "file", fileName: imageFileName, mimeType: mimiType)
          let query = self.createQuery(chunkImageDetil: chunkImageDetil)
          
          return self.customServiceApi.uploadImage(query: query, imageData: [m1, m2, m3, m4, m5, m6, m7, m8, m9, multiPartData])
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

  private func createQuery(chunkImageDetil: ChunkImageDetil) -> [String: Any] {
    var query: [String: Any] = [:]
    do {
      let encoder = JSONEncoder()
      let data = try encoder.encode(chunkImageDetil)
      query = try (JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any])!
    }
    catch {
      Logger.shared.debug(error.localizedDescription)
    }

    if let idx = query.index(forKey: "file") {
      query.remove(at: idx)
    }

    return query
  }
}

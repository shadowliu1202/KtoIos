import Foundation
import Moya
import RxSwift
import sharedbu

protocol ImageRepository {
  var imageApi: ImageApiProtocol { get }
  func uploadImage(imageData: Data) -> Single<UploadImage>
}

class ImageRepositoryImpl: ImageRepository {
  var imageApi: ImageApiProtocol

  init(_ imageApi: ImageApi) {
    self.imageApi = imageApi
  }
  
  func uploadImagePath(_ imagePath: ImagePath) -> SingleWrapper<ImageToken> {
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
          
          let chunkImageDetail = ChunkImageDetil(
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
          let query = try self.createQuery(chunkImageDetil: chunkImageDetail)
          
          return self.imageApi.uploadImage(query: query, imageData: [m1, m2, m3, m4, m5, m6, m7, m8, m9, multiPartData])
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
  
  func uploadImage(imageData: Data) -> Single<UploadImage> {
    do {
      let fileName = UUID().uuidString + ".jpeg"
      let requests = try createUploadRequests(imageData: imageData, uuid: fileName)

      return Single<UploadImage>.create(subscribe: { single in
        let subscription = Observable
          .concat(requests)
          .takeLast(1)
          .do(onNext: {
            let image = UploadImage(imageToken: ImageToken(token: $0), fileName: fileName)
            single(.success(image))
          })
          .subscribe()

        return Disposables.create { subscription.dispose() }
      })
    }
    catch {
      return .error(error)
    }
  }

  private func createUploadRequests(imageData: Data, uuid: String) throws -> [Observable<String>] {
    var chunks: [Data] = []
    var requests: [Observable<String>] = []
    let mimiType = "image/jpeg"
    let totalSize = imageData.count
    let dataLen = imageData.count
    let chunkSize = 512 * 1024
    let fullChunks = Int(dataLen / chunkSize)
    let totalChunks = fullChunks + (dataLen % 1024 != 0 ? 1 : 0)
    for chunkCounter in 0..<totalChunks {
      var chunk: Data
      let chunkBase = chunkCounter * chunkSize
      var diff = chunkSize
      if chunkCounter == totalChunks - 1 {
        diff = dataLen - chunkBase
      }

      chunk = imageData.subdata(in: chunkBase..<(chunkBase + diff))
      chunks.append(chunk)
    }

    for (index, chunk) in chunks.enumerated() {
      let chunkImageDetil = ChunkImageDetil(
        resumableChunkNumber: String(index + 1),
        resumableChunkSize: String(chunkSize),
        resumableCurrentChunkSize: String(chunk.count),
        resumableTotalSize: String(totalSize),
        resumableType: mimiType,
        resumableIdentifier: uuid,
        resumableFilename: uuid,
        resumableRelativePath: uuid,
        resumableTotalChunks: String(chunks.count),
        file: chunk)
      let m1 = MultipartFormData(provider: .data(String(index + 1).data(using: .utf8)!), name: "resumableChunkNumber")
      let m2 = MultipartFormData(provider: .data(String(chunk.count).data(using: .utf8)!), name: "resumableChunkSize")
      let m3 = MultipartFormData(
        provider: .data(String(chunk.count).data(using: .utf8)!),
        name: "resumableCurrentChunkSize")
      let m4 = MultipartFormData(provider: .data(String(totalSize).data(using: .utf8)!), name: "resumableTotalSize")
      let m5 = MultipartFormData(provider: .data(mimiType.data(using: .utf8)!), name: "resumableType")
      let m6 = MultipartFormData(provider: .data(uuid.data(using: .utf8)!), name: "resumableIdentifier")
      let m7 = MultipartFormData(provider: .data(uuid.data(using: .utf8)!), name: "resumableFilename")
      let m8 = MultipartFormData(provider: .data(uuid.data(using: .utf8)!), name: "resumableRelativePath")
      let m9 = MultipartFormData(provider: .data(String(chunks.count).data(using: .utf8)!), name: "resumableTotalChunks")
      let multiPartData = MultipartFormData(provider: .data(chunk), name: "file", fileName: uuid, mimeType: mimiType)
      let query = try createQuery(chunkImageDetil: chunkImageDetil)
      requests
        .append(
          imageApi.uploadImage(query: query, imageData: [m1, m2, m3, m4, m5, m6, m7, m8, m9, multiPartData])
            .map { $0.data ?? "" }
            .asObservable())
    }

    return requests
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
}

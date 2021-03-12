import Foundation
import RxSwift
import Moya
import share_bu

protocol ImageRepository {
    func uploadImage(imageData: Data) -> Single<UploadImageDetail>
}

class ImageRepositoryImpl: ImageRepository {
    private var imageApi: ImageApi!

    init(_ imageApi: ImageApi) {
        self.imageApi = imageApi
    }

    func uploadImage(imageData: Data) -> Single<UploadImageDetail> {
        let uuid = UUID().uuidString + ".jpeg"
        let completables = createChunks(imageData: imageData, uuid: uuid)
        return Single.zip(completables).flatMap { (tokens) -> Single<UploadImageDetail> in
            let token = tokens.filter { $0.count != 0 }
            let uploadImageDetail = UploadImageDetail(uriString: uuid, portalImage: PortalImage.Private.init(imageId: token.first!, fileName: uuid, host: uuid), fileName: uuid)
            return Single.just(uploadImageDetail)
        }
    }

    private func createChunks(imageData: Data, uuid: String) -> [Single<String>] {
        var chunks: [Data] = []
        var completables: [Single<String>] = []
        let mimiType = "image/jpeg"
        let totalSize = imageData.count
        let dataLen = imageData.count
        let chunkSize = 819200
        let fullChunks = Int(dataLen / chunkSize)
        let totalChunks = fullChunks + (dataLen % 1024 != 0 ? 1 : 0)
        for chunkCounter in 0..<totalChunks {
            var chunk:Data
            let chunkBase = chunkCounter * chunkSize
            var diff = chunkSize
            if(chunkCounter == totalChunks - 1) {
                diff = dataLen - chunkBase
            }
            
            chunk = imageData.subdata(in: chunkBase..<(chunkBase + diff))
            chunks.append(chunk)
        }
        
        for (index, chunk) in chunks.enumerated() {
            let chunkImageDetil = ChunkImageDetil(resumableChunkNumber: String(index + 1),
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
            let m3 = MultipartFormData(provider: .data(String(chunk.count).data(using: .utf8)!), name: "resumableCurrentChunkSize")
            let m4 = MultipartFormData(provider: .data(String(totalSize).data(using: .utf8)!), name: "resumableTotalSize")
            let m5 = MultipartFormData(provider: .data(mimiType.data(using: .utf8)!), name: "resumableType")
            let m6 = MultipartFormData(provider: .data(uuid.data(using: .utf8)!), name: "resumableIdentifier")
            let m7 = MultipartFormData(provider: .data(uuid.data(using: .utf8)!), name: "resumableFilename")
            let m8 = MultipartFormData(provider: .data(uuid.data(using: .utf8)!), name: "resumableRelativePath")
            let m9 = MultipartFormData(provider: .data(String(chunks.count).data(using: .utf8)!), name: "resumableTotalChunks")
            let multiPartData = MultipartFormData(provider: .data(chunk), name: "file", fileName: uuid, mimeType: mimiType)
            let query = createQuery(chunkImageDetil: chunkImageDetil)
            completables.append(imageApi.uploadImage(query: query, imageData: [m1,m2,m3,m4,m5,m6,m7,m8,m9,multiPartData]).map { $0.data ?? "" })
        }
        
        return completables
    }
    
    private func createQuery(chunkImageDetil: ChunkImageDetil) -> [String: Any] {
        var query: [String: Any] = [:]
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(chunkImageDetil)
            query = try (JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any>)!
        } catch {
            print(error)
        }
        
        if let idx = query.index(forKey: "file") {
            query.remove(at: idx)
        }
        
        return query
    }
}

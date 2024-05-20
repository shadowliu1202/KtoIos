import Foundation
import sharedbu

class ImageAdapter: ImageProtocol {
    private var imageApi: ImageApi!

    init(_ imageApi: ImageApi) {
        self.imageApi = imageApi
    }

    func getImageHash(imageId: String) -> SingleWrapper<ResponseItem<NSString>> {
        imageApi.getPrivateImageToken(imageId: imageId).asReaktiveResponseItem()
    }
  
    func uploadImage(imagePath _: ImagePath) -> SingleWrapper<ImageDataBean> {
        fatalError("TODO")
    }
}

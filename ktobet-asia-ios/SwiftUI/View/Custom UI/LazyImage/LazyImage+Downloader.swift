import RxSwift
import SwiftUI
import SDWebImage

extension LazyImage {
  enum Result: Equatable {
    case placeholder
    case success(UIImage)
    case failure(Error)
    
    var image: UIImage? {
      switch self {
      case .success(let image):
        return image
      default:
        return nil
      }
    }
    
    var error: Error? {
      switch self {
      case .failure(let error):
        return error
      default:
        return nil
      }
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.image == rhs.image
    }
  }
  
  class Downloader: ObservableObject {
    @Published var result: Result?
    
    private let downloader: SDWebImageDownloader
    private let disposeBag = DisposeBag()
    
    var headers: [String : String]? {
      didSet {
        headers?.forEach {
          downloader.setValue($0.value, forHTTPHeaderField: $0.key)
        }
      }
    }
    
    init(downloader: SDWebImageDownloader = .shared) {
      self.downloader = downloader
    }
    
    func image(from url: String, startWith _result: Result? = nil) {
      if let _result {
        result = _result
      }
      
      downloader.rx
        .image(from: url)
        .observe(on: MainScheduler.instance)
        .subscribe(onSuccess: { [weak self] in
          self?.result = .success($0)
        }, onFailure: { [weak self] in
          self?.result = .failure($0)
        })
        .disposed(by: disposeBag)
    }
  }
}

// MARK: - Rx

extension Reactive where Base: SDWebImageDownloader {
  fileprivate func image(from url: String) -> Single<UIImage> {
    .create { single in
      self.base.downloadImage(with: .init(string: url)) { image, _, error, _ in
        if let error {
          single(.failure(error))
        }
        else if let image {
          single(.success(image))
        }
        else {
          single(.failure(KTOError.EmptyData))
        }
      }

      return Disposables.create()
    }
  }
}

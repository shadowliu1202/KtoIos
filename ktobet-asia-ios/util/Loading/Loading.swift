import RxSwift
import UIKit

protocol Loading: AnyObject {
  var isLoading: Bool { get }
  var tracker: ActivityIndicator { get }

  func setAppearance(isHidden: Bool)
  func bind(to observable: Observable<Bool>) -> Disposable
}

class LoadingImpl: Loading {
  static let shared: Loading = LoadingImpl()

  private let loadingView = LoadingView()

  private let disposeBag = DisposeBag()

  private(set) var tracker = ActivityIndicator()

  var isLoading: Bool { !loadingView.isHidden }

  private init() {
    bind(to: tracker.asObservable())
      .disposed(by: disposeBag)
  }

  func setAppearance(isHidden: Bool) {
    if loadingView.superview == nil {
      UIWindow.key?.addSubview(loadingView)

      loadingView.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }
    }

    if isHidden {
      loadingView.isHidden = true
    }
    else {
      UIWindow.key?.bringSubviewToFront(loadingView)
      loadingView.isHidden = false
    }
  }

  func bind(to observable: Observable<Bool>) -> Disposable {
    observable
      .subscribe(onNext: { [unowned self] in
        self.setAppearance(isHidden: !$0)
      })
  }
}

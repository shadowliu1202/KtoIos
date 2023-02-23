import RxSwift
import SharedBu
import UIKit

class LaunchViewController: UIViewController {
  var viewModel: NavigationViewModel = Injectable.resolveWrapper(NavigationViewModel.self)

  private var disposeBag = DisposeBag()

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    executeNavigation()
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit.")
    CustomServicePresenter.shared.initService()
  }

  private func showAlert(_ title: String?, _ message: String?) {
    Alert.shared.show(title, message, confirm: { exit(0) }, confirmText: Localize.string("common_confirm"), cancel: nil)
  }

  func executeNavigation() {
    switch viewModel.initLaunchNavigation() {
    case .Landing:
      playVideo(onCompleted: { [weak self] in
        self?.navigateToLandingPage()
      })
    case .Lobby(let productType):
      navigateToProductPage(productType)
    }
  }

  private func playVideo(onCompleted: @escaping (() -> Void)) {
    let videoView = VideoView()
    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: nil,
      queue: nil,
      using: { _ in onCompleted() })
    let videoURL = Bundle.main.url(forResource: "KTO", withExtension: "mp4")!
    self.view.addSubview(videoView, constraints: .fill())
    videoView.play(with: videoURL, fail: onCompleted)
  }

  private func navigateToLandingPage() {
    NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
  }

  private func navigateToProductPage(_ productType: ProductType) {
    if productType == .none {
      NavigationManagement.sharedInstance.goToSetDefaultProduct()
    }
    else {
      NavigationManagement.sharedInstance.goTo(productType: productType)
    }
  }
}

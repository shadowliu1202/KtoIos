import RxSwift
import SharedBu
import UIKit

class LaunchViewController: UIViewController {
  var viewModel: NavigationViewModel = Injectable.resolveWrapper(NavigationViewModel.self)

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    Task { await executeNavigation() }
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit.")
    CustomServicePresenter.shared.initService()
  }

  private func showAlert(_ title: String?, _ message: String?) {
    Alert.shared.show(title, message, confirm: { exit(0) }, confirmText: Localize.string("common_confirm"), cancel: nil)
  }

  func executeNavigation(videoURL: URL? = Bundle.main.url(forResource: "KTO", withExtension: "mp4")) async {
    switch viewModel.initLaunchNavigation() {
    case .Landing:
      await playVideo(videoURL)
      _ = try? await Injection.shared.networkReadyRelay.values.first(where: { $0 })
      navigateToLandingPage()
      
    case .Lobby(let productType):
      _ = try? await Injection.shared.networkReadyRelay.values.first(where: { $0 })
      navigateToProductPage(productType)
    }
  }

  private func playVideo(_ videoURL: URL?) async {
    guard let videoURL else { return }
    
    let videoView = VideoView()
    view.addSubview(videoView, constraints: .fill())
    try? await videoView.play(with: videoURL)
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

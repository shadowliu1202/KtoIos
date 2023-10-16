import RxSwift
import sharedbu
import SwiftUI
import UIKit

class SharedOTPVerificationFailureViewController:
  LobbyViewController &
  SwiftUIConverter
{
  @Injected private var alert: AlertProtocol

  private let message: String?

  init(
    alert: AlertProtocol? = nil,
    message: String? = nil)
  {
    if let alert {
      self._alert.wrappedValue = alert
    }

    self.message = message

    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  override func viewDidLoad() {
    Logger.shared.info("\(type(of: self)) viewDidLoad")

    super.viewDidLoad()
    setupUI()
  }
}

// MARK: - UI

extension SharedOTPVerificationFailureViewController {
  func setupUI() {
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: UIImageView(image: .init(named: "KTO (D)")))

    NavigationManagement.sharedInstance.viewController = self

    addSubView(
      from: {
        SharedOTPVerificationFailureView(
          message: message,
          buttonOnClick: {
            NavigationManagement.sharedInstance.popToRootViewController(nil)
          })
      }, to: view)
  }
}

import SwiftUI
import UIKit

final class LoadingPlaceholderViewController:
  LobbyViewController,
  SwiftUIConverter
{
  private(set) var viewModel: LoadingPlaceholderViewModel

  init(_ type: LoadingPlaceholder.`Type`) {
    self.viewModel = .init(type)
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .overFullScreen
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .clear

    addSubView(
      from: { [unowned self] in
        LoadingPlaceholder(
          viewModel: self.viewModel,
          onViewDisappear: {
            DispatchQueue.main.async {
              self.view.removeFromSuperview()
              self.removeFromParent()
            }
          })
      },
      to: view)
  }

  func setIsLoading(_ isLoading: Bool) {
    viewModel.isLoading = isLoading
  }
}

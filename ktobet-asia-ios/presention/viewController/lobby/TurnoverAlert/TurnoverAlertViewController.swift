import SharedBu
import SwiftUI
import UIKit

class TurnoverAlertViewController:
  UIViewController,
  SwiftUIConverter
{
  @Injected var viewModel: TurnoverAlertViewModel

  let gameName: String
  let turnover: TurnOverDetail

  init(gameName: String, turnover: TurnOverDetail) {
    self.gameName = gameName
    self.turnover = turnover

    super.init(nibName: nil, bundle: nil)

    modalPresentationStyle = .overCurrentContext
    modalTransitionStyle = .crossDissolve
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

// MARK: - UI

extension TurnoverAlertViewController {
  private func setupUI() {
    addSubView(
      from: { [unowned self] in
        TurnoverAlert(
          viewModel: self.viewModel,
          gameName: self.gameName,
          turnover: self.turnover)
      },
      to: view)
  }
}

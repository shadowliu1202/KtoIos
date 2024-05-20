import sharedbu
import SwiftUI
import UIKit

class TurnoverAlertViewController:
    UIViewController,
    SwiftUIConverter
{
    @Injected var viewModel: TurnoverAlertViewModel

    let situation: TurnoverAlertDataModel.Situation
    let turnover: TurnOverDetail

    init(situation: TurnoverAlertDataModel.Situation, turnover: TurnOverDetail) {
        self.situation = situation
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
}

// MARK: - UI

extension TurnoverAlertViewController {
    private func setupUI() {
        addSubView(
            from: { [unowned self] in
                TurnoverAlert(
                    viewModel: self.viewModel,
                    situation: self.situation,
                    turnover: self.turnover)
            },
            to: view)
    }
}

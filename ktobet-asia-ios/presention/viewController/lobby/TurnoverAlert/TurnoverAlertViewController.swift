import UIKit
import SwiftUI
import SharedBu

class TurnoverAlertViewController: UIViewController,
                                   SwiftUIConverter {
    
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

// MARK: - UI

private extension TurnoverAlertViewController {
    
    func setupUI() {
        addSubView(
            from: { [unowned self] in
                TurnoverAlert(
                    viewModel: self.viewModel,
                    gameName: self.gameName,
                    turnover: self.turnover
                )
            },
            to: view
        )
    }
}

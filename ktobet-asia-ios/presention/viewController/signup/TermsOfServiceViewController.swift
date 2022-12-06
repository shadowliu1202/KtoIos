import UIKit
import SharedBu

class TermsOfServiceViewController<Presenter: TermsPresenter>:
    CommonViewController,
    SwiftUIConverter {
    
    let presenter: Presenter
    
    static func instantiate(_ presenter: Presenter) -> TermsOfServiceViewController<Presenter> {
        UIStoryboard(name: "Signup", bundle: nil)
            .instantiateViewController(
                identifier: "TermsOfServiceViewController",
                creator: {
                    TermsOfServiceViewController(coder: $0, presenter: presenter)
                }
            )
    }
    
    init?(coder: NSCoder, presenter: Presenter) {
        self.presenter = presenter
        super.init(coder: coder)
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

private extension TermsOfServiceViewController {
    
    func setupUI() {
        NavigationManagement.sharedInstance.addBarButtonItem(
            vc: self,
            barItemType: presenter.barItemType
        )
        
        addSubView(
            from: { [unowned self] in
                TermsView(presenter: self.presenter)
            },
            to: view
        )
    }
}

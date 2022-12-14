import UIKit
import RxSwift
import RxCocoa
import SharedBu

class TransactionFilterViewController<Presenter>:
    UIViewController,
    SwiftUIConverter
where
    Presenter: Selecting & ObservableObject
{
    let presenter: Presenter

    var onDone: (() -> Void)?
    
    init(presenter: Presenter, onDone: (() -> Void)?) {
        self.presenter = presenter
        self.onDone = onDone
        super.init(nibName: nil, bundle: nil)
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

private extension TransactionFilterViewController {
    
    func setupUI() {
        NavigationManagement.sharedInstance
            .addBarButtonItem(
                vc: self,
                barItemType: .back,
                image: "Close"
            )
        
        addSubView(
            from: { [unowned self] in
                FilterSelector(
                    presenter: self.presenter,
                    accessory: .circle,
                    haveSelectAll: true,
                    selectAtLeastOne: true,
                    allowMultipleSelection: false,
                    onDone: self.onDone
                )
            },
            to: view
        )
    }
}

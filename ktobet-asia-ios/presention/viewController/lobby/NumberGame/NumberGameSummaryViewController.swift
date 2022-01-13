import UIKit
import RxSwift
import RxCocoa

class NumberGameSummaryViewController: APPViewController {
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var segment: UISegmentedControl!
    @IBOutlet weak var containView: UIView!
    
    private var viewModel = DI.resolve(NumberGameRecordViewModel.self)!
    private var disposeBag = DisposeBag()
    
    var presentingVC: UIViewController?
    private lazy var recentVC: RecentViewController = {
        let storyboard = UIStoryboard(name: "NumberGame", bundle: Bundle.main)
        var viewController = storyboard.instantiateViewController(withIdentifier: "RecentViewController") as! RecentViewController
        viewController.viewModel = self.viewModel
        return viewController
    }()
    private lazy var unSettleVC: UnSettleViewController = {
        let storyboard = UIStoryboard(name: "NumberGame", bundle: Bundle.main)
        var viewController = storyboard.instantiateViewController(withIdentifier: "UnSettleViewController") as! UnSettleViewController
        viewController.viewModel = self.viewModel
        return viewController
    }()
    private lazy var settleVC: SettleViewController = {
        let storyboard = UIStoryboard(name: "NumberGame", bundle: Bundle.main)
        var viewController = storyboard.instantiateViewController(withIdentifier: "SettleViewController") as! SettleViewController
        viewController.viewModel = self.viewModel
        return viewController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, title: Localize.string("product_my_bet"))
        initView()
        bindData() 
    }
    
    private func initView() {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = CustomIntensityVisualEffectView(effect: blurEffect, intensity: 0.1)
        blurEffectView.frame = topView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        topView.addSubview(blurEffectView)
        
        segment.setTitle(Localize.string("product_new_bets"), forSegmentAt: 0)
        segment.setTitle(Localize.string("product_unsettled_bets"), forSegmentAt: 1)
        segment.setTitle(Localize.string("product_settled_bets"), forSegmentAt: 2)
        segment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.whiteFull], for: .selected)
        segment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.whiteFull], for: .normal)
    }
    
    private func bindData() {
        self.segment.rx.value.distinctUntilChanged().bind { [weak self] (index) in
            self?.switchContain(index)
        }.disposed(by: disposeBag)
    }
    
    private func switchContain(_ index: Int) {
        if let vc = presentingVC {
            self.removeChildViewController(vc)
        }
        switch index {
        case 0:
            presentingVC = recentVC
        case 1:
            presentingVC = unSettleVC
        case 2:
            presentingVC = settleVC
        default:
            presentingVC = nil
        }
        if let vc = presentingVC {
            self.addChildViewController(vc, inner: containView)
        }
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

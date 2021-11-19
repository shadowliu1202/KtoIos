import UIKit
import RxSwift

class SBKViewController: UIViewController {
    @IBOutlet weak var button: UIButton!

    private let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self)
        button.rx.tap.subscribe(onNext: {[weak self] in
            guard let self = self else { return }
            CustomServicePresenter.shared.startCustomerService(from: self, delegate: nil)
                .subscribe {
                    print("")
                } onError: { error in
                    self.handleErrors(error)
                }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}

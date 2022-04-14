import UIKit
import RxSwift
import RxCocoa
import SharedBu
import Swinject

protocol AuthProfileVerification {
    func navigateToAuthorization()
}
extension AuthProfileVerification where Self: UIViewController {
    func navigateToAuthorization() {
        navigationController?.dismiss(animated: true, completion: nil)
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        let navi = storyboard.instantiateViewController(withIdentifier: "AuthProfileModificationNavigation") as! UINavigationController
        navi.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        let vc = navi.viewControllers.first as? AuthProfileModificationViewController
        if let currentVC = NavigationManagement.sharedInstance.viewController as? UIAdaptivePresentationControllerDelegate {
            vc?.presentationController?.delegate = currentVC
        }
        NavigationManagement.sharedInstance.viewController.present(navi, animated: true, completion: nil)
    }
}

class AuthProfileModificationViewController: APPViewController {
    var barButtonItems: [UIBarButtonItem] = []
    var didAuthenticated: (() -> ())?
    @IBOutlet weak var errorViewHeight: NSLayoutConstraint!
    @IBOutlet weak var passwordTextField: InputPassword!
    @IBOutlet weak var verifyBtn: UIButton!
    
    private var viewModel = DI.resolve(ModifyProfileViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bind(position: .left, barButtonItems: .kto(.close))
        viewModel.profileAuthorization.subscribe(onSuccess: { [weak self] in
            if $0 == .authenticated {
                self?.navigateToProfile()
            }
        }, onError: { [weak self] in
            if !$0.isUnauthorized() {
                self?.handleErrors($0)
            }
        }).disposed(by: disposeBag)
        passwordTextField.setTitle(Localize.string("common_password"))
        (passwordTextField.text <-> viewModel.relayPassword).disposed(by: disposeBag)
        viewModel.relayPassword.map({$0.isNotEmpty}).bind(to: verifyBtn.rx.isValid).disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        passwordTextField.showKeyboard()
    }

    @IBAction func onPressVerify(_ sender: Any) {
        viewModel.authorizeProfileSetting(password: viewModel.relayPassword.value).subscribe { [weak self] in
            self?.navigateToProfile()
        } onError: { [weak self] in
            self?.handleError($0)
        }.disposed(by: disposeBag)
    }
    
    private func handleError(_ error: Error) {
        switch error {
        case is KtoPasswordVerifyFail:
            errorViewHeight.constant = 53
            break
        case is KtoPasswordVerifyFailLimitExceed:
            alertAndLogout()
        default:
            self.handleErrors(error)
        }
    }
    
    private func navigateToProfile() {
        self.didAuthenticated?()
        NavigationManagement.sharedInstance.goTo(storyboard: "Profile", viewControllerId: "ProfileNavigationController")
    }
    
    private func alertAndLogout() {
        Alert.show(Localize.string("common_tip_title_warm"), Localize.string("profile_wrong_password_over_limit"), confirm: {
            CustomServicePresenter.shared.close(completion: {
                let viewModel = DI.resolve(PlayerViewModel.self)!
                viewModel.logout()
                    .subscribeOn(MainScheduler.instance)
                    .subscribe(onCompleted: {
                        NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
                    }).disposed(by: self.disposeBag)
            })
        }, cancel: nil)
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

extension AuthProfileModificationViewController: BarButtonItemable {
    func pressedLeftBarButtonItems(_ sender: UIBarButtonItem) {
        self.navigationController?.dismiss(animated: true, completion: nil)
        self.presentationController?.delegate?.presentationControllerDidDismiss?(self.presentationController!)
    }
}

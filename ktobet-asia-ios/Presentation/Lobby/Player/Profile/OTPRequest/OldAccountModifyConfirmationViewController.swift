import RxSwift
import SharedBu
import UIKit

class OldAccountModifyConfirmationViewController: LobbyViewController {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var contentLabel: UILabel!
  @IBOutlet weak var verifyButton: UIButton!

  var delegate: OldAccountModifyProtocol!

  private var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)

    titleLabel.text = delegate.oldAccountModifyArgs.title
    contentLabel.text = delegate.oldAccountModifyArgs.content

    verifyButton.rx.throttledTap.subscribe(onNext: { [weak self] in
      guard let self else { return }
      self.delegate.verifyOldAccount()
        .do(onSubscribe: { self.verifyButton.isValid = false })
        .do(onError: { _ in self.verifyButton.isValid = true })
        .subscribe(onCompleted: { self.delegate.toNextStepPage() }).disposed(by: self.disposeBag)
    }).disposed(by: disposeBag)

    delegate.handleErrors().subscribe(onNext: { [weak self] error in
      if error.isUnauthorized() {
        NavigationManagement.sharedInstance.navigateToAuthorization()
      }
      else {
        switch error {
        case is PlayerOtpMailInactive,
             is PlayerOtpSmsInactive:
          self?.toErrorPage()
        default:
          self?.handleErrors(error)
        }
      }
    }).disposed(by: disposeBag)
  }

  private func toErrorPage() {
    let commonFailViewController = UIStoryboard(name: "Common", bundle: nil)
      .instantiateViewController(withIdentifier: "CommonFailViewController") as! CommonFailViewController
    commonFailViewController.commonFailedType = delegate.oldAccountModifyArgs.failedType
    NavigationManagement.sharedInstance.pushViewController(vc: commonFailViewController)
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

protocol OldAccountModifyProtocol {
  func verifyOldAccount() -> Completable
  func toNextStepPage()
  func handleErrors() -> Observable<Error>

  var oldAccountModifyArgs: OldAccountModifyArgs { get }
}

struct OldAccountModifyArgs {
  var identity: String
  var title: String
  var content: String
  var failedType: CommonFailedTypeProtocol
}

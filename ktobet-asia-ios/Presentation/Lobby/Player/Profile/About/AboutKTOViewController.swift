import RxSwift
import sharedbu
import UIKit

class AboutKTOViewController: LobbyViewController {
  static let segueIdentifier = "toAboutKTO"

  @IBOutlet weak var imgKto: UIImageView!
  @IBOutlet weak var imgMap: UIImageView!
  @IBOutlet weak var webLink: UITextView!
  @IBOutlet weak var csLink: UITextView!
  @IBOutlet weak var vnPartner: UIView!

  private let httpClient = Injectable.resolve(HttpClient.self)!
  private let playerConfig = Injectable.resolve(PlayerConfiguration.self)!
  private let viewModel = Injectable.resolve(TermsViewModel.self)!
  private var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
    initImage()
    setKtoWebLinkTextView()
    setCsLinkTextView()

    vnPartner.isHidden = playerConfig.supportLocale != .Vietnam()
    view.backgroundColor = .white
  }

  private func initImage() {
    let host = httpClient.host.absoluteString
    imgKto.sd_setImage(url: URL(string: "\(host)/img/app/kto.png"))
    imgMap.sd_setImage(url: URL(string: "\(host)/img/app/map.png"))
  }

  private func setKtoWebLinkTextView() {
    let link = Localize.string("license_ktoglobal_link")
    let attributedText = NSAttributedString(text: link)
      .link(link)
    webLink.attributedText = attributedText
    webLink.setLinkColor(.primaryForLight)
    webLink.textContainerInset = .zero
  }

  private func setCsLinkTextView() {
    csLink.textContainerInset = .zero
    viewModel.getCustomerServiceEmail.subscribe(onSuccess: { [unowned self] in
      let csEmail = Localize.string("common_cs_email", "\($0)")
      let attributedText = NSAttributedString(text: csEmail)
        .color(.primaryForLight)
        .link("\(URL(string: "mailto:\($0)")!)", for: $0)
      csLink.attributedText = attributedText
      csLink.setLinkColor(.primaryForLight)
    }, onFailure: { [weak self] in
      self?.handleErrors($0)
    }).disposed(by: disposeBag)
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

import RxSwift
import UIKit

class AboutKTOViewController: LobbyViewController {
  static let segueIdentifier = "toAboutKTO"

  @IBOutlet weak var imgKto: UIImageView!
  @IBOutlet weak var imgMap: UIImageView!
  @IBOutlet weak var webLink: UITextView!
  @IBOutlet weak var csLink: UITextView!

  private let httpClient = Injectable.resolve(HttpClient.self)!
  private let viewModel = Injectable.resolve(TermsViewModel.self)!
  private var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
    initImage()
    setKtoWebLinkTextView()
    setCsLinkTextView()
  }

  private func initImage() {
    let host = httpClient.host.absoluteString
    imgKto.sd_setImage(url: URL(string: "\(host)/img/app/kto.png"))
    imgMap.sd_setImage(url: URL(string: "\(host)/img/app/map.png"))
  }

  private func setKtoWebLinkTextView() {
    let link = Localize.string("license_ktoglobal_link")
    let txt = AttribTextHolder(text: link)
      .addAttr((text: link, type: .color, UIColor.redD90101))
      .addAttr((text: link, type: .link(true), link))
    txt.setTo(textView: webLink)
    webLink.textContainerInset = .zero
  }

  private func setCsLinkTextView() {
    csLink.textContainerInset = .zero
    viewModel.getCustomerServiceEmail.subscribe(onSuccess: { [unowned self] in
      let csEmail = Localize.string("common_cs_email", "\($0)")
      let txt = AttribTextHolder(text: csEmail)
        .addAttr((text: csEmail, type: .color, UIColor.redD90101))
        .addAttr((text: $0, type: .link(true), URL(string: "mailto:\($0)") as Any))
      txt.setTo(textView: self.csLink)
    }, onError: { [weak self] in
      self?.handleErrors($0)
    }).disposed(by: disposeBag)
  }

  deinit {
    print("\(type(of: self)) deinit")
  }
}

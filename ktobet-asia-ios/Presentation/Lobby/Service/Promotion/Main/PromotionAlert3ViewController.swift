import RxSwift
import sharedbu
import UIKit

class PromotionAlert3ViewController: UIViewController {
  @IBOutlet weak var headerLabel: UILabel!
  @IBOutlet weak var titleLbl: UILabel!
  @IBOutlet weak var remainAmountLabel: UILabel!
  @IBOutlet weak var totalAmountLabel: UILabel!
  @IBOutlet weak var totalRequestAmountLabel: UILabel!
  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!

  var turnOver: TurnOverHint!
  var confirmAction: (() -> Void)?
  var cancelAction: (() -> Void)?
  var titleString: String?
  private var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    headerLabel.text = Localize.string("bonus_turnover_hint_title")
    titleLbl.text = titleString
    remainAmountLabel.text = turnOver.parameters.balance.description()
    totalAmountLabel.text = turnOver.parameters.amount.description()
    totalRequestAmountLabel.text = turnOver.parameters.request.description()

    confirmButton.rx.tap.subscribe(onNext: { [weak self] in
      self?.dismiss(animated: true, completion: { [weak self] in
        self?.confirmAction?()
      })
    }).disposed(by: disposeBag)

    cancelButton.rx.tap.subscribe(onNext: { [weak self] in
      self?.dismiss(animated: true, completion: { [weak self] in
        self?.cancelAction?()
      })
    }).disposed(by: disposeBag)
  }
}

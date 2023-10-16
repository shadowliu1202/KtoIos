import RxSwift
import sharedbu
import UIKit

class PromotionAlert2ViewController: UIViewController {
  @IBOutlet weak var headerLabel: UILabel!
  @IBOutlet weak var titleLbl: UILabel!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var totalAmountLabel: UILabel!
  @IBOutlet weak var remainAmountLabel: UILabel!
  @IBOutlet weak var percentageTitleLabel: UILabel!
  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var progressView: UIView!

  var turnOver: TurnOverDetail!
  var confirmAction: (() -> Void)?
  var cancelAction: (() -> Void)?
  var titleString: String?
  private var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    headerLabel.text = String(format: Localize.string("bonus_isturnoverremind"), turnOver.informPlayerDate.toDateString())
    titleLbl.text = titleString
    nameLabel.text = turnOver.name
    totalAmountLabel.text = turnOver.parameters.turnoverRequest.description()
    remainAmountLabel.text = turnOver.remainAmount.description()

    percentageTitleLabel.text = String(
      format: Localize.string("bonus_current_completion"),
      turnOver.parameters.percentage.description())

    let spb = SegmentedProgressBar(numberOfSegments: 40, percentage: turnOver.parameters.percentage.percent)
    spb.frame = CGRect(x: 0, y: 0, width: progressView.frame.width, height: progressView.frame.height)
    progressView.addSubview(spb)
    spb.startAnimation()

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

import RxSwift
import SharedBu
import UIKit

class PromotionAlert1ViewController: UIViewController {
  @IBOutlet weak var headerLabel: UILabel!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var bonusLabel: UILabel!
  @IBOutlet weak var totalAmountLabel: UILabel!
  @IBOutlet weak var remainAmountLabel: UILabel!
  @IBOutlet weak var percentageTitleLabel: UILabel!
  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var progressView: UIView!

  var turnOver: TurnOverDetail!
  var confirmAction: (() -> Void)?
  private var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    headerLabel.text = String(
      format: Localize.string("bonus_turnover_confirm_title"),
      turnOver.informPlayerDate.toDateString())
    nameLabel.text = turnOver.name
    bonusLabel.text = turnOver.parameters.amount.description()
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
  }
}

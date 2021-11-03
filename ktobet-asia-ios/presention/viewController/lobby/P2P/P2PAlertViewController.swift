import UIKit
import SharedBu
import RxSwift
import RxCocoa


class P2PAlertViewController: UIViewController {
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bonusLabel: UILabel!
    @IBOutlet weak var totalAmountLabel: UILabel!
    @IBOutlet weak var remainAmountLabel: UILabel!
    @IBOutlet weak var percentageTitleLabel: UILabel!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var progressView: UIView!
    
    var p2pTurnOver: P2PTurnOver!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let turnOver = p2pTurnOver as? P2PTurnOver.TurnOverReceipt {
            headerLabel.text = String(format: Localize.string("product_p2p_turnover_description"), turnOver.turnOverDetail.informPlayerDate.toDateTimeString())
            nameLabel.text = turnOver.turnOverDetail.name
            bonusLabel.text = turnOver.turnOverDetail.parameters.amount.description()
            totalAmountLabel.text = turnOver.turnOverDetail.parameters.turnoverRequest.description()
            remainAmountLabel.text = turnOver.turnOverDetail.remainAmount.description()
            percentageTitleLabel.text = String(format: Localize.string("bonus_current_completion"), turnOver.turnOverDetail.parameters.percentage.description())
            
            let spb = SegmentedProgressBar(numberOfSegments: 40, percentage: turnOver.turnOverDetail.parameters.percentage.percent)
            spb.frame = CGRect(x: 0, y: 0, width: progressView.frame.width, height: progressView.frame.height)
            progressView.addSubview(spb)
            spb.startAnimation()
            
            confirmButton.rx.tap.subscribe(onNext: {
                self.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
        }
    }
}



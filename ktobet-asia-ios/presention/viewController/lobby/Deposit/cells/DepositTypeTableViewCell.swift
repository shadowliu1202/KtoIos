import UIKit
import SharedBu

class DepositTypeTableViewCell: UITableViewCell {
    @IBOutlet private weak var iconImg: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var recommendButton: UIButton!
    @IBOutlet private weak var hintLabel: UILabel!
    
    lazy var imgIcon: [String: String] = ["0": Localize.string("Topup ¥(32)"),
                                    "1": "UnionPay(32)",
                                    "2": "WeChatPay(32)",
                                    "3": "AliPay(32)",
                                    "5": "秒存(32)",
                                    "6": "閃充(32)",
                                    "11": "雲閃付(32)",
                                    "14": "iconPayMultiple",
                                    "2001": "Crypto"]
    
    func setUp(depositSelection: DepositSelection) {
        nameLabel.text = depositSelection.name
        iconImg.image = UIImage(named: imgIcon[depositSelection.id] ?? "Default(32)")
        recommendButton.isHidden = !depositSelection.isRecommend
        recommendButton.setTitle(Localize.string("deposit_recommend"), for: .normal)
        hintLabel.text = depositSelection.hint
    }
}

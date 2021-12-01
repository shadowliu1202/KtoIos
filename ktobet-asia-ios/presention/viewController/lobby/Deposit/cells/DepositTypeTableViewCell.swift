import UIKit
import SharedBu

class DepositTypeTableViewCell: UITableViewCell {
    @IBOutlet private weak var iconImg: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var recommendButton: UIButton!
    @IBOutlet private weak var hintLabel: UILabel!
    
    func setUp(name: String, icon: String, isRecommend: Bool, hint: String? = nil) {
        nameLabel.text = name
        iconImg.image = UIImage(named: icon)
        recommendButton.isHidden = !isRecommend
        recommendButton.setTitle(Localize.string("deposit_recommend"), for: .normal)
        hintLabel.text = hint
    }
    
    func setUp(data: DepositType, icon: String) {
        nameLabel.text = data.method.name
        iconImg.image = UIImage(named: icon)
        recommendButton.isHidden = !data.method.isFavorite
        recommendButton.setTitle(Localize.string("deposit_recommend"), for: .normal)
        if data.paymentType is PaymentType.Ethereum {
            hintLabel.text = Localize.string("deposit_cps_hint")
        } else {
            hintLabel.text = data.hint
        }
    }
}

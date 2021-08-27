import UIKit

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
}

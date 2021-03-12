import UIKit

class DepositTypeTableViewCell: UITableViewCell {
    @IBOutlet private weak var iconImg: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var recommendButton: UIButton!
    
    func setUp(name: String, icon: String, isRecommend: Bool) {
        nameLabel.text = name
        iconImg.image = UIImage(named: icon)
        recommendButton.isHidden = !isRecommend
        recommendButton.setTitle(Localize.string("deposit_recommend"), for: .normal)
    }
}

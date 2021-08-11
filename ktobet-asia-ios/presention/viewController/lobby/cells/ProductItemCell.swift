import UIKit
import SharedBu

class ProductItemCell: UICollectionViewCell {
    
    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet private weak var labTitle : UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setup(_ data : ProductItem){
        labTitle.text = data.title
        imgIcon.image = UIImage(named: data.image)
    }
    
    func setSelectedIcon(_ type : ProductType, isSelected: Bool) {
        switch type {
        case .sbk:
            imgIcon.image = isSelected ? UIImage(named: "SBK_Selected") : UIImage(named: "SBK")
        case .casino:
            imgIcon.image = isSelected ? UIImage(named: "Casino_Selected") : UIImage(named: "Casino")
        case .numbergame:
            imgIcon.image = isSelected ? UIImage(named: "Number Game_Selected") : UIImage(named: "Number Game")
        case .slot:
            imgIcon.image = isSelected ? UIImage(named: "Slot_Selected") : UIImage(named: "Slot")
        case .p2p:
            imgIcon.image = isSelected ? UIImage(named: "P2P_Selected") : UIImage(named: "P2P")
        case .arcade:
            imgIcon.image = isSelected ? UIImage(named: "Arcade_Selected") : UIImage(named: "Arcade")
        default:
            break
        }
    }
}

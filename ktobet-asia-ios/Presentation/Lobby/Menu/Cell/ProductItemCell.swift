import sharedbu
import UIKit

class ProductItemCell: UICollectionViewCell {
    @IBOutlet weak var mainatainView: UIView!
    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet weak var labTitle: UILabel!

    private var type: ProductType?
    private var tickCircle: TickCircle?

    var finishCountDown: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setup(_ data: ProductItem) {
        type = data.type
        labTitle.text = data.title
        imgIcon.image = UIImage(named: data.image)

        self.tickCircle?.remove()
        if let time = data.maintainTime {
            self.mainatainView.isHidden = false
            let remainTime = TimeInterval(time.epochSeconds - Int64(Date().timeIntervalSince1970))
            self.tickCircle = TickCircle(view: self.mainatainView)
            self.tickCircle?.drawTickCircle(diameter: 56, countDownSecond: Int(remainTime))
            self.tickCircle?.finishCountDown = self.finishCountDown
            self.isUserInteractionEnabled = false
        }
        else {
            self.isUserInteractionEnabled = true
        }
    }

    func setSelectedIcon(isSelected: Bool) {
        guard let type else { return }
    
        switch type {
        case .sbk:
            imgIcon.image = isSelected ? UIImage(named: "SBK_Selected") : UIImage(named: "SBK")
        case .casino:
            imgIcon.image = isSelected ? UIImage(named: "Casino_Selected") : UIImage(named: "Casino")
        case .numberGame:
            imgIcon.image = isSelected ? UIImage(named: "Number Game_Selected") : UIImage(named: "Number Game")
        case .slot:
            imgIcon.image = isSelected ? UIImage(named: "Slot_Selected") : UIImage(named: "Slot")
        case .p2P:
            imgIcon.image = isSelected ? UIImage(named: "P2P_Selected") : UIImage(named: "P2P")
        case .arcade:
            imgIcon.image = isSelected ? UIImage(named: "Arcade_Selected") : UIImage(named: "Arcade")
        case .none:
            break
        }
    }
}

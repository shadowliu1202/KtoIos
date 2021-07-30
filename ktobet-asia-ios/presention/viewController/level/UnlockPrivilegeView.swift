import UIKit
import SharedBu

class UnlockPrivilegeView: UIView {

    @IBOutlet weak var stamp: UIView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var subTagLabel: UILabel!
    @IBOutlet weak var msgLabel: UILabel!
    @IBOutlet weak var halfCircleStack: UIStackView!
    
    var xibView: UIView!
    var clickHandler: (() -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadXib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadXib()
    }
    
    convenience init(_ args: LevelPrivilege, tapPrivilege: ((LevelPrivilege) -> ())? = nil) {
        self.init(frame: CGRect.zero)
        tagLabel.text = args.title.value as? String
        subTagLabel.text = args.subTitle.value as? String
        msgLabel.text = args.description_.value as? String
        self.clickHandler = {
            tapPrivilege?(args)
        }
        let gesture =  UITapGestureRecognizer(target: self, action: #selector(tapAction))
        switch args {
        case is LevelPrivilege.Rebate:
            self.addGestureRecognizer(gesture)
            icon.image = UIImage(named: "iconLvCashBack48")
            break
        case is LevelPrivilege.ProductSlotRescue:
            self.addGestureRecognizer(gesture)
            icon.image = UIImage(named: "iconLvSlot48")
            break
        case is LevelPrivilege.ProductBetInsurance:
            self.addGestureRecognizer(gesture)
            icon.image = UIImage(named: "iconLvSportsbook48")
            break
        case is LevelPrivilege.Withdrawal:
            icon.image = UIImage(named: "iconLvSpecialWithdrawal48")
            break
        case is LevelPrivilege.Deposit:
            self.addGestureRecognizer(gesture)
            icon.image = UIImage(named: "iconLvDepositBonus48")
            break
        case is LevelPrivilege.Feedback:
            icon.image = UIImage(named: "iconLvSpecial48")
            break
        case is LevelPrivilege.Domain:
            icon.image = UIImage(named: "iconLvSpecial48")
            break
        case is LevelPrivilege.Unknown:
            icon.image = UIImage(named: "")
            break
        default:
            break
        }
    }
    
    @objc func tapAction() {
        self.clickHandler?()
    }
    
    func loadXib() {
        xibView = loadNib()
        stamp.applyGradient(horizontal: [UIColor(rgb: 0xffd500).cgColor, UIColor(rgb: 0xfea144).cgColor])
        addSubview(xibView, constraints: .fill())
        
        addStampBorder()
    }
    
    fileprivate func addStampBorder() {
        stamp.roundCorners(corners: [.topLeft, .bottomLeft], radius: 4)
        let n = (stamp.frame.height + 2) / 10
        for _ in 0..<Int(n) {
            let circleView = UIView()
            circleView.layer.cornerRadius = 4
            circleView.layer.masksToBounds = true
            circleView.backgroundColor = UIColor.black_two
            self.halfCircleStack.addArrangedSubview(circleView)
        }
    }
    
}

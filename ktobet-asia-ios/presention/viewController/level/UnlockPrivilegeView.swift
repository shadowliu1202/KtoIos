import SharedBu
import UIKit

let subTagOneLineHeight: CGFloat = 14
class UnlockPrivilegeView: UIView {
  @IBOutlet weak var stamp: UIView!
  @IBOutlet weak var icon: UIImageView!
  @IBOutlet weak var tagStack: UIStackView!
  @IBOutlet weak var tagLabel: UILabel!
  @IBOutlet weak var subTagLabel: UILabel!
  @IBOutlet weak var msgLabel: UILabel!
  @IBOutlet weak var halfCircleStack: UIStackView!

  var xibView: UIView!
  var clickHandler: (() -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    loadXib()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    loadXib()
  }

  convenience init(_ args: LevelPrivilege, tapPrivilege: ((LevelPrivilege) -> Void)? = nil) {
    self.init(frame: CGRect.zero)
    tagLabel.text = args.title.value as? String
    subTagLabel.text = args.subTitle.value as? String
    adjustSubTagPosition()
    msgLabel.text = args.description_.value as? String
    self.clickHandler = {
      tapPrivilege?(args)
    }
    let gesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
    switch args {
    case is LevelPrivilege.Rebate:
      self.addGestureRecognizer(gesture)
      icon.image = UIImage(named: "iconLvCashBack48")
    case is LevelPrivilege.ProductSlotRescue:
      self.addGestureRecognizer(gesture)
      icon.image = UIImage(named: "iconLvSlot48")
    case is LevelPrivilege.ProductBetInsurance:
      self.addGestureRecognizer(gesture)
      icon.image = UIImage(named: "iconLvSportsbook48")
    case is LevelPrivilege.Withdrawal:
      icon.image = UIImage(named: "iconLvSpecialWithdrawal48")
    case is LevelPrivilege.Deposit:
      self.addGestureRecognizer(gesture)
      icon.image = UIImage(named: "iconLvDepositBonus48")
    case is LevelPrivilege.Feedback:
      icon.image = UIImage(named: "iconLvSpecial48")
    case is LevelPrivilege.Domain:
      icon.image = UIImage(named: "iconLvSpecial48")
    case is LevelPrivilege.Unknown:
      icon.image = UIImage(named: "")
    default:
      break
    }
  }

  @objc
  func tapAction() {
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
      circleView.backgroundColor = UIColor.black131313
      self.halfCircleStack.addArrangedSubview(circleView)
    }
  }

  func adjustSubTagPosition() {
    DispatchQueue.main.async { [weak self] in
      if self?.subTagLabel.frame.height ?? 0 > subTagOneLineHeight {
        self?.tagStack.axis = .vertical
        self?.subTagLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
      }
      else {
        self?.tagStack.axis = .horizontal
      }
    }
  }
}

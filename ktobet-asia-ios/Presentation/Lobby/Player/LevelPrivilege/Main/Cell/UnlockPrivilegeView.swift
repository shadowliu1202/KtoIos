import sharedbu
import UIKit

let subTagOneLineHeight: CGFloat = 17

class UnlockPrivilegeView: UIView {
    @IBOutlet weak var stamp: UIView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var tagStack: UIStackView!
    @IBOutlet weak var tagBackgroundView: UIView!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var subTagLabel: UILabel!
    @IBOutlet weak var msgLabel: UILabel!
    @IBOutlet weak var halfCircleStack: UIStackView!

    private lazy var gradientLayer = gradientLayer(horizontal: [UIColor(rgb: 0xffd500).cgColor, UIColor(rgb: 0xfea144).cgColor])

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
        subTagLabel.isHidden = (args.subTitle.value as? String)?.isEmpty ?? true

        tagBackgroundView.borderWidth = 0.5
        tagBackgroundView.bordersColor = .textSecondary

        msgLabel.text = args.description_.value as? String

        self.clickHandler = {
            tapPrivilege?(args)
        }

        let gesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))

        switch onEnum(of: args) {
        case .deposit:
            self.addGestureRecognizer(gesture)
            icon.image = UIImage(named: "iconLvDepositBonus48")
        case .domain:
            icon.image = UIImage(named: "iconLvSpecial48")
        case .feedback:
            icon.image = UIImage(named: "iconLvSpecial48")
        case .product(let it):
            switch onEnum(of: it) {
            case .betInsurance:
                self.addGestureRecognizer(gesture)
                icon.image = UIImage(named: "iconLvSportsbook48")
            case .slotRescue:
                self.addGestureRecognizer(gesture)
                icon.image = UIImage(named: "iconLvSlot48")
            }
        case .rebate:
            self.addGestureRecognizer(gesture)
            icon.image = UIImage(named: "iconLvCashBack48")
        case .unknown:
            icon.image = UIImage(named: "")
        case .withdrawal:
            icon.image = UIImage(named: "iconLvSpecialWithdrawal48")
        }
    }

    @objc
    func tapAction() {
        self.clickHandler?()
    }

    func loadXib() {
        xibView = loadNib()

        addSubview(xibView, constraints: .fill())
        addStampBorder()

        stamp.layer.insertSublayer(gradientLayer, at: 0)
        gradientLayer.frame = stamp.bounds
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        DispatchQueue.main.async {
            self.gradientLayer.frame = self.stamp.bounds
            self.adjustSubTagPosition()
        }
    }

    fileprivate func addStampBorder() {
        stamp.roundCorners(corners: [.topLeft, .bottomLeft], radius: 4)
        halfCircleStack.spacing = 2
        halfCircleStack.alignment = .center
        halfCircleStack.distribution = .equalSpacing

        DispatchQueue.main.async {
            let numberOfGap = Int((self.stamp.frame.height - 2) / 8)

            for _ in 0..<numberOfGap {
                let circleView = UIView()
                circleView.layer.cornerRadius = 3
                circleView.layer.masksToBounds = true
                circleView.backgroundColor = UIColor.greyScaleDefault
                circleView.snp.makeConstraints { make in
                    make.size.equalTo(6)
                }
                self.halfCircleStack.addArrangedSubview(circleView)
            }
        }
    }

    func adjustSubTagPosition() {
        if subTagLabel.frame.height > subTagOneLineHeight {
            tagStack.axis = .vertical
            tagStack.alignment = .leading
        }
        else {
            tagStack.axis = .horizontal
            tagStack.alignment = .center
        }
    }
}

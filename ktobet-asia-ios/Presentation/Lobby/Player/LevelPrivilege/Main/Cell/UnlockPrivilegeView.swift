import sharedbu
import UIKit

let subTagOneLineHeight: CGFloat = 17

class UnlockPrivilegeView: UIView {
    @IBOutlet var stamp: UIView!
    @IBOutlet var icon: UIImageView!
    @IBOutlet var tagStack: UIStackView!
    @IBOutlet var tagBackgroundView: UIView!
    @IBOutlet var tagLabel: UILabel!
    @IBOutlet var hSubTagLabel: UILabel!
    @IBOutlet var vSubTagLabel: UILabel!
    @IBOutlet var msgLabel: UILabel!
    @IBOutlet var halfCircleStack: UIStackView!

    private lazy var gradientLayer = gradientLayer(horizontal: [
        UIColor.complementaryDefault.cgColor,
        UIColor.complementaryGradient.cgColor,
    ])

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
        hSubTagLabel.text = args.subTitle.value as? String
        vSubTagLabel.text = args.subTitle.value as? String

        tagBackgroundView.borderWidth = 0.5
        tagBackgroundView.bordersColor = .textSecondary

        msgLabel.text = args.description_.value as? String

        adjustSubTagLabels()

        clickHandler = {
            tapPrivilege?(args)
        }

        let gesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))

        switch onEnum(of: args) {
        case .deposit:
            addGestureRecognizer(gesture)
            icon.image = UIImage(named: "iconLvDepositBonus48")
        case .domain:
            icon.image = UIImage(named: "iconLvSpecial48")
        case .feedback:
            icon.image = UIImage(named: "iconLvSpecial48")
        case let .product(it):
            switch onEnum(of: it) {
            case .betInsurance:
                addGestureRecognizer(gesture)
                icon.image = UIImage(named: "iconLvSportsbook48")
            case .slotRescue:
                addGestureRecognizer(gesture)
                icon.image = UIImage(named: "iconLvSlot48")
            }
        case .rebate:
            addGestureRecognizer(gesture)
            icon.image = UIImage(named: "iconLvCashBack48")
        case .unknown:
            icon.image = UIImage(named: "")
        case .withdrawal:
            icon.image = UIImage(named: "iconLvSpecialWithdrawal48")
        }
    }

    @objc
    func tapAction() {
        clickHandler?()
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
        }
    }

    private func adjustSubTagLabels() {
        DispatchQueue.main.async {
            if self.hSubTagLabel.countLines() > 1 {
                self.hSubTagLabel.isHidden = true
                self.vSubTagLabel.isHidden = false
            } else {
                self.hSubTagLabel.isHidden = false
                self.vSubTagLabel.isHidden = true
            }
        }
    }

    fileprivate func addStampBorder() {
        stamp.roundCorners(corners: [.topLeft, .bottomLeft], radius: 4)
        halfCircleStack.spacing = 2
        halfCircleStack.alignment = .center
        halfCircleStack.distribution = .equalSpacing

        DispatchQueue.main.async {
            let numberOfGap = Int((self.stamp.frame.height - 2) / 8)

            for _ in 0 ..< numberOfGap {
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
}

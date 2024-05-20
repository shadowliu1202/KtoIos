import sharedbu
import UIKit

class LockPrivilegeView: UIView {
    @IBOutlet weak var stamp: UIView!
    @IBOutlet weak var tagStack: UIStackView!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var subTagLabel: UILabel!
    @IBOutlet weak var msgLabel: UILabel!
    @IBOutlet weak var halfCircleStack: UIStackView!

    var xibView: UIView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadXib()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadXib()
    }

    convenience init(_ args: LevelPrivilege) {
        self.init(frame: CGRect.zero)
        tagLabel.text = args.title.value as? String
        subTagLabel.text = args.subTitle.value as? String
        adjustSubTagPosition()
        msgLabel.text = args.description_.value as? String
    }

    func loadXib() {
        xibView = loadNib()
        addSubview(xibView, constraints: .fill())

        addStampBorder()
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

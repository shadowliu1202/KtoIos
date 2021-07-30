import UIKit
import SharedBu

class LockPrivilegeView: UIView {

    @IBOutlet weak var stamp: UIView!
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
        msgLabel.text = args.description_.value as? String
    }
    
    func loadXib() {
        xibView = loadNib()
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

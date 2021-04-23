import UIKit

class ToastPopUp: UIView {
    
    private lazy var imageView: UIImageView = { UIImageView(frame: .zero) }()
    private lazy var msgLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.init(name: "PingFangSC-Semibold", size: 16)
        label.textColor = UIColor.whiteFull
        return label
    }()
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 146, height: 146)
    }
    
    init(icon: UIImage, text: String) {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.black80
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 8
        msgLabel.text = text
        imageView.image = icon
        self.addSubview(self.imageView, constraints: .center)
        self.imageView.constrain([
            .equal(\.heightAnchor, length: 50),
            .equal(\.widthAnchor, length: 50)
        ])
        self.addSubview(self.msgLabel, constraints: [
            .equal(\.trailingAnchor, offset: 0),
            .equal(\.leadingAnchor, offset: 0)
        ])
        self.msgLabel.constrain([.equal(\.heightAnchor, length: 24)])
        self.msgLabel.constrain(to: self.imageView, constraints: [.equal(\.topAnchor, \.bottomAnchor, offset: 9)])
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
    }
}

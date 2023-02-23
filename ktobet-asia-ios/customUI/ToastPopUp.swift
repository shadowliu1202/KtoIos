import UIKit

class ToastPopUp: UIView {
  private lazy var imageView = UIImageView(frame: .zero)
  private lazy var msgLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    label.font = UIFont(name: "PingFangSC-Semibold", size: 16)
    label.textColor = UIColor.whitePure
    return label
  }()

  override var intrinsicContentSize: CGSize {
    CGSize(width: 146, height: 146)
  }

  init(icon: UIImage, text: String) {
    super.init(frame: .zero)
    self.backgroundColor = UIColor.black131313.withAlphaComponent(0.8)
    self.layer.masksToBounds = true
    self.layer.cornerRadius = 8
    msgLabel.text = text
    imageView.image = icon
    self.addSubview(self.imageView)
    self.imageView.constrain(to: self, constraints: [.equal(\.centerXAnchor), .equal(\.topAnchor, offset: 25)])
    self.imageView.constrain([
      .equal(\.heightAnchor, length: 64),
      .equal(\.widthAnchor, length: 64),
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

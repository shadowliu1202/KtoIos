import UIKit

class LockInputText: InputText {
  lazy var imageView: UIImageView = {
    let imageView = UIImageView(frame: .zero)
    imageView.image = UIImage(named: "Lock")
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    return imageView
  }()

  private var once = true

  override func layoutSubviews() {
    super.layoutSubviews()
    setupUI()
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    self.setCorner(topCorner: true, bottomCorner: true)
    self.textContent.isUserInteractionEnabled = false
  }

  private func setupUI() {
    guard once else { return }
    self.addSubview(imageView)
    let verticalConstraint = imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
    let widthConstraint = imageView.widthAnchor.constraint(equalToConstant: 24)
    let heightConstraint = imageView.heightAnchor.constraint(equalToConstant: 24)
    let trailing = imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15)
    self.addConstraints([verticalConstraint, widthConstraint, heightConstraint, trailing])

    once = false
  }
}

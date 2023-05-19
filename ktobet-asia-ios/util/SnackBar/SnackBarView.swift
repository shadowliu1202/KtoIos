import UIKit

class SnackBarView: UIView {
  @Injected var repo: LocalStorageRepository

  private let label: UILabel = .init(frame: .zero)
  private let imageView: UIImageView = .init(frame: .zero)

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
    setupConstraints()
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    backgroundColor = .greyScaleToast
    layer.cornerRadius = 8
    clipsToBounds = true
    layer.masksToBounds = false
    layer.shadowRadius = 4
    layer.shadowOpacity = 1
    layer.shadowOffset = CGSize(width: 0, height: 0)
    layer.shadowColor = UIColor.greyScaleWhite.withAlphaComponent(0.3).cgColor
  }

  private func setupConstraints() {
    let stack: UIStackView = .init(
      arrangedSubviews: [imageView, label],
      spacing: 8,
      axis: .horizontal,
      distribution: .fill,
      alignment: .center)
    addSubview(stack)
    stack.snp.makeConstraints { make in
      make.edges.equalToSuperview()
        .inset(UIEdgeInsets(top: 12, left: 15, bottom: 12, right: 15))
    }

    imageView.snp.makeConstraints { make in
      make.size.equalTo(CGSize(width: 24, height: 24))
    }
    imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
    imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    label.localizedFont(by: repo.getSupportLocale(), weight: .regular, size: 14)
    label.textColor = .greyScaleWhite
    label.numberOfLines = 0
  }

  func setText(_ str: String?) {
    label.text = str
  }

  func getText() -> String? {
    label.text
  }

  func setImage(_ img: UIImage?) {
    imageView.isHidden = img == nil ? true : false
    imageView.image = img
    layoutIfNeeded()
  }
}

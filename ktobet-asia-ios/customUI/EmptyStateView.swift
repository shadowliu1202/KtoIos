import SnapKit
import SwiftUI
import UIKit

extension EmptyStateView {
  enum KeyboardAppearance {
    case possible
    case impossible
  }
}

class EmptyStateView: UIView {
  private var iconImageView: UIImageView!
  private var descriptionLabel: UILabel!
  private var stackView: UIStackView!
  private var contentView: UIView!
  private var scrollView: UIScrollView!

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  init(icon: UIImage?, description: String, keyboardAppearance: KeyboardAppearance) {
    super.init(frame: .zero)

    setupUI(
      icon,
      description,
      keyboardAppearance)
  }

  private func setupUI(
    _ icon: UIImage?,
    _ description: String,
    _ keyboardAppearance: KeyboardAppearance)
  {
    iconImageView = UIImageView(image: icon)
    iconImageView.contentMode = .scaleAspectFit
    iconImageView.snp.makeConstraints { make in
      make.width.height.equalTo(128)
    }

    descriptionLabel = UILabel()
    descriptionLabel.text = description
    descriptionLabel.textAlignment = .center
    descriptionLabel.textColor = .textPrimary
    descriptionLabel.font = UIFont(name: "PingFangSC-Regular", size: 14)!

    stackView = UIStackView(arrangedSubviews: [iconImageView, descriptionLabel])
    stackView.axis = .vertical
    stackView.distribution = .fill
    stackView.spacing = 0

    contentView = UIView()
    contentView.addSubview(stackView)
    
    scrollView = UIScrollView()
    scrollView.bounces = true
    scrollView.alwaysBounceVertical = true
    scrollView.addSubview(contentView)
    addSubview(scrollView)

    scrollView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    contentView.snp.makeConstraints { make in
      make.width.equalTo(self)
      make.height.equalTo(self.safeAreaLayoutGuide)
      make.edges.equalToSuperview()
    }

    stackView.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.width.equalToSuperview()

      switch keyboardAppearance {
      case .possible:
        make.top.equalToSuperview().offset(80)
      case .impossible:
        make.centerY.equalToSuperview().offset(-74)
      }
    }
  }
}

struct EmptyStateView_Previews: PreviewProvider {
  static var previews: some View {
    ZStack {
      Color.black

      VStack(spacing: 0) {
        LimitSpacer(30)

        Rectangle()
          .frame(height: 100)
          .padding(.horizontal, 20)
          .foregroundColor(.gray)

        UIViewPreviewHelper(
          EmptyStateView(
            icon: UIImage(named: "No Records"),
            description: "没有投注历史",
            keyboardAppearance: .possible))
      }
    }
    .previewDisplayName("Has Keyboard")

    ZStack {
      Color.black

      UIViewPreviewHelper(
        EmptyStateView(
          icon: UIImage(named: "No Records"),
          description: "没有投注历史",
          keyboardAppearance: .impossible))
    }
    .previewDisplayName("No Keyboard")
  }
}

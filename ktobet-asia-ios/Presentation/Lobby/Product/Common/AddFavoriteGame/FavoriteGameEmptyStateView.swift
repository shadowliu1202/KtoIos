import SnapKit
import SwiftUI
import UIKit

class FavoriteGameEmptyStateView: UIView {
    private var iconImageView: UIImageView!
    private var descriptionLabel: UILabel!
    private var stackView: UIStackView!
    private var contentView: UIView!
    private var scrollView: UIScrollView!

    var addFavoriteButton: UIButton!

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)

        setupUI()
    }

    private func setupUI() {
        iconImageView = UIImageView(image: UIImage(named: "No Favorite"))
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(128)
        }

        descriptionLabel = UILabel()
        descriptionLabel.text = Localize.string("product_none_favorite")
        descriptionLabel.textAlignment = .center
        descriptionLabel.textColor = .textPrimary
        descriptionLabel.font = UIFont(name: "PingFangSC-Regular", size: 14)!

        stackView = UIStackView(arrangedSubviews: [iconImageView, descriptionLabel])
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 0

        addFavoriteButton = UIButton(type: .system)
        addFavoriteButton.setTitle(Localize.string("product_add_now"), for: .normal)
        addFavoriteButton.setTitleColor(UIColor.primaryDefault, for: .normal)
        addFavoriteButton.titleLabel?.font = UIFont(name: "PingFangSC-Regular", size: 16)!
        addFavoriteButton.backgroundColor = UIColor.clear
        addFavoriteButton.layer.borderWidth = 1
        addFavoriteButton.layer.borderColor = UIColor.textSecondary.cgColor
        addFavoriteButton.layer.cornerRadius = 8
        addFavoriteButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    
        contentView = UIView()
        contentView.addSubview(stackView)
        contentView.addSubview(addFavoriteButton)

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
            make.centerY.equalToSuperview().offset(-74)
        }

        addFavoriteButton.snp.makeConstraints { make in
            make.height.equalTo(addFavoriteButton.intrinsicContentSize.height)
            make.width.greaterThanOrEqualTo(addFavoriteButton.intrinsicContentSize.width)
      
            make.centerX.equalToSuperview()
            make.top.equalTo(stackView.snp.bottom).offset(48)
            make.leading.equalToSuperview().offset(30)
            make.trailing.equalToSuperview().offset(-30)
        }
    }
}

struct FavoriteGameEmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black

            VStack(spacing: 0) {
                LimitSpacer(30)

                UIViewPreviewHelper(
                    FavoriteGameEmptyStateView())
            }
        }
    }
}

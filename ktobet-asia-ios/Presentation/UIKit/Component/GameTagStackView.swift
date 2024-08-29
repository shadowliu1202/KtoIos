import sharedbu
import UIKit

class GameTagStackView: UIStackView {
    private let rowHeight: CGFloat = 40
    private let rowSpacing: CGFloat = 8

    required init(coder: NSCoder) {
        super.init(coder: coder)
        addArrangedSubview(createOneChildView(self))
        let allBtn = createOneButton(
            title: Localize.string("common_all"),
            isSelected: true,
            callback: UIAction { _ in }
        )
        arrangedSubviews.last?.addSubview(allBtn)
    }

    func initialize(
        recommend: (ProductDTO.RecommendTag?, Bool) = (nil, false),
        new: (ProductDTO.NewTag?, Bool) = (nil, false),
        data: [(ProductDTO.GameTag, Bool)] = [],
        allTagClick: @escaping () -> Void,
        recommendClick: @escaping (() -> Void) = {},
        newClick: @escaping (() -> Void) = {},
        customClick: @escaping ((ProductDTO.GameTag) -> Void) = { _ in }
    ) {
        removeAllArrangedSubviews()
        translatesAutoresizingMaskIntoConstraints = false
        spacing = rowSpacing
        axis = .vertical
        distribution = .equalSpacing
        addArrangedSubview(createOneChildView(self))

        let allBtn = createOneButton(
            title: Localize.string("common_all"),
            isSelected: data.allSatisfy { $0.1 == false } && recommend.1 == false && new.1 == false,
            callback: UIAction { _ in
                allTagClick()
            }
        )
        arrangedSubviews.last?.addSubview(allBtn)

        if let recommendTag = recommend.0 {
            let recommendBtn = createOneButton(
                title: recommendTag.name,
                isSelected: recommend.1,
                callback: UIAction { _ in
                    recommendClick()
                }
            )
            arrangedSubviews.last?.addSubview(recommendBtn)
        }
        if let newTag = new.0 {
            let newBtn = createOneButton(title: newTag.name, isSelected: new.1, callback: UIAction { _ in
                newClick()
            })
            arrangedSubviews.last?.addSubview(newBtn)
        }

        for (key, isSelected) in data {
            let button = createOneButton(title: key.name, isSelected: isSelected, callback: UIAction { _ in
                customClick(key)
            })

            arrangedSubviews.last?.addSubview(button)
        }

        setNeedsLayout()
        layoutIfNeeded()
    }

    func calculateHeight() -> CGFloat {
        let numberOfItems = arrangedSubviews.count
        return CGFloat(numberOfItems) * rowHeight + CGFloat(max(0, numberOfItems - 1)) * rowSpacing
    }

    private func createOneButton(title: String, isSelected: Bool, callback: UIAction) -> UIButton {
        let button = UIButton(primaryAction: callback)
        configureButton(button, title: title, isSelected: isSelected)

        if let lastSubview = arrangedSubviews.last {
            lastSubview.addSubview(button)
            layoutButton(button, in: lastSubview)

            lastSubview.layoutIfNeeded()

            if shouldWrapToNextLine(button, in: lastSubview) {
                moveToNewRow(button)
            }
        }

        return button
    }

    private func configureButton(_ button: UIButton, title: String, isSelected: Bool) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont(name: "PingFangSC-Medium", size: 12)
        button.titleLabel?.numberOfLines = 0
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 18, bottom: 8, right: 18)
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true

        if isSelected {
            button.applyGradient(vertical: [UIColor(rgb: 0xF74D25).cgColor, UIColor(rgb: 0xF20000).cgColor])
            button.setTitleColor(UIColor.greyScaleWhite, for: .normal)
        } else {
            button.applyGradient(vertical: [UIColor(rgb: 0x32383E).cgColor, UIColor(rgb: 0x17191C).cgColor])
            button.setTitleColor(UIColor.textPrimary, for: .normal)
        }
    }

    private func layoutButton(_ button: UIButton, in parentView: UIView) {
        button.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.bottom.equalToSuperview().inset(4)
            if parentView.subviews.count == 1 {
                make.leading.equalToSuperview()
            } else {
                if let previousButton = parentView.subviews[parentView.subviews.count - 2] as? UIButton {
                    make.leading.equalTo(previousButton.snp.trailing).offset(8)
                }
            }
        }
    }

    private func shouldWrapToNextLine(_ button: UIButton, in parentView: UIView) -> Bool {
        return button.frame.maxX > parentView.frame.width
    }

    private func moveToNewRow(_ button: UIButton) {
        button.removeFromSuperview()

        let newChildRow = createOneChildView(self)
        addArrangedSubview(newChildRow)

        newChildRow.addSubview(button)
        layoutButton(button, in: newChildRow)

        newChildRow.snp.makeConstraints { make in
            make.width.equalTo(self.frame.size.width)
        }

        if let lastSubview = arrangedSubviews.last {
            newChildRow.snp.makeConstraints { make in
                make.top.equalTo(lastSubview.snp.bottom).offset(8)
            }
        }
    }

    private func createOneChildView(_ parentView: UIStackView) -> UIView {
        let childRow = UIView(frame: .zero)

        childRow.snp.makeConstraints { make in
            make.height.equalTo(rowHeight)
            make.width.equalTo(parentView.frame.size.width)
        }

        return childRow
    }
}

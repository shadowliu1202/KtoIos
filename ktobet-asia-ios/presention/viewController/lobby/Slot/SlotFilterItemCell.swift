import UIKit

class SlotFilterItemCell: UICollectionViewCell {
  @IBOutlet weak var titleLabel: UILabel!

  func setup(title: String, isSelected: Bool) -> Self {
    titleLabel.text = title
    isSelected ? setSelectTheme() : setUnSelectTheme()
    return self
  }

  func onClick(_ isSelected: Bool) {
    isSelected ? setSelectTheme() : setUnSelectTheme()
  }

  private func setUnSelectTheme() {
    contentView.backgroundColor = .greyScaleDefault
    titleLabel.textColor = .complementaryDefault
  }

  private func setSelectTheme() {
    contentView.backgroundColor = .complementaryDefault
    titleLabel.textColor = .greyScaleDefault
  }
}

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
    contentView.backgroundColor = .black131313
    titleLabel.textColor = .yellowFFD500
  }
  
  private func setSelectTheme() {
    contentView.backgroundColor = .yellowFFD500
    titleLabel.textColor = .black131313
  }
}

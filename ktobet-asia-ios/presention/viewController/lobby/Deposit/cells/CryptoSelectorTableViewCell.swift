import RxSwift
import UIKit

class CryptoSelectorTableViewCell: UITableViewCell {
  @IBOutlet weak var img: UIImageView!
  @IBOutlet weak var name: UILabel!
  @IBOutlet weak var hint: UILabel!
  @IBOutlet weak var selectRadioButton: RadioButton!

  func selectRow() {
    selectRadioButton.isSelected = true
  }

  func unSelectRow() {
    selectRadioButton.isSelected = false
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    selectRadioButton.isSelected = false
  }
}

import SharedBu
import UIKit

class DepositMethodTableViewCell: UITableViewCell {
  @IBOutlet private weak var iconImage: UIImageView!
  @IBOutlet private weak var nameLabel: UILabel!
  @IBOutlet private weak var hintLabel: UILabel!
  @IBOutlet private weak var selectRadioButton: RadioButton!

  func setUp(offlinePaymentGatewayItemViewModel: OfflinePaymentGatewayItemViewModel) {
    nameLabel.text = offlinePaymentGatewayItemViewModel.name
    hintLabel.text = ""
    iconImage.image = UIImage(named: offlinePaymentGatewayItemViewModel.icon)
    selectRadioButton.isSelected = offlinePaymentGatewayItemViewModel.isSelected
  }

  func setUp(onlinePaymentGatewayItemViewModel: OnlinePaymentGatewayItemViewModel) {
    nameLabel.text = onlinePaymentGatewayItemViewModel.name
    hintLabel.text = onlinePaymentGatewayItemViewModel.hint
    iconImage.image = UIImage(named: onlinePaymentGatewayItemViewModel.icon)
    selectRadioButton.isSelected = onlinePaymentGatewayItemViewModel.isSelected

    hintLabel.isHidden = onlinePaymentGatewayItemViewModel.hint.isEmpty
    hintLabel.numberOfLines = 0
  }

  func selectRow() {
    selectRadioButton.isSelected = true
    selectRadioButton.isClicked()
  }

  func unSelectRow() {
    selectRadioButton.isSelected = false
    selectRadioButton.isClicked()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    selectRadioButton.isSelected = false
  }
}

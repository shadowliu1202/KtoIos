import UIKit

class DepositMethodTableViewCell: UITableViewCell {
    @IBOutlet private weak var iconImage: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var selectRadioButton: RadioButton!
    
    func setUp(icon: String, name: String, index: Int, selectedIndex: Int) {
        nameLabel.text = name
        iconImage.image = UIImage(named: icon)
        selectRadioButton.tag = index
        selectRadioButton.isSelected = index == selectedIndex
    }
    
    func selectRow(){
        selectRadioButton.isSelected = true
        selectRadioButton.isClicked()
    }
    
    func unSelectRow(){
        selectRadioButton.isSelected = false
        selectRadioButton.isClicked()
    }
}

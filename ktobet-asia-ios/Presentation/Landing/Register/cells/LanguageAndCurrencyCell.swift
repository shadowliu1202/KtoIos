import UIKit

class LanguageAndCurrencyCell: UITableViewCell {
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var labTitle: UILabel!
    @IBOutlet weak var btnSelected: UIButton!
    var didSelectOn: ((UIButton) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        background.layer.masksToBounds = true
        background.layer.cornerRadius = 8
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func setup(_ data: SignupLanguageViewController.LanguageListData) {
        let tundoraGray = UIColor.inputFocus
        let shaftGray = UIColor.inputDefault
        labTitle.text = data.title
        labTitle.textColor = data.selected ? UIColor.greyScaleWhite : UIColor.textPrimary
        btnSelected.isSelected = data.selected
        background.backgroundColor = data.selected ? tundoraGray : shaftGray
    }

    @IBAction
    func radioBtnPressed(_ sender: UIButton) {
        self.didSelectOn?(sender)
    }
}

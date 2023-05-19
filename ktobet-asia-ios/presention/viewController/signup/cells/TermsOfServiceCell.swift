import UIKit

class TermsOfServiceCell: UITableViewCell {
  @IBOutlet weak var labTitle: UILabel!
  @IBOutlet weak var labTitleContent: UILabel!
  @IBOutlet weak var labContent: UILabel!
  @IBOutlet weak var iconArrowImage: UIImageView!
  @IBOutlet weak var constraintTitleContentTop: NSLayoutConstraint!
  @IBOutlet weak var constraintContentTop: NSLayoutConstraint!
  @IBOutlet weak var constraintContentBottom: NSLayoutConstraint!
  @IBOutlet weak var constraintUnderLineHeight: NSLayoutConstraint!
  @IBOutlet weak var bottomLineView: UIView!

  override func awakeFromNib() {
    super.awakeFromNib()
    labTitle.textColor = UIColor.greyScaleDefault
    labContent.textColor = UIColor.greyScaleDefault
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  func setup(_ data: TermsOfService, isLatestRow: Bool) {
    labTitle.text = data.title
    labTitleContent.text = data.selected ? data.title : ""
    labContent.text = data.selected ? data.content : ""
    iconArrowImage.image = data.selected ? UIImage(named: "termsArrowUp") : UIImage(named: "termsArrowDown")
    constraintTitleContentTop.constant = data.selected ? 8 : 0
    constraintContentTop.constant = data.selected ? 16 : 0
    constraintContentBottom.constant = data.selected ? 32 : 0
    constraintUnderLineHeight.constant = data.selected ? 1 : 0
    bottomLineView.isHidden = data.selected && isLatestRow
  }
}

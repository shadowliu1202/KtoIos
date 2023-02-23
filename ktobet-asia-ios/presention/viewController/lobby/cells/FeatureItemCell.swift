import UIKit

class FeatureItemCell: UITableViewCell {
  @IBOutlet private weak var imgIcon: UIImageView!
  @IBOutlet private weak var labTitle: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }

  func setup(_ title: String, image: UIImage?) {
    labTitle.text = title
    imgIcon.image = image
  }
}

import UIKit

class P2PTableViewCell: UITableViewCell {
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var label: UILabel!

  override func prepareForReuse() {
    super.prepareForReuse()
    iconImageView.sd_cancelCurrentImageLoad()
    iconImageView.image = nil
  }
}

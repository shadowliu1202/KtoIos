import sharedbu
import UIKit

class CasinoLobbyItemCell: UICollectionViewCell {
  @IBOutlet weak var mainView: UIView!
  @IBOutlet weak var imgIcon: UIImageView!
  @IBOutlet weak var maintainIcon: UIImageView!
  @IBOutlet private weak var labTitle: UILabel!
  @IBOutlet private weak var blurView: UIView!
  @IBOutlet weak var imgWidth: NSLayoutConstraint!

  override func awakeFromNib() {
    super.awakeFromNib()
    mainView.translatesAutoresizingMaskIntoConstraints = false
    let width = floor((UIScreen.main.bounds.size.width - 24 * 2 - 14 * 2) / 3)
    self.mainView.constrain([.equal(\.widthAnchor, length: width)])
    imgWidth.constant = width - 4 * 2
  }

  @discardableResult
  func configure(_ data: CasinoLobby) -> Self {
    labTitle.text = data.name
    imgIcon.image = data.lobby.img
    maintainIcon.image = UIImage(named: "game-maintainance")
    blurView.isHidden = !data.isMaintenance
    self.isUserInteractionEnabled = !data.isMaintenance
    blurView.layer.cornerRadius = self.bounds.width / 2
    blurView.layer.masksToBounds = true
    return self
  }
}

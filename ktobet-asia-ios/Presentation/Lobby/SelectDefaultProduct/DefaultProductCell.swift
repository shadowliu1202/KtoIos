import sharedbu
import UIKit

class DefaultProductCell: UITableViewCell {
  @IBOutlet private weak var labTitle: UILabel!
  @IBOutlet private weak var labDesc: UILabel!
  @IBOutlet private weak var viewBg: UIView!
  @IBOutlet private weak var imgBackground: UIImageView!
  @IBOutlet private weak var viewShadow: UIView!
  @IBOutlet private weak var imgMask: UIView!
  @IBOutlet weak var titleLeading: NSLayoutConstraint!
  @IBOutlet weak var titleTrailing: NSLayoutConstraint!

  override func awakeFromNib() {
    super.awakeFromNib()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    imgBackground.sd_cancelCurrentImageLoad()
    imgBackground.image = nil
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    self.viewBg.layer.masksToBounds = true
    self.viewBg.layer.cornerRadius = 8
    self.imgBackground?.layer.masksToBounds = true
    self.viewShadow.layer.masksToBounds = false
    self.viewShadow.layer.cornerRadius = 8
    self.viewShadow.layer.shadowColor = UIColor.white.cgColor
    self.viewShadow.layer.shadowPath = UIBezierPath(
      roundedRect: self.viewBg.bounds,
      cornerRadius: self.viewBg.layer.cornerRadius).cgPath
    self.viewShadow.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
    self.viewShadow.layer.shadowOpacity = 0.7
    self.viewShadow.layer.shadowRadius = 5
  }

  func setup(_ gameType: DefaultProductType, _ local: SupportLocale, _ selectedGameType: DefaultProductType?, _ host: String) {
    let isSelected = gameType == selectedGameType ? true : false
    self.imgBackground.sd_setImage(url: try! getSelectImgUrl(host, gameType))
    self.imgMask.isHidden = isSelected
    self.labTitle.text = gameType.localizeString
    self.labDesc.text = try! getDesc(gameType)
    self.viewBg.layer.borderWidth = isSelected ? 1 : 0
    self.viewBg.layer
      .borderColor = (
        isSelected ? UIColor.greyScaleWhite.withAlphaComponent(0.5) : UIColor.greyScaleWhite
          .withAlphaComponent(0.3))
      .cgColor
    self.viewShadow.isHidden = !isSelected
    titleLeading.constant = Theme.shared.getDefaultProductTextPadding(by: local)
    titleTrailing.constant = Theme.shared.getDefaultProductTextPadding(by: local)
  }

  private func getDesc(_ productType: DefaultProductType) -> String {
    switch productType {
    case .sbk:
      return Localize.string("profile_defaultproduct_sportsbook_description")
    case .casino:
      return Localize.string("profile_defaultproduct_casino_description")
    case .slot:
      return Localize.string("profile_defaultproduct_slot_description")
    case .numberGame:
      return Localize.string("profile_defaultproduct_keno_description")
    }
  }

  private func getSelectImgUrl(_ host: String, _ productType: DefaultProductType) -> URL? {
    switch productType {
    case .sbk:
      return URL(string: "\(host)/img/app/sbk.png")
    case .casino:
      return URL(string: "\(host)/img/app/casino.png")
    case .slot:
      return URL(string: "\(host)/img/app/slot.png")
    case .numberGame:
      return URL(string: "\(host)/img/app/number_game.png")
    }
  }
}

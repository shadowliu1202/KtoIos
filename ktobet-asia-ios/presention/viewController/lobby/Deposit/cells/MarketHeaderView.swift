import UIKit

class MarketHeaderView: UITableViewHeaderFooterView {
  @IBOutlet weak var bottomLine: UIView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var icon: UIImageView!
  var callback: ((MarketHeaderView) -> Void)?

  func configure(
    _ item: Market,
    isLastSection: Bool,
    callback: ((MarketHeaderView) -> Void)? = nil)
    -> Self
  {
    titleLabel.text = item.name
    icon.image = item.expanded
    ? UIImage(named: "arrow-drop-up")
    : UIImage(named: "arrow-drop-down")
    
    bottomLine.backgroundColor = isLastSection
    ? .gray3C3E40
    : .clear
    
    self.callback = callback
    return self
  }

  @IBAction
  func pressBtn() {
    self.callback?(self)
  }
}

import UIKit

class KTOBarButtonItem: UIBarButtonItem {
  override var action: Selector? {
    didSet {
      guard let target = self.target, let action = self.action else { return }
      self.button.addTarget(target, action: action, for: .touchUpInside)
    }
  }

  lazy var button: UIButton = {
    let button = UIButton(type: .custom)
    button.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
    return button
  }()

  override init() {
    super.init()
    self.setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    self.setupUI()
  }

  func setupUI() {
    self.customView = self.button
  }
}

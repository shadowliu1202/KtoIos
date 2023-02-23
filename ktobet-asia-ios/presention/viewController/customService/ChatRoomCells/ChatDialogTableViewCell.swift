import UIKit

class ChatDialogTableViewCell: UITableViewCell {
  static let playerDialogIdentifier = "PlayerDialogTableViewCell"
  static let handlerDialogIdentifier = "HandlerDialogTableViewCell"

  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var messageLabel: UILabel!
}

class UILabelPadding: UILabel {
  private var padding = UIEdgeInsets.zero

  @IBInspectable var paddingLeft: CGFloat {
    get { padding.left }
    set { padding.left = newValue }
  }

  @IBInspectable var paddingRight: CGFloat {
    get { padding.right }
    set { padding.right = newValue }
  }

  @IBInspectable var paddingTop: CGFloat {
    get { padding.top }
    set { padding.top = newValue }
  }

  @IBInspectable var paddingBottom: CGFloat {
    get { padding.bottom }
    set { padding.bottom = newValue }
  }

  override func drawText(in rect: CGRect) {
    super.drawText(in: rect.inset(by: padding))
  }

  override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
    let insets = self.padding
    var rect = super.textRect(forBounds: bounds.inset(by: insets), limitedToNumberOfLines: numberOfLines)
    rect.origin.x -= insets.left
    rect.origin.y -= insets.top
    rect.size.width += (insets.left + insets.right)
    rect.size.height += (insets.top + insets.bottom)
    return rect
  }
}

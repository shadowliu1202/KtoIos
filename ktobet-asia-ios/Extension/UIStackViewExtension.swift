import UIKit

extension UIStackView {
  @discardableResult
  func removeAllArrangedSubviews() -> [UIView] {
    arrangedSubviews.reduce([UIView]()) { $0 + [removeArrangedSubViewProperly($1)] }
  }

  func removeArrangedSubViewProperly(_ view: UIView) -> UIView {
    removeArrangedSubview(view)
    NSLayoutConstraint.deactivate(view.constraints)
    view.removeFromSuperview()
    return view
  }

  convenience init(
    arrangedSubviews: [UIView] = [],
    spacing: CGFloat,
    axis: NSLayoutConstraint.Axis = .vertical,
    distribution: Distribution,
    alignment: Alignment,
    padding: UIEdgeInsets? = nil)
  {
    self.init(arrangedSubviews: arrangedSubviews)
    self.axis = axis
    self.spacing = spacing
    self.distribution = distribution
    self.alignment = alignment

    if let newPadding = padding {
      self.isLayoutMarginsRelativeArrangement = true
      self.layoutMargins = newPadding
    }
  }
}

import Foundation
import SnapKit
import UIKit

class PlainHorizontalProgressBar: UIView {
  private let backgroundMask = CAShapeLayer()

  private var width: SnapKit.Constraint?

  var progress: CGFloat = 0 {
    didSet { setNeedsLayout() }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  private func setup() {
    let top = UIView()
    top.backgroundColor = .green6AB336
    let bottom = UIView()
    bottom.backgroundColor = .green5D9B31

    let stack = UIStackView(
      arrangedSubviews: [top, bottom],
      spacing: 0, axis: .vertical,
      distribution: .fillEqually,
      alignment: .fill)

    stack.cornerRadius = 8

    addSubview(stack)
    stack.snp.makeConstraints { make in
      make.top.bottom.left.equalToSuperview()
      width = make.width.equalTo(0).constraint
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    let size = self.frame.size
    backgroundMask.path = UIBezierPath(
      roundedRect: .init(origin: .zero, size: size),
      cornerRadius: size.height * 0.25)
      .cgPath

    layer.mask = backgroundMask

    UIView.animate(withDuration: 0.3, animations: { [weak self] in
      guard let self else { return }
      self.width?.update(offset: size.width * self.progress)
      self.layoutIfNeeded()
    })
  }
}

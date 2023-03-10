import UIKit

protocol ExpandableHeaderViewDelegate: AnyObject {
  func toggleSection(header: ExpandableHeaderView, section: Int, expanded: Bool)
}

class ExpandableHeaderView: UITableViewHeaderFooterView {
  private let section: Int
  private var expanded: Bool
  private weak var delegate: ExpandableHeaderViewDelegate?

  private var imageView = UIImageView(frame: .zero)
  private var titleLabel = UILabel(frame: .zero)
  private var dateTimeLabel = UILabel(frame: .zero)
  private var bottomLine = UIView(frame: .zero)

  init(
    title: String,
    section: Int,
    total: Int,
    expanded: Bool,
    delegate: ExpandableHeaderViewDelegate,
    date: String? = nil)
  {
    self.section = section
    self.expanded = expanded

    super.init(reuseIdentifier: nil)

    addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clickSectionHeader)))
    contentView.backgroundColor = UIColor.black131313

    setupUI(title: title, date: date, section: section, total: total)

    self.delegate = delegate
  }

  private func setupUI(title: String, date: String?, section: Int, total _: Int) {
    let mainStack = UIStackView(frame: .zero)
    mainStack.axis = .horizontal
    mainStack.alignment = .center
    mainStack.distribution = .equalSpacing
    mainStack.spacing = 12

    addSubview(mainStack)
    mainStack.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 24, bottom: 16, right: 24))
    }

    let hStack = UIStackView(frame: .zero)
    hStack.axis = .horizontal
    hStack.alignment = .leading
    hStack.distribution = .equalSpacing
    hStack.spacing = 12

    mainStack.addArrangedSubview(hStack)
    mainStack.addArrangedSubview(imageView)

    imageView.image = arrowImage(expanded: expanded)

    hStack.addArrangedSubview(titleLabel)
    titleLabel.text = title
    titleLabel.textColor = UIColor.whitePure
    titleLabel.font = UIFont(name: "PingFangSC-Semibold", size: 14)
    titleLabel.setContentHuggingPriority(.required, for: .horizontal)

    hStack.addArrangedSubview(dateTimeLabel)
    dateTimeLabel.text = date
    dateTimeLabel.textColor = UIColor.gray595959
    dateTimeLabel.font = UIFont(name: "PingFangSC-Regular", size: 14)

    if section != 0 {
      addBorder(.top)
    }

    addSubview(bottomLine)
    bottomLine.backgroundColor = .gray3C3E40
    bottomLine.snp.makeConstraints { make in
      make.left.equalToSuperview()
      make.right.equalToSuperview()
      make.height.equalTo(1)
      make.bottom.equalToSuperview()
    }
    bottomLine.alpha = 0
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc
  func clickSectionHeader(gesture: UITapGestureRecognizer) {
    let cell = gesture.view as! ExpandableHeaderView
    expanded.toggle()
    delegate?.toggleSection(header: self, section: cell.section, expanded: expanded)

    imageView.image = arrowImage(expanded: expanded)

    if expanded {
      bottomLine.alpha = 1
    }
    else {
      let animator = UIViewPropertyAnimator(duration: 0.5, curve: .easeInOut) {
        self.bottomLine.alpha = 0
      }
      animator.startAnimation()
    }
  }

  private func arrowImage(expanded: Bool) -> UIImage? {
    expanded ? UIImage(named: "arrow-drop-up") : UIImage(named: "arrow-drop-down")
  }
}

import RxCocoa
import RxSwift
import SharedBu
import UIKit

class NextLevelTableViewCell: UITableViewCell {
  @IBOutlet weak var levelLabel: UILabel!
  @IBOutlet weak var collapseLabel: UILabel!
  @IBOutlet weak var collapseIcon: UIImageView!
  @IBOutlet weak var collapseBtn: UIButton!
  @IBOutlet weak var stackView: UIStackView!
  private lazy var disposeBag = DisposeBag()

  override func prepareForReuse() {
    super.prepareForReuse()
    disposeBag = DisposeBag()
    stackView.removeAllArrangedSubviews()
  }

  func configure(_ item: Item, callback: (Observable<Void>, DisposeBag) -> Void) -> Self {
    self.selectionStyle = .none
    levelLabel.text = Localize.string("common_level_2", "\(item.level)")
    switch item.collapse {
    case .unFold:
      collapseLabel.text = Localize.string("common_fold") // 收起
      collapseIcon.image = UIImage(named: "iconFold") // 朝上
      stackView.isHidden = false
      loadPrivilegeView(item.privileges)
    case .fold:
      collapseLabel.text = Localize.string("common_open") // 展开
      collapseIcon.image = UIImage(named: "iconUnfold") // 朝下
      stackView.isHidden = true
    }
    collapseBtn.rx.touchUpInside.bind { _ in
      print(">>> collapseBtn click Lv \(item.level)")
    }.disposed(by: disposeBag)
    callback(self.collapseBtn.rx.touchUpInside.asObservable(), disposeBag)
    return self
  }

  func loadPrivilegeView(_ privileges: [LevelPrivilege]) {
    privileges.forEach({
      stackView.addArrangedSubview(LockPrivilegeView($0))
    })
  }
}

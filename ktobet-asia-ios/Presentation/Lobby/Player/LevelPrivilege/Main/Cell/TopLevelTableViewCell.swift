import RxCocoa
import RxSwift
import sharedbu
import UIKit

class TopLevelTableViewCell: UITableViewCell {
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var msgLabel: UILabel!
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

    func configure(
        _ item: LevelPrivilegeViewModel.Item,
        callback: (Observable<Void>, DisposeBag) -> Void,
        tapPrivilegeHandler: @escaping (LevelPrivilege) -> Void)
        -> Self
    {
        self.selectionStyle = .none
        levelLabel.text = Localize.string("common_level_2", "\(item.level)")
        timeLabel.text = item.time
        msgLabel.text = Localize.string("level_desc_levelup", "\(item.level)")
        switch item.collapse {
        case .unFold:
            collapseLabel.text = Localize.string("common_fold")
            collapseIcon.image = UIImage(named: "iconFold")
            stackView.isHidden = false
            loadPrivilegeView(item.privileges, tapPrivilegeHandler)
        case .fold:
            collapseLabel.text = Localize.string("common_open")
            collapseIcon.image = UIImage(named: "iconUnfold")
            stackView.isHidden = true
        }
        collapseBtn.rx.touchUpInside.bind { _ in
            Logger.shared.info("collapseBtn click Lv \(item.level)")
        }.disposed(by: disposeBag)
        callback(self.collapseBtn.rx.touchUpInside.asObservable(), disposeBag)
        return self
    }

    func loadPrivilegeView(_ privileges: [LevelPrivilege], _ tapPrivilegeHandler: @escaping (LevelPrivilege) -> Void) {
        for privilege in privileges {
            stackView.addArrangedSubview(UnlockPrivilegeView(privilege, tapPrivilege: tapPrivilegeHandler))
        }
    }
}

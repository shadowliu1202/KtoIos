import RxCocoa
import RxSwift
import sharedbu
import UIKit

class LevelTableViewCell: UITableViewCell {
    @IBOutlet var levelLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var msgLabel: UILabel!
    @IBOutlet var collapseLabel: UILabel!
    @IBOutlet var collapseIcon: UIImageView!
    @IBOutlet var collapseBtn: UIButton!
    @IBOutlet var stackView: UIStackView!
    private lazy var disposeBag = DisposeBag()

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        stackView.removeAllArrangedSubviews()
    }

    func configure(
        _ item: LevelPrivilegeViewModel.Item,
        callback: (Observable<Void>, DisposeBag) -> Void,
        tapPrivilegeHandler: @escaping (LevelPrivilege) -> Void
    )
        -> Self
    {
        selectionStyle = .none
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
        callback(collapseBtn.rx.touchUpInside.asObservable(), disposeBag)
        return self
    }

    func loadPrivilegeView(_ privileges: [LevelPrivilege], _ tapPrivilegeHandler: @escaping (LevelPrivilege) -> Void) {
        for privilege in privileges {
            stackView.addArrangedSubview(UnlockPrivilegeView(privilege, tapPrivilege: tapPrivilegeHandler))
        }
    }
}

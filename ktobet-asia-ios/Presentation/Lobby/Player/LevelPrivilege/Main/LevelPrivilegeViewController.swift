import RxCocoa
import RxDataSources
import RxSwift
import sharedbu
import SwiftUI
import UIKit

class LevelPrivilegeViewController: LobbyViewController {
    @Injected private var viewModel: LevelPrivilegeViewModel

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var levelBackgroundView: UIView!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var accountLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var expButton: UIButton!
    @IBOutlet weak var expLabel: UILabel!
    @IBOutlet weak var progress: PlainHorizontalProgressBar!

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        binding()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchData()
    }

    @IBAction
    func showExpInfo(_: UIButton) {
        Alert.shared.show(
            Localize.string("level_experience_title"),
            Localize.string("level_experience_desc"),
            confirm: { },
            cancel: nil)
    }
}

// MARK: - UI

extension LevelPrivilegeViewController {
    private func setupUI() {
        NavigationManagement.sharedInstance
            .addMenuToBarButtonItem(vc: self, title: Localize.string("level_levelprivilege"))

        headerView
            .applyGradient(horizontal: [
                UIColor.yellowFFD500.cgColor,
                UIColor.yellowFEA144.cgColor
            ])

        progress.borderWidth = 1
        progress.bordersColor = .greyScaleWhite.withAlphaComponent(0.6)
        progress.backgroundColor = .greyScaleWhite.withAlphaComponent(0.2)

        levelBackgroundView.roundCorners(
            corners: [.topLeft, .bottomLeft],
            radius: 16)

        expButton.imageView?.contentMode = .scaleAspectFill
    }

    private func binding() {
        viewModel.playerRelay
            .subscribe(onNext: { [weak self] player in
                self?.accountLabel.text = "\(AccountMask.maskAccount(account: player.playerInfo.displayId))"
                self?.idLabel.text = player.playerInfo.gameId
                self?.progress.progress = CGFloat(player.playerInfo.exp.percent / 100)
                self?.expLabel.text = player.playerInfo.exp.description() + "%"
                self?.levelLabel.text = Localize.string("common_level_2", [String(player.playerInfo.level)])
            })
            .disposed(by: disposeBag)

        viewModel.itemsRelay
            .bind(to: tableView.rx.items) { [weak self] tableView, row, item in
                guard let self else { return .init() }

                let collapseHandler: (Observable<Void>, DisposeBag) -> Void = { [weak self] collapse, disposeBag in
                    self?.updateCollapse(
                        tableView: tableView,
                        item: item,
                        collapse: collapse,
                        disposeBag: disposeBag)
                }

                let tapPrivilegeHandler: (LevelPrivilege) -> Void = { [weak self] privilege in
                    self?.goToDetail(level: item.level, privilege)
                }

                if self.viewModel.isPreviewLevel(row) {
                    return tableView.dequeueReusableCell(
                        withIdentifier: "NextLevelTableViewCell",
                        cellType: NextLevelTableViewCell.self)
                        .configure(item, callback: collapseHandler)
                }
                else if self.viewModel.isTopLevel(row) {
                    return tableView.dequeueReusableCell(
                        withIdentifier: "TopLevelTableViewCell",
                        cellType: TopLevelTableViewCell.self)
                        .configure(item, callback: collapseHandler, tapPrivilegeHandler: tapPrivilegeHandler)
                }
                else if self.viewModel.isZeroLevel(row) {
                    return tableView.dequeueReusableCell(
                        withIdentifier: "ZeroLevelTableViewCell",
                        cellType: ZeroLevelTableViewCell.self)
                        .configure(item)
                }
                else {
                    return tableView.dequeueReusableCell(
                        withIdentifier: "LevelTableViewCell",
                        cellType: LevelTableViewCell.self)
                        .configure(item, callback: collapseHandler, tapPrivilegeHandler: tapPrivilegeHandler)
                }
            }
            .disposed(by: disposeBag)
    }

    private func updateCollapse(
        tableView _: UITableView,
        item: LevelPrivilegeViewModel.Item,
        collapse: Observable<Void>,
        disposeBag: DisposeBag)
    {
        collapse
            .bind(onNext: { [weak self] in
                guard
                    let self,
                    let index = self.viewModel.itemsRelay.value
                        .firstIndex(where: { $0.level == item.level })
                else { return }

                item.isFold.toggle()

                var updated = self.viewModel.itemsRelay.value
                updated[index] = item
                self.viewModel.itemsRelay.accept(updated)
            })
            .disposed(by: disposeBag)
    }

    private func goToDetail(level: Int32, _ privilege: LevelPrivilege) {
        navigationController?.pushViewController(
            LevelPrivilegeDetailViewController.instantiate(
                levelPrivilege: privilege,
                level: level),
            animated: true)
    }
}

extension UIColor {
    fileprivate static let yellowFFD500: UIColor = #colorLiteral(red: 1, green: 0.8352941176, blue: 0, alpha: 1)
    fileprivate static let yellowFEA144: UIColor = #colorLiteral(red: 0.9960784314, green: 0.631372549, blue: 0.2666666667, alpha: 1)
}

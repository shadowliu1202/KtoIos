import UIKit
import RxSwift
import RxCocoa
import SharedBu
import AlignedCollectionViewFlowLayout

class P2PViewController: AppVersionCheckViewController {
    
    @IBOutlet private weak var tableView: UITableView!
        
    var barButtonItems: [UIBarButtonItem] = []
    private var viewModel = DI.resolve(P2PViewModel.self)!
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self)
        self.bind(position: .right, barButtonItems: .kto(.record))
        
        let dataSource = self.rx.viewWillAppear.flatMap({ [unowned self](_) in
            return self.viewModel.getAllGames().asObservable()
        }).share(replay: 1)
        dataSource.catchError({ [weak self] (error) -> Observable<[P2PGame]> in
            self?.handleUnknownError(error)
            return Observable.just([])
        }).bind(to: tableView.rx.items) {tableView, row, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "p2pTableVIewCell", cellType: P2PTableViewCell.self)
            if let url = URL(string: item.thumbnail.url()) {
                cell.iconImageView.sd_setImage(with: url, completed: nil)
                cell.iconImageView.borderWidth = 1
                cell.iconImageView.bordersColor = UIColor(red: 200.0/255.0, green: 212.0/255.0, blue: 222.0/255.0, alpha: 1)
            }
            
            cell.label.text = item.gameName
            return cell
        }.disposed(by: disposeBag)
        
        tableView.rx.modelSelected(P2PGame.self).bind{ [unowned self] (data) in
            self.checkTurnOver(p2pGame: data)
        }.disposed(by: disposeBag)
        
        tableView.estimatedRowHeight = 208.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 96, right: 0)
    }
    
    private func checkTurnOver(p2pGame: P2PGame) {
        viewModel.getTurnOverStatus().subscribe { (turnOver) in
            switch turnOver {
            case is P2PTurnOver.Calculating:
                print("Calculating")
                Alert.show(Localize.string("common_tip_title_warm"), Localize.string("product_p2p_bonus_calculating"), confirm: {}, cancel: nil)
            case is P2PTurnOver.None:
                let storyboard = UIStoryboard(name: "Product", bundle: nil)
                let navi = storyboard.instantiateViewController(withIdentifier: "GameNavigationViewController") as! UINavigationController
                if let gameVc = navi.viewControllers.first as? GameWebViewViewController {
                    gameVc.gameId = p2pGame.gameId
                    gameVc.gameName = p2pGame.gameName
                    gameVc.viewModel = self.viewModel
                    gameVc.delegate = self
                    navi.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
                    self.present(navi, animated: true, completion: nil)
                }
            case is P2PTurnOver.TurnOverReceipt:
                guard let p2pAlertView = UIStoryboard(name: "P2P", bundle: nil).instantiateViewController(withIdentifier: "P2PAlertViewController") as? P2PAlertViewController else { return }
                p2pAlertView.p2pTurnOver = turnOver
                p2pAlertView.view.backgroundColor = UIColor(red: 19/255, green: 19/255, blue: 19/255, alpha: 0.8)
                p2pAlertView.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                p2pAlertView.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
                self.present(p2pAlertView, animated: true, completion: nil)
            default:
                break
            }
        } onError: {[weak self] (error) in
            self?.handleUnknownError(error)
        }.disposed(by: disposeBag)
    }
}

extension P2PViewController: BarButtonItemable {
    
    func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
        switch sender {
        case is RecordBarButtonItem:
            guard let betSummaryViewController = self.storyboard?.instantiateViewController(withIdentifier: "P2PSummaryViewController") as? P2PSummaryViewController else { return }
            self.navigationController?.pushViewController(betSummaryViewController, animated: true)
            break
        default: break
        }
    }
    
}

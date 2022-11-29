import UIKit
import RxSwift
import RxCocoa
import SharedBu

class TransactionFilterViewController: FilterConditionViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnSubmit: UIButton!
    lazy var totalSource = BehaviorRelay<[FilterItem]>(value: [])
    var _presenter: FilterPresentProtocol!
    override var presenter: FilterPresentProtocol! {
        get {
            return _presenter
        }
        set {
            _presenter = newValue
        }
    }
    
    let disposeBag = DisposeBag()
    var _conditionCallbck: (([FilterItem]) -> ())?
    override var conditionCallbck: (([FilterItem]) -> ())? {
        get {
            return _conditionCallbck
        }
        set {
            _conditionCallbck = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        dataBinding()
    }
  
    func initUI() {
        titleLabel.text = presenter.getTitle()
        tableView.separatorColor = UIColor.clear
        displayLastRowSperator()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, image: "Close")
    }
    
    func dataBinding() {
        totalSource.accept(presenter.getDatasource())
        btnSubmit.rx.touchUpInside.subscribe(onNext: { [weak self] in
            self?.conditionCallbck?(self?.getConditions() ?? [])
            NavigationManagement.sharedInstance.popViewController()
        }).disposed(by: disposeBag)
        
        totalSource.asObservable().bind(to: tableView.rx.items) { [weak self] tableView, row, item in
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "StaticCell", cellType: StaticCell.self)
                    let _ = cell.configure(item, impl: self?.presenter) {(pressedEvent, disposeBag) in
                    pressedEvent.subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        if item.isSelected! {
                            cell.selectAllButton.setTitle(Localize.string("common_unselect_all"), for: .normal)
                        } else {
                            cell.selectAllButton.setTitle(Localize.string("common_select_all"), for: .normal)
                        }
                        
                        self.toggle(row)
                    }).disposed(by: disposeBag)
                }
                
                if item.isSelected! {
                    cell.selectAllButton.setTitle(Localize.string("common_select_all"), for: .normal)
                }
                
                return cell
            } else {
                return tableView.dequeueReusableCell(withIdentifier: "InteractiveCell", cellType: InteractiveCell.self).configure(item, impl: self?.presenter) { (pressedEvent, disposeBag) in
                    pressedEvent.subscribe(onNext: { [weak self] _ in
                        guard let `self` = self else { return }
                        self.toggle(row)
                    }).disposed(by: disposeBag)
                }
            }
        }.disposed(by: disposeBag)
    }
    
    private func getConditions() -> [FilterItem] {
        return totalSource.value
    }
    
    private func toggle(_ row: Int) {
        self.presenter.toggleItem(row)
        let newValue = self.presenter.getDatasource()
        totalSource.accept(newValue)
    }
    
    private func lastRowSeparator() -> CALayer {
        let sepFrame = CGRect(x: 0, y: -1, width: self.tableView.bounds.width, height: 1)
        let sep = CALayer()
        sep.frame = sepFrame
        sep.backgroundColor = UIColor.gray3C3E40.cgColor
        return sep
    }
    
    private func displayLastRowSperator() {
        let seprator = UIView(frame: .zero)
        seprator.layer.addSublayer(lastRowSeparator())
        self.tableView.tableFooterView = seprator
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

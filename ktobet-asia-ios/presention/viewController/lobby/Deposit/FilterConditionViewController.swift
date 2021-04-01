import UIKit
import RxSwift
import RxCocoa
import share_bu

class FilterConditionViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnSubmit: UIButton!
    lazy var totalSource = BehaviorRelay<[FilterItem]>(value: [])
    var presenter: FilterPresentProtocol!
    let disposeBag = DisposeBag()
    var conditionCallbck: (([FilterItem]) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        dataBinding()
    }
  
    func initUI() {
        titleLabel.text = presenter.getTitle()
        tableView.separatorColor = UIColor.clear
        displayLastRowSperator()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, icon: .close, action: .back)
    }
    
    func dataBinding() {
        totalSource.accept(presenter.getDatasource())
        btnSubmit.rx.touchUpInside.subscribe(onNext: { [weak self] in
            self?.conditionCallbck?(self?.getConditions() ?? [])
            NavigationManagement.sharedInstance.popViewController()
        }).disposed(by: disposeBag)
        
        totalSource.asObservable().bind(to: tableView.rx.items) { [weak self] tableView, row, item in
            if row == 0 {
                return tableView.dequeueReusableCell(withIdentifier: "StaticCell", cellType: StaticCell.self).configure(item, impl: self?.presenter)
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
        sep.backgroundColor = UIColor.dividerCapeCodGray2.cgColor
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

class StaticCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    
    func configure(_ item: FilterItem, impl: FilterPresentProtocol?) -> Self {
        self.selectionStyle = .none
        self.titleLabel.text = impl?.itemText(item)
        return self
    }
}

class InteractiveCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var selectBtn: UIButton!
    private lazy var disposeBag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    func configure(_ item: FilterItem, impl: FilterPresentProtocol?, callback: (Observable<Void>, DisposeBag) -> Void) -> Self {
        self.selectionStyle = .none
        self.titleLabel.text = impl?.itemText(item)
        if let img = impl?.itemAccenery(item) as? UIImage {
            self.selectBtn.setImage(img, for: .normal)
        }
        callback(self.selectBtn.rx.touchUpInside.asObservable(), disposeBag)
        return self
    }
}

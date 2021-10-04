import UIKit
import RxSwift
import RxCocoa


class PromotionFilterViewController: FilterConditionViewController, UITableViewDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnSubmit: UIButton!
    
    private var sortingStackView: UIStackView!
    private lazy var totalSource = BehaviorRelay<[FilterItem]>(value: [])
    private let disposeBag = DisposeBag()

    private var _presenter: FilterPresentProtocol!
    override internal var presenter: FilterPresentProtocol! {
        get {
            return _presenter
        }
        set {
            _presenter = newValue
        }
    }
    private var _conditionCallbck: (([FilterItem]) -> ())?
    override internal var conditionCallbck: (([FilterItem]) -> ())? {
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
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
    }
  
    private func initUI() {
        titleLabel.text = presenter.getTitle()
        displayLastRowSperator()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, image: "Close")
    }
        
    private func dataBinding() {
        totalSource.accept(presenter.getDatasource())
        btnSubmit.rx.touchUpInside.subscribe(onNext: { [weak self] in
            self?.conditionCallbck?(self?.getConditions() ?? [])
            NavigationManagement.sharedInstance.popViewController()
        }).disposed(by: disposeBag)
        
        totalSource.asObservable().bind(to: tableView.rx.items) { [weak self] tableView, row, item in
            guard let self = self else { return UITableViewCell() }
            if item.type == .static {
                return tableView.dequeueReusableCell(withIdentifier: "StaticCell", cellType: StaticCell.self).configure(item, impl: self.presenter)
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "InteractiveCell", cellType: InteractiveCell.self).configure(item, impl: self.presenter) { (pressedEvent, disposeBag) in
                    pressedEvent.subscribe(onNext: { [weak self] _ in
                        guard let `self` = self else { return }
                        self.toggle(row)
                    }).disposed(by: disposeBag)
                }
                
                if PromotionPresenter.productRows.contains(row) {
                    cell.separatorInset = UIEdgeInsets(top: 0, left: 52, bottom: 0, right: 0)
                    cell.titleLeadingConstraint.constant = 47
                } else {
                    cell.separatorInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 0)
                    cell.titleLeadingConstraint.constant = 24
                }
                
                return cell
            }
        }.disposed(by: disposeBag)
    }
    
    @objc private func sortingDescTapped(_ sender: UITapGestureRecognizer) {
        sortringTapped(Localize.string("bonus_orderby_desc"))
    }
    
    @objc private func sortingAscTapped(_ sender: UITapGestureRecognizer) {
        sortringTapped(Localize.string("bonus_orderby_asc"))
    }
    
    private func sortringTapped(_ currenttitle: String) {
        self.sortingStackView.removeFromSuperview()
        let sortingCondition = self.presenter.getDatasource()[PromotionPresenter.sortingRow]
        if sortingCondition.title != currenttitle {
            self.presenter.toggleItem(PromotionPresenter.sortingRow)
        }
        
        let newValue = self.presenter.getDatasource()
        totalSource.accept(newValue)
    }
    
    private func getConditions() -> [FilterItem] {
        return totalSource.value
    }
    
    private func toggle(_ row: Int) {
        if row == PromotionPresenter.sortingRow {
            showSortingView()
        } else {
            self.presenter.toggleItem(row)
            let newValue = self.presenter.getDatasource()
            totalSource.accept(newValue)
        }
    }
    
    private func showSortingView() {
        let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as! InteractiveCell
        let descLabel = UILabel()
        descLabel.textColor = .whiteFull
        descLabel.text = Localize.string("bonus_orderby_desc")
        descLabel.font = UIFont(name: "PingFangSC-Medium", size: 14)
        let descTap = UITapGestureRecognizer(target: self, action: #selector(self.sortingDescTapped(_:)))
        descLabel.isUserInteractionEnabled = true
        descLabel.addGestureRecognizer(descTap)
        
        let ascLabel = UILabel()
        ascLabel.textColor = .whiteFull
        ascLabel.text = Localize.string("bonus_orderby_asc")
        ascLabel.font = UIFont(name: "PingFangSC-Medium", size: 14)
        let ascTap = UITapGestureRecognizer(target: self, action: #selector(self.sortingAscTapped(_:)))
        ascLabel.isUserInteractionEnabled = true
        ascLabel.addGestureRecognizer(ascTap)
        
        self.sortingStackView = UIStackView(frame: CGRect(x: cell.titleLbl.frame.origin.x - 8, y: cell.frame.origin.y, width: cell.frame.width * 0.87, height: cell.frame.height * 2))
        self.sortingStackView.distribution = .fillEqually
        self.sortingStackView.alignment = .fill
        self.sortingStackView.axis = .vertical
        self.sortingStackView.insertArrangedSubview(descLabel, at: 0)
        self.sortingStackView.insertArrangedSubview(ascLabel, at: 1)
        self.sortingStackView.backgroundColor = UIColor.black_two
        self.sortingStackView.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        self.sortingStackView.isLayoutMarginsRelativeArrangement = true
        tableView.addSubview(self.sortingStackView ?? UIView())
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 2 {
            return 69
        } else {
            return 48
        }
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

class FilterConditionViewController: UIViewController {
    var presenter: FilterPresentProtocol!
    var conditionCallbck: (([FilterItem]) -> ())?
}


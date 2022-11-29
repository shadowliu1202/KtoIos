import UIKit
import RxSwift
import RxCocoa


class PromotionFilterViewController: FilterConditionViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnSubmit: UIButton!
    
    private let disposeBag = DisposeBag()
    
    private lazy var totalSource = BehaviorRelay<[FilterItem]>(value: [])
    private var sortingStackView: UIStackView!

    private var _presenter: FilterPresentProtocol!
    
    private var _conditionCallbck: (([FilterItem]) -> ())?
    
    override var presenter: FilterPresentProtocol! {
        get {
            return _presenter
        }
        set {
            _presenter = newValue
        }
    }
    
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
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

// MARK: - UI

private extension PromotionFilterViewController {
    
    func initUI() {
        titleLabel.text = presenter.getTitle()
        
        tableView.separatorColor = .clear
        
        displayLastRowSperator()
        
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, image: "Close")
    }
        
    func dataBinding() {
        totalSource.accept(presenter.getDatasource())
        
        btnSubmit.rx.touchUpInside
            .subscribe(onNext: { [weak self] in
                self?.conditionCallbck?(self?.getConditions() ?? [])
                NavigationManagement.sharedInstance.popViewController()
            })
            .disposed(by: disposeBag)
        
        totalSource.asObservable()
            .bind(to: tableView.rx.items) { [weak self] tableView, row, item in
                guard let self = self else { return UITableViewCell() }
                
                if item.type == .static {
                    return tableView
                        .dequeueReusableCell(
                            withIdentifier: "StaticCell",
                            cellType: StaticCell.self
                        )
                        .configure(item, impl: self.presenter)
                }
                else {
                    let cell = tableView
                        .dequeueReusableCell(
                            withIdentifier: "InteractiveCell",
                            cellType: InteractiveCell.self
                        )
                        .configure(item, impl: self.presenter) { (pressedEvent, disposeBag) in
                            pressedEvent
                                .subscribe(onNext: { [weak self] _ in
                                    guard let `self` = self else { return }
                                    self.toggle(row)
                                })
                                .disposed(by: disposeBag)
                        }
                    
                    cell.removeBorder()
                    
                    if PromotionPresenter.productRows.contains(row) {
                        cell.addBorder(leftConstant: 52)
                        cell.titleLeadingConstraint.constant = 47
                    }
                    else if row == 1 {
                        cell.addBorder()
                        cell.addBorder(.bottom)
                        cell.titleLeadingConstraint.constant = 24
                    }
                    else if row == 3 {
                        cell.addBorder()
                        cell.titleLeadingConstraint.constant = 24
                    }
                    else {
                        cell.addBorder(leftConstant: 24)
                        cell.titleLeadingConstraint.constant = 24
                    }
                    
                    return cell
                }
            }
            .disposed(by: disposeBag)
    }
    
    @objc func sortingDescTapped(_ sender: UITapGestureRecognizer) {
        sortringTapped(Localize.string("bonus_orderby_desc"))
    }
    
    @objc func sortingAscTapped(_ sender: UITapGestureRecognizer) {
        sortringTapped(Localize.string("bonus_orderby_asc"))
    }
    
    func sortringTapped(_ currenttitle: String) {
        sortingStackView.removeFromSuperview()
        
        let sortingCondition = presenter.getDatasource()[PromotionPresenter.sortingRow]
        if sortingCondition.title != currenttitle {
            presenter.toggleItem(PromotionPresenter.sortingRow)
        }
        
        let newValue = presenter.getDatasource()
        totalSource.accept(newValue)
    }
    
    func getConditions() -> [FilterItem] {
        return totalSource.value
    }
    
    func toggle(_ row: Int) {
        if row == PromotionPresenter.sortingRow {
            showSortingView()
        }
        else {
            presenter.toggleItem(row)
            
            let newValue = presenter.getDatasource()
            totalSource.accept(newValue)
        }
    }
    
    func showSortingView() {
        let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as! InteractiveCell
        
        let descLabel = UILabel()
        descLabel.textColor = .whitePure
        descLabel.text = Localize.string("bonus_orderby_desc")
        descLabel.font = UIFont(name: "PingFangSC-Medium", size: 14)
        
        let descTap = UITapGestureRecognizer(target: self, action: #selector(sortingDescTapped(_:)))
        descLabel.isUserInteractionEnabled = true
        descLabel.addGestureRecognizer(descTap)
        
        let ascLabel = UILabel()
        ascLabel.textColor = .whitePure
        ascLabel.text = Localize.string("bonus_orderby_asc")
        ascLabel.font = UIFont(name: "PingFangSC-Medium", size: 14)
        
        let ascTap = UITapGestureRecognizer(target: self, action: #selector(sortingAscTapped(_:)))
        ascLabel.isUserInteractionEnabled = true
        ascLabel.addGestureRecognizer(ascTap)
        
        sortingStackView = UIStackView(
            frame: CGRect(
                x: cell.titleLbl.frame.origin.x - 8,
                y: cell.frame.origin.y,
                width: cell.frame.width * 0.87,
                height: cell.frame.height * 2
            )
        )
        sortingStackView.distribution = .fillEqually
        sortingStackView.alignment = .fill
        sortingStackView.axis = .vertical
        sortingStackView.insertArrangedSubview(descLabel, at: 0)
        sortingStackView.insertArrangedSubview(ascLabel, at: 1)
        sortingStackView.backgroundColor = UIColor.black131313
        sortingStackView.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        sortingStackView.isLayoutMarginsRelativeArrangement = true
        
        tableView.addSubview(sortingStackView ?? UIView())
    }
    
    func lastRowSeparator() -> CALayer {
        let sepFrame = CGRect(x: 0, y: -1, width: self.tableView.bounds.width, height: 1)
        let sep = CALayer()
        sep.frame = sepFrame
        sep.backgroundColor = UIColor.gray3C3E40.cgColor
        return sep
    }
    
    func displayLastRowSperator() {
        let seprator = UIView(frame: .zero)
        seprator.layer.addSublayer(lastRowSeparator())
        tableView.tableFooterView = seprator
    }
}

// MARK: - TableViewDelegate

extension PromotionFilterViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 2 {
            return 69
        } else {
            return 48
        }
    }
}

class FilterConditionViewController: UIViewController {
    var presenter: FilterPresentProtocol!
    var conditionCallbck: (([FilterItem]) -> ())?
}


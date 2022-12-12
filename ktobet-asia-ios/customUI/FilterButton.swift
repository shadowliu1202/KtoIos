import UIKit
import RxSwift
import RxCocoa

class FilterButton: UIView {
    typealias ConditionCallbck = (([FilterItem]) -> ())
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var interactiveBtn: UIButton!
    
    private weak var parentController: UIViewController?
    private var presenter: FilterPresentProtocol?
    private var initalFilterItem: [FilterItem]?
    private var conditionCallback: ConditionCallbck?
    private var vc: FilterConditionViewController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initUI()
    }
    
    private func initUI() {
        loadXib()
        setTitle(Localize.string("common_all"))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if parentController == nil{
            parentController = self.parentViewController
        }
    }
    
    private func loadXib(){
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "FilterButton", bundle: bundle)
        let xibView = nib.instantiate(withOwner: self, options: nil)[0] as? UIView
        xibView?.layer.cornerRadius = 8
        xibView?.layer.masksToBounds = true
        addSubview(xibView!)
        xibView?.translatesAutoresizingMaskIntoConstraints = false
        let attributes: [NSLayoutConstraint.Attribute] = [.top, .bottom, .right, .left]
        NSLayoutConstraint.activate(attributes.map {
            NSLayoutConstraint(item: xibView!, attribute: $0, relatedBy: .equal, toItem: xibView!.superview, attribute: $0, multiplier: 1, constant: 0)
        })
    }
    
    @IBAction private func btnFilterPressed(_ sender : UIButton) {
        goToFilterVC()
    }
    
    func setTitle(_ title: String?) {
        self.titleLabel.text = title
    }
    
    func setTitle(_ source: [FilterItem]?) {
        var text = ""
        if isSelectedAllFilterItem(source: source) {
            text = Localize.string("common_all")
        } else {
            text = filterItemToTitleString(source: source)
        }
        
        self.setTitle(text)
    }
    
    private func isSelectedAllFilterItem(source: [FilterItem]?) -> Bool {
        let allSelectCount = source?.filter({ $0.isSelected == true }).count
        let interactiveCount = source?.filter({$0.type != .static}).count
        return allSelectCount == interactiveCount
    }
    
    private func filterItemToTitleString(source: [FilterItem]?) -> String {
        var text = ""
        source?.filter({ $0.isSelected == true }).forEach { text.append("\($0.title)/") }
        text = String(text.dropLast())
        return text
    }
    
    @discardableResult
    func setPromotionStyleTitle(source: [FilterItem]?) -> Self {
        var text = ""
        if isSelectedAllFilterItem(source: source) {
            text = (source?[PromotionPresenter.sortingRow].title ?? Localize.string("bonus_orderby_desc")) + "、" + Localize.string("common_all")
        } else {
            text = filterItemToTitleString(source: source)
            let firstSymbolIndex = text.firstIndex(of: "/")!
            text.replaceSubrange(firstSymbolIndex...firstSymbolIndex, with: "、")
        }
        
        self.setTitle(text)
        return self
    }
    
    @discardableResult
    func setGotoFilterVC(vc: FilterConditionViewController) -> Self {
        self.vc = vc
        return self
    }
    
    @discardableResult
    func set(_ presenter: FilterPresentProtocol) -> Self {
        self.presenter = presenter
        return self
    }
    
    @discardableResult
    func set(_ initalFilterItems: [FilterItem]?) -> Self {
        self.initalFilterItem = initalFilterItems
        return self
    }
    
    @discardableResult
    func set(_ callback: @escaping ConditionCallbck) -> Self {
        self.conditionCallback = callback
        return self
    }
    
    private func goToFilterVC() {
        guard let presenter = presenter,
              let vc = self.vc
        else { return }
        
        vc.presenter = presenter
        
        if let filter = initalFilterItem {
            presenter.setConditions(filter + [])
        }
        
        vc.conditionCallback = { [weak self] (items) in
            self?.setTitle(items)
            self?.conditionCallback?(items)
        }
        
        parentController?.navigationController?.pushViewController(vc, animated: true)
    }
}

extension Reactive where Base: FilterButton {
    var touchUpInside: ControlEvent<Void> {
        base.interactiveBtn.rx.controlEvent(.touchUpInside)
    }
}
 

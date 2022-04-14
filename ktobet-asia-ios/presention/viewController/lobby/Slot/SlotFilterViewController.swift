import UIKit
import RxSwift
import SharedBu

class SlotFilterViewController: UIViewController {
    static let segueIdentifier = "toSlotFilter"
    
    @IBOutlet weak var gameFeatureView: UIView!
    @IBOutlet weak var gameThemeView: UIView!
    @IBOutlet weak var payLineWayView: UIView!
    
    @IBOutlet weak var slotSeparateButton: UIButton!
    @IBOutlet weak var slotWildButton: UIButton!
    @IBOutlet weak var slotFeatureButton: UIButton!
    @IBOutlet weak var freeSpinButton: UIButton!
    @IBOutlet weak var bidirectionalButton: UIButton!
    
    @IBOutlet weak var slotAsiaButton: UIButton!
    @IBOutlet weak var slotWestButton: UIButton!
    
    @IBOutlet weak var lessThan15Button: UIButton!
    @IBOutlet weak var slot15To30Button: UIButton!
    @IBOutlet weak var moreThan30Button: UIButton!
    @IBOutlet weak var allMoneyButton: UIButton!
    @IBOutlet weak var otherButton: UIButton!
    
    @IBOutlet weak var selectedCountLabel: UILabel!
    
    var conditionCallbck: ((_ dateType: [SlotGameFilter]) -> ())?
    var barButtonItems: [UIBarButtonItem] = []
    var featureButtons: [UIButton] = []
    var themeButtons: [UIButton] = []
    var payLineWayButtons: [UIButton] = []
    var options: [SlotGameFilter] = []
    private var viewModel = DI.resolve(SlotViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bind(position: .left, barButtonItems: .kto(.close))
        self.bind(position: .right, barButtonItems: .kto(.text(text: Localize.string("product_clear_filters"))))
        featureButtons = [slotSeparateButton, slotWildButton, slotFeatureButton, freeSpinButton, bidirectionalButton]
        themeButtons = [slotAsiaButton, slotWestButton]
        payLineWayButtons = [lessThan15Button, slot15To30Button, moreThan30Button, allMoneyButton, otherButton]
        setButtonTag(buttons: featureButtons, filterType: 0)
        setButtonTag(buttons: themeButtons, filterType: 1)
        setButtonTag(buttons: payLineWayButtons, filterType: 2)
        viewModel.gameCountFilters.onNext(options)
        viewModel.gameCountWithSearchFilters.subscribe(onNext: {[weak self] (count, filters) in
            if filters.count == 0 {
                self?.selectedCountLabel.text = Localize.string("product_all_games_selected")
            } else {
                self?.selectedCountLabel.text = String(format: Localize.string("product_count_selected_games"), "\(count)")
            }
        }).disposed(by: disposeBag)
        
        self.gameFeatureView.addBorder(.bottom, size: 1, color: UIColor(red: 60.0/255.0, green: 62.0/255.0, blue: 64.0/255.0, alpha: 1.0))
        self.gameThemeView.addBorder(.bottom, size: 1, color: UIColor(red: 60.0/255.0, green: 62.0/255.0, blue: 64.0/255.0, alpha: 1.0))
    }
    
    @IBAction func featureTouchDownTag(_ sender: UIButton) {
        selectTag(sender, filterType: 0)
    }
    
    @IBAction func themeTouchDownTag(_ sender: UIButton) {
        selectTag(sender, filterType: 1)
    }
    
    @IBAction func payTouchDownTag(_ sender: UIButton) {
        selectTag(sender, filterType: 2)
    }
    
    @IBAction func done(_ sender: UIButton) {
        conditionCallbck?(options)
        self.dismiss(animated: true, completion: nil)
    }
    
    private func setTagButtonStyle(button: UIButton) {
        button.setTitleColor(.black_two, for: .selected)
        button.setTitleColor(.yellowFull, for: .normal)
        button.setBackgroundColor(color: .black_two, forUIControlState: .normal)
        button.setBackgroundColor(color: .yellowFull, forUIControlState: .selected)
    }
    
    private func selectTag(_ sender: UIButton, filterType: Int) {
        let filterClass: AnyClass? = getFilterType(filterType: filterType)
        guard let type = filterClass else { return }
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            options.append(SlotGameFilter.Companion.init().allFilters.first{ $0.isKind(of: type) && $0.getDecimalValue() == Double(sender.tag)}!)
        } else {
            options.removeAll { (filter) -> Bool in
                filter.isKind(of: type) && filter.getDecimalValue() == Double(sender.tag)
            }
        }
        
        viewModel.gameCountFilters.onNext(options)
    }
    
    private func setButtonTag(buttons: [UIButton], filterType: Int) {
        buttons.forEach{ setTagButtonStyle(button: $0)}
        var previousIndex = 0
        for (index, button) in buttons.enumerated() {
            if index == 0 {
                previousIndex = 1
            } else {
                previousIndex = previousIndex * 2
            }
            
            button.tag = previousIndex
            let filterClass: AnyClass? = getFilterType(filterType: filterType)
            guard let type = filterClass else { return }
            if options.contains(where: { $0.isKind(of: type) && $0.getDecimalValue() == Double(previousIndex) }) {
                button.isSelected = true
            }
        }
    }
    
    private func getFilterType(filterType: Int) -> AnyClass? {
        switch filterType {
        case 0:
            return SlotGameFilter.SlotGameFeature.self
        case 1:
            return SlotGameFilter.SlotGameTheme.self
        case 2:
            return SlotGameFilter.SlotPayLineWay.self
        default:
            return nil
        }
    }
}

extension SlotFilterViewController: BarButtonItemable {
    func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
        let allButtons = featureButtons + themeButtons + payLineWayButtons
        allButtons.forEach{ $0.isSelected = false }
        options = []
        viewModel.gameCountFilters.onNext(options)
    }

    func pressedLeftBarButtonItems(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
        self.presentationController?.delegate?.presentationControllerDidDismiss?(self.presentationController!)
    }
}

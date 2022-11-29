import UIKit
import RxSwift
import RxCocoa
import SharedBu

class SetMainPageViewController: LobbyViewController {
    static let segueIdentifier = "toSetMainPage"
    
    @IBOutlet weak var sportbookView: ProductItemView!
    @IBOutlet weak var casinoView: ProductItemView!
    @IBOutlet weak var slotView: ProductItemView!
    @IBOutlet weak var numbergameView: ProductItemView!
    @IBOutlet weak var submitBtn: UIButton!
    
    private var selectedProduct: ProductType!
    private var viewModel = Injectable.resolve(ConfigurationViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        initUI()
        dataBinding()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    private func initUI() {
        let callback = methodPointer(obj: self, method: SetMainPageViewController.changeSelected(_:))
        sportbookView.setProductType(.sbk).setOnClick(callback)
        casinoView.setProductType(.casino).setOnClick(callback)
        slotView.setProductType(.slot).setOnClick(callback)
        numbergameView.setProductType(.numbergame).setOnClick(callback)
    }
    
    private func dataBinding() {
        viewModel.fetchDefaultProduct()
            .subscribe(onSuccess: { [weak self] in
                self?.changeSelected($0)
            }, onFailure: { [weak self] in
                self?.handleErrors($0)
                self?.submitBtn.isValid = false
            })
            .disposed(by: disposeBag)
        
        submitBtn.rx.touchUpInside
            .bind(onNext: { [weak self] in
                self?.submitBtn.isEnabled = false
                self?.saveDefaultProduct()
            })
            .disposed(by: disposeBag)
    }
    
    private func saveDefaultProduct() {
        viewModel
            .saveDefaultProduct(productType: self.selectedProduct)
            .subscribe(onCompleted: { [weak self] in
                guard let self = self else {
                    Logger.shared.debug("Missing reference.")
                    return
                }
                
                self.popThenToastSuccess()
                self.viewModel.refreshPlayerInfoCache(self.selectedProduct)
            }, onError: { [weak self] in
                self?.submitBtn.isEnabled = true
                self?.handleErrors($0)
            })
            .disposed(by: disposeBag)
    }
    
    private func changeSelected(_ productType: ProductType) {
        sportbookView.isSelected = false
        casinoView.isSelected = false
        slotView.isSelected = false
        numbergameView.isSelected = false
        self.selectedProduct = productType
        switch productType {
        case .sbk:
            self.sportbookView.isSelected = true
        case .casino:
            self.casinoView.isSelected = true
        case .slot:
            self.slotView.isSelected = true
        case .numbergame:
            self.numbergameView.isSelected = true
        default:
            self.selectedProduct = ProductType.none
            break
        }
        self.setUpSubmitBtn(selectedProduct)
    }

    private func setUpSubmitBtn(_ productType: ProductType) {
        self.submitBtn.isValid = productType != .none
    }
    
    private func popThenToastSuccess() {
        NavigationManagement.sharedInstance.popViewController({ [weak self] in
            self?.showToastOnBottom(Localize.string("common_setting_done"), img: UIImage(named: "Success"))
        })
    }
}

func methodPointer<T: AnyObject>(obj: T, method: @escaping (T) -> (ProductType) -> Void) -> ((ProductType) -> Void) {
    return { [unowned obj] in method(obj)($0) }
}

class ProductItemView: UIView {
    private var clickCallback: ((_ productType: ProductType) -> Void)?
    private(set) var productType: ProductType!
    @IBOutlet private weak var radioButton: RadioButton!
    
    var isSelected: Bool = false {
        didSet {
            modifySelected(isSelected)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addGesture()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addGesture()
    }
    
    func setProductType(_ type: ProductType) -> ProductItemView {
        self.productType = type
        return self
    }
    
    func setOnClick(_ callback: @escaping (_ productType: ProductType) -> Void) {
        self.clickCallback = callback
    }
    
    private func modifySelected(_ selected: Bool) {
        self.backgroundColor = selected ? .gray454545 : .gray333333
        self.radioButton.isSelected = selected
        layoutSubviews()
    }
    
    private func addGesture() {
        let gesture =  UITapGestureRecognizer(target: self, action: #selector(self.pressAction(_:)))
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(gesture)
    }
    
    @objc private func pressAction(_ sender: UITapGestureRecognizer) {
        self.clickCallback?(productType)
    }
    
    @IBAction func pressRadioBtn(_ sender: Any) {
        self.clickCallback?(productType)
    }
}

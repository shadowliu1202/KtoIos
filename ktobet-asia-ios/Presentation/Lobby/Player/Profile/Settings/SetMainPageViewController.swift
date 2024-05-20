import RxCocoa
import RxSwift
import sharedbu
import UIKit

class SetMainPageViewController: LobbyViewController {
    static let segueIdentifier = "toSetMainPage"

    @IBOutlet weak var sportbookView: ProductItemView!
    @IBOutlet weak var casinoView: ProductItemView!
    @IBOutlet weak var slotView: ProductItemView!
    @IBOutlet weak var numbergameView: ProductItemView!
    @IBOutlet weak var submitBtn: UIButton!

    private var selectedProduct: DefaultProductType!
    private var viewModel = Injectable.resolve(ConfigurationViewModel.self)!
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        initUI()
        dataBinding()
    }

    private func initUI() {
        let callback = methodPointer(obj: self, method: SetMainPageViewController.changeSelected(_:))
        sportbookView.setProductType(.sbk).setOnClick(callback)
        casinoView.setProductType(.casino).setOnClick(callback)
        slotView.setProductType(.slot).setOnClick(callback)
        numbergameView.setProductType(.numberGame).setOnClick(callback)
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
            .subscribe(onCompleted: { [unowned self] in
                popThenToastSuccess()
                viewModel.refreshPlayerInfoCache(convertDefaultProduct(selectedProduct))
            }, onError: { [weak self] in
                self?.submitBtn.isEnabled = true
                self?.handleErrors($0)
            })
            .disposed(by: disposeBag)
    }
  
    @available(*, deprecated, message: "will remove after move player profile to sharebu")
    private func convertDefaultProduct(_ type: DefaultProductType) -> ProductType {
        switch type {
        case .slot: return ProductType.slot
        case .casino: return ProductType.casino
        case .sbk: return ProductType.sbk
        case .numberGame: return ProductType.numberGame
        }
    }

    private func changeSelected(_ productType: DefaultProductType?) {
        guard let productType else { return }
    
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
        case .numberGame:
            self.numbergameView.isSelected = true
        }
    }

    private func popThenToastSuccess() {
        NavigationManagement.sharedInstance.popViewController({ [weak self] in
            self?.showToast(Localize.string("common_setting_done"), barImg: .success)
        })
    }
}

func methodPointer<T: AnyObject>(
    obj: T,
    method: @escaping (T) -> (DefaultProductType?) -> Void)
    -> ((DefaultProductType?) -> Void)
{
    { [unowned obj] in method(obj)($0) }
}

class ProductItemView: UIView {
    private var clickCallback: ((_ productType: DefaultProductType) -> Void)?
    private(set) var productType: DefaultProductType!
    @IBOutlet private weak var radioButton: RadioButton!

    var isSelected = false {
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

    func setProductType(_ type: DefaultProductType) -> ProductItemView {
        self.productType = type
        return self
    }

    func setOnClick(_ callback: @escaping (_ productType: DefaultProductType) -> Void) {
        self.clickCallback = callback
    }

    private func modifySelected(_ selected: Bool) {
        self.backgroundColor = selected ? .inputFocus : .inputDefault
        self.radioButton.isSelected = selected
        layoutSubviews()
    }

    private func addGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.pressAction(_:)))
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(gesture)
    }

    @objc
    private func pressAction(_: UITapGestureRecognizer) {
        self.clickCallback?(productType)
    }

    @IBAction
    func pressRadioBtn(_: Any) {
        self.clickCallback?(productType)
    }
}

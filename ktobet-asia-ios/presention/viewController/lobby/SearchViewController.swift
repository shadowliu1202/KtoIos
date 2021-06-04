import UIKit
import RxSwift
import RxCocoa
import SharedBu

class SearchViewController: SearchProduct {
    
    @IBOutlet var searchBarView: UISearchBar!
    @IBOutlet weak var suggestionView: UIView!
    @IBOutlet weak var tagsStackView: UIStackView!
    @IBOutlet weak var gamesCollectionView: WebGameCollectionView!
    lazy var gameDataSourceDelegate = { return SearchGameDataSourceDelegate(self) }()
    private var gameData: [WebGameWithProperties] = [] {
        didSet {
            self.switchContent(gameData)
            self.gameDataSourceDelegate.searchKeyword = self.searchText.value
            self.reloadGameData(gameData)
        }
    }
    private let searchText = BehaviorRelay<String?>(value: nil)
    var viewModel: ProductViewModel?
    private var keepNavigationBar: UIColor?
    private var disposeBag: DisposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self)
        initUI()
        dataBinding()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Show keyboard in correct way
        self.definesPresentationContext = true
        DispatchQueue.main.async {
            self.searchBarView.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.barTintColor = keepNavigationBar
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    private func initUI() {
        initSearchTitle()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification:NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        var keyboardFrame:CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        var contentInset = UIEdgeInsets.zero
        contentInset.bottom = keyboardFrame.size.height + 44
        gamesCollectionView.contentInset = contentInset
    }

    @objc func keyboardWillHide(notification:NSNotification) {
        var contentInset = UIEdgeInsets.zero
        contentInset.bottom = 96
        gamesCollectionView.contentInset = contentInset
    }
    
    @objc private func pressDone(_ sender: UIButton) {
        self.searchBarView.endEditing(true)
    }
    
    private func initSearchTitle() {
        let frame = CGRect(x: 0, y: 0, width: searchBarView.frame.width, height: 44)
        let titleView = UIView(frame: frame)
        searchBarView.removeMagnifyingGlass()
        searchBarView.setClearButtonColorTo(color: .white)
        searchBarView.setCursorColorTo(color: UIColor.redForDarkFull)
        titleView.addSubview(searchBarView)
        searchBarView.center = titleView.convert(titleView.center, from: titleView.superview)
        navigationItem.titleView = titleView
        keepNavigationBar = self.navigationController?.navigationBar.barTintColor
        self.navigationController?.navigationBar.barTintColor = UIColor.backgroundSidebarMineShaftGray
        searchBarView.addDoneButton(title: "Done", target: self, selector: #selector(pressDone(_:)))
    }
    
    private func dataBinding() {
        viewModel?.clearSearchResult()
        viewModel?.searchSuggestion()
            .catchError({ [weak self] (error) -> Single<[String]> in
                self?.handleUnknownError(error)
                return Single.just([])
            })
            .subscribe(onSuccess: { [weak self] (suggestions) in
            guard let `self` = self else { return }
            self.addTagBtns(stackView: self.tagsStackView, data: suggestions)
        }).disposed(by: disposeBag)
        
        searchBarView.rx.text.orEmpty.asDriver().drive(searchText).disposed(by: disposeBag)
        searchText.asObservable().subscribe(onNext: { [weak self] (text) in
            if let `self` = self, self.searchBarView.text != text {
                self.searchBarView.text = text
            }
            if text?.isEmpty ?? true {
                self?.searchBarView.endEditing(true)
                self?.switchContent()
            }
        }).disposed(by: disposeBag)
        searchText.asObservable()
            .debounce(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
            .observeOn(MainScheduler.asyncInstance)
            .bind(onNext: { [weak self] (text) in
                if text?.isEmpty == false {
                    self?.viewModel?.triggerSearch(text)
                }
            }).disposed(by: disposeBag)
        
        searchBarView.rx.searchButtonClicked.bind { [weak self] (_) in
            self?.searchBarView.endEditing(true)
        }.disposed(by: disposeBag)
        
        viewModel?.searchResult()
            .subscribe(onNext: { [weak self] (event) in
                if let games = event.element {
                    self?.gameData = games
                }
                if let error = event.error {
                    self?.switchContent()
                    self?.handleUnknownError(error)
                }
            }).disposed(by: self.disposeBag)
    }
    
    private func switchContent(_ games: [WebGameWithProperties]? = nil) {
        if let items = games, items.count > 0 {
            self.gamesCollectionView.isHidden = false
            self.suggestionView.isHidden = true
        } else {
            self.gamesCollectionView.isHidden = true
            self.suggestionView.isHidden = false
        }
    }
    
    private func addTagBtns(stackView: UIStackView, data: [String]) {
        stackView.removeAllArrangedSubviews()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 8
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        
        var btns: [[UIButton]] = [[]]
        var childRow = createOneChildView(stackView)
        var rowInex = 0
        stackView.addArrangedSubview(childRow)
        for i in 0..<data.count {
            let dx = btns[rowInex].reduce(0) { (total, btn) -> CGFloat in
                return total + btn.frame.size.width + 8
            }
            let frame = CGRect(x: dx, y: 0, width: 180, height: 40 )
            let button = UIButton(frame: frame)
            button.setTitle("\(data[i])", for: .normal)
            button.setTitleColor(UIColor.textPrimaryDustyGray, for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 18, bottom: 8, right: 18)
            button.sizeToFit()
            button.layer.cornerRadius = 16
            button.layer.masksToBounds = true
            button.applyGradient(colors: [UIColor(rgb: 0x32383e).cgColor, UIColor(rgb: 0x17191c).cgColor])
            if dx+button.frame.size.width > tagsStackView.frame.size.width {
                childRow = createOneChildView(stackView)
                rowInex += 1
                btns.append([])
                stackView.addArrangedSubview(childRow)
                button.frame.origin.x = 0
            }
            button.addTarget(self, action: #selector(pressSearchTag(_:)), for: .touchUpInside)
            childRow.addSubview(button)
            btns[rowInex].append(button)
        }
    }
    
    private func createOneChildView(_ parentView: UIStackView) -> UIView {
        let childRow = UIView(frame: .zero)
        childRow.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        childRow.widthAnchor.constraint(equalToConstant: parentView.frame.size.width).isActive = true
        return childRow
    }
    
    @objc private func pressSearchTag(_ sender: UIButton) {
        self.searchBarView.becomeFirstResponder()
        let text = sender.title(for: .normal)
        if self.searchBarView.text != text {
            self.searchText.accept(text)
        }
    }
    
    // MARK: SearchBaseCollection
    func setCollectionView() -> UICollectionView {
        return gamesCollectionView
    }
    
    func setProductGameDataSourceDelegate() -> SearchGameDataSourceDelegate {
        return gameDataSourceDelegate
    }
    
    func setViewModel() -> ProductViewModel? {
        return viewModel
    }
}

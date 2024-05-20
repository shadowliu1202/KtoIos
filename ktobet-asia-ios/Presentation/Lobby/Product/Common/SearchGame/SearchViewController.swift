import RxCocoa
import RxSwift
import sharedbu
import UIKit

class SearchViewController: SearchProduct, UISearchBarDelegate {
    private static let searchCharacterLimit = 30
  
    @IBOutlet var searchBarView: UISearchBar!
    @IBOutlet weak var suggestionView: UIView!
    @IBOutlet weak var tagsStackView: UIStackView!
    @IBOutlet weak var gamesCollectionView: WebGameCollectionView!
    @IBOutlet weak var lackConditionView: UIView!
  
    private var emptyStateView: EmptyStateView!
  
    lazy var gameDataSourceDelegate = SearchGameDataSourceDelegate(self)
    private var gameData: [WebGameWithDuplicatable] = [] {
        didSet {
            self.gameDataSourceDelegate.searchKeyword = self.searchText.value
            self.reloadGameData(gameData)
        }
    }

    private let searchText = BehaviorRelay<String?>(value: nil)
    var viewModel: ProductViewModel?
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
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
        self.searchBarView.resignFirstResponder()

        Theme.shared.configNavigationBar(
            navigationController,
            backgroundColor: UIColor.greyScaleDefault.withAlphaComponent(0.9))
    }

    private func initUI() {
        initSearchTitle()
        initEmptyStateView()
    
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }

    @objc
    func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        var keyboardFrame: CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        var contentInset = UIEdgeInsets.zero
        contentInset.bottom = keyboardFrame.size.height + 44
        gamesCollectionView.contentInset = contentInset
    }

    @objc
    func keyboardWillHide(notification _: NSNotification) {
        var contentInset = UIEdgeInsets.zero
        contentInset.bottom = 96
        gamesCollectionView.contentInset = contentInset
    }

    @objc
    private func pressDone(_: UIButton) {
        self.searchBarView.endEditing(true)
    }

    private func initSearchTitle() {
        Theme.shared.configNavigationBar(
            navigationController,
            backgroundColor: UIColor.greyScaleChatWindow.withAlphaComponent(0.9))

        let frame = CGRect(x: -10, y: 0, width: searchBarView.frame.width, height: 32)
        let titleView = UIView(frame: frame)
        searchBarView.removeMagnifyingGlass()
        searchBarView.setClearButtonColorTo(color: .white)
        searchBarView.setCursorColorTo(color: UIColor.primaryDefault)
        searchBarView.frame = .init(origin: .zero, size: titleView.frame.size)
        searchBarView.delegate = self
        titleView.addSubview(searchBarView)
        searchBarView.center = titleView.convert(titleView.center, from: titleView.superview)
        navigationItem.titleView = titleView
        searchBarView.addDoneButton(title: "Done", target: self, selector: #selector(pressDone(_:)))
        searchBarView.searchTextField.borderStyle = .none
        searchBarView.searchTextField.backgroundColor = UIColor.black
        searchBarView.searchTextField.attributedPlaceholder = NSAttributedString(
            string: " \(Localize.string("product_enter_search_keyword"))",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.textPrimary])
    }
  
    private func initEmptyStateView() {
        emptyStateView = EmptyStateView(
            icon: UIImage(named: "No Results Found"),
            description: Localize.string("common_no_games_found"),
            keyboardAppearance: .possible)
        emptyStateView.isHidden = true
    
        view.addSubview(emptyStateView)

        emptyStateView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func dataBinding() {
        viewModel?.clearSearchResult()

        viewModel?.searchSuggestion()
            .catch({ [weak self] error -> Single<[String]> in
                self?.handleErrors(error)
                return Single.just([])
            })
            .subscribe(onSuccess: { [weak self] suggestions in
                guard let self else { return }
                self.addTagBtns(stackView: self.tagsStackView, data: suggestions)
            })
            .disposed(by: disposeBag)

        searchBarView.rx.text.orEmpty.asDriver()
            .drive(searchText)
            .disposed(by: disposeBag)

        searchText
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] text in
                if self?.searchBarView.text != text {
                    self?.searchBarView.text = text
                }
                if text.isEmpty {
                    self?.searchBarView.endEditing(true)
                }
            })
            .disposed(by: disposeBag)

        searchText.asObservable()
            .debounce(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
            .observe(on: MainScheduler.asyncInstance)
            .bind(onNext: { [weak self] text in
                self?.viewModel?.triggerSearch(text)
            })
            .disposed(by: disposeBag)

        searchBarView.rx.searchButtonClicked.bind { [weak self] _ in
            self?.viewModel?.triggerSearch(self?.searchText.value)
            self?.searchBarView.endEditing(true)
        }
        .disposed(by: disposeBag)

        Observable.combineLatest(searchText.asObservable(), viewModel!.searchResult())
            .subscribe(onNext: { [weak self] text, event in
                if let games = event.element {
                    self?.gameData = games.filter { $0.gameStatus != .maintenance }
                    self?.changeContent(text: text!, games: games)
                }
                if let error = event.error {
                    self?.handleErrors(error)
                }
            })
            .disposed(by: self.disposeBag)
    }

    private func changeContent(text: String, games: [WebGameWithProperties]) {
        let searchKeyword = SearchKeyword(keyword: text)
        if text.isEmpty {
            takeSuggestion()
        }
        else if !searchKeyword.isSearchPermitted(), text.isNotEmpty {
            lackCondition()
        }
        else if games.count == 0 {
            noResult()
        }
        else {
            displayResult()
        }
    }

    private func displayResult() {
        gamesCollectionView.isHidden = false
        emptyStateView.isHidden = true
        suggestionView.isHidden = true
        lackConditionView.isHidden = true
    }

    private func noResult() {
        gamesCollectionView.isHidden = true
        emptyStateView.isHidden = false
        suggestionView.isHidden = true
        lackConditionView.isHidden = true
    }

    private func lackCondition() {
        gamesCollectionView.isHidden = true
        emptyStateView.isHidden = true
        suggestionView.isHidden = true
        lackConditionView.isHidden = false
    }

    private func takeSuggestion() {
        gamesCollectionView.isHidden = true
        emptyStateView.isHidden = true
        suggestionView.isHidden = false
        lackConditionView.isHidden = true
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
            let dx = btns[rowInex].reduce(0) { total, btn -> CGFloat in
                total + btn.frame.size.width + 8
            }
            let frame = CGRect(x: dx, y: 0, width: 180, height: 40)
            let button = UIButton(frame: frame)
            button.setTitle("\(data[i])", for: .normal)
            button.setTitleColor(UIColor.textPrimary, for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 18, bottom: 8, right: 18)
            button.layer.cornerRadius = 16
            button.layer.masksToBounds = true
            button.applyGradient(vertical: [UIColor(rgb: 0x32383e).cgColor, UIColor(rgb: 0x17191c).cgColor])
            button.titleLabel?.font = UIFont(name: "PingFangSC-Medium", size: 12)
            button.sizeToFit()
            if dx + button.frame.size.width > tagsStackView.frame.size.width {
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

    @objc
    private func pressSearchTag(_ sender: UIButton) {
        self.searchBarView.becomeFirstResponder()
        let text = sender.title(for: .normal)
        if self.searchBarView.text != text {
            self.searchText.accept(text)
        }
    }

    // MARK: SearchBaseCollection
    func setCollectionView() -> UICollectionView {
        gamesCollectionView
    }

    func setProductGameDataSourceDelegate() -> SearchGameDataSourceDelegate {
        gameDataSourceDelegate
    }

    func setViewModel() -> ProductViewModel? {
        viewModel
    }

    override func setProductType() -> ProductType {
        viewModel!.getGameProductType()
    }

    // MARK: UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = searchBar.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: text)
        
        let isSpellingMode = (searchBar.searchTextField.markedTextRange != nil)
        
        return isSpellingMode ? true : countTextLength(newText) <= Self.searchCharacterLimit
    }

    private func countTextLength(_ text: String) -> Int {
        var count = 0

        for scalar in text.unicodeScalars {
            let value = scalar.value
            let isHalfWidthCharacter = (value >= 0x0000 && value <= 0x00FF)
      
            if isHalfWidthCharacter {
                count += 1
            }
            else {
                count += 2
            }
        }

        return count
    }
  
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if countTextLength(searchText) > Self.searchCharacterLimit {
            let trimmedText = trimText(searchText, to: Self.searchCharacterLimit)
            searchBar.text = trimmedText
        }
    }
  
    private func trimText(_ text: String, to maxLength: Int) -> String {
        var trimmedText = text
      
        while countTextLength(trimmedText) > maxLength {
            let endIndex = trimmedText.index(trimmedText.endIndex, offsetBy: -1)
            trimmedText = String(trimmedText[..<endIndex])
        }
      
        return trimmedText
    }
}

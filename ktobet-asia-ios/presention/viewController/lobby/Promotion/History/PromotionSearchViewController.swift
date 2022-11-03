import UIKit
import RxSwift
import RxCocoa


class PromotionSearchViewController: LobbyViewController {
    @IBOutlet var searchBarView: UISearchBar!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var emptyView: UIView!
    private let FirstEmptyTime = 1
    private var viewModel = Injectable.resolve(PromotionHistoryViewModel.self)!
    
    private let searchText = BehaviorRelay<String?>(value: nil)
    private var keepNavigationBar: UIColor?
    private var disposeBag: DisposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        initUI()
        dataBinding()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.definesPresentationContext = true
        DispatchQueue.main.async {
            self.searchBarView.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.barTintColor = keepNavigationBar
        disposeBag = DisposeBag()
        viewModel.keyword = "" 
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.contentSize.height = tableView.contentSize.height + 96
    }
    
    private func initUI() {
        initSearchTitle()
        tableView.register(UINib(nibName: "PromotionHistoryTableViewCell", bundle: nil), forCellReuseIdentifier: "PromotionHistoryTableViewCell")
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 96, right: 0)
        tableView.contentInset = insets
    }
    
    private func initSearchTitle() {
        let frame = CGRect(x: -10, y: 0, width: searchBarView.frame.width, height: 44)
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
        searchBarView.searchTextField.borderStyle = .none
        searchBarView.searchTextField.backgroundColor = UIColor.black
        searchBarView.searchTextField.attributedPlaceholder = NSAttributedString(string: " \(Localize.string("common_search"))", attributes: [NSAttributedString.Key.foregroundColor : UIColor.textPrimaryDustyGray])
    }
    
    private func dataBinding() {
        searchBarView.rx.text.orEmpty.asDriver().skip(FirstEmptyTime).drive(searchText).disposed(by: disposeBag)
        searchText.asObservable().subscribe(onNext: { [weak self] (text) in
            if let self = self, self.searchBarView.text != text {
                self.searchBarView.text = text
            }
            if text?.isEmpty ?? true {
                self?.searchBarView.endEditing(true)
            }
        }).disposed(by: disposeBag)
                
        searchText.asObservable()
            .debounce(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (text) in
                guard let keyword = text else { return }
                self?.fetchData(keyword)
            }).disposed(by: disposeBag)
        
        self.networkConnectRelay.filter{$0}.subscribe(onNext: { [weak self] _ in
            guard let keyword = self?.searchBarView.text else { return }
            self?.fetchData(keyword)
        }).disposed(by: disposeBag)
        
        searchBarView.rx.searchButtonClicked.bind { [weak self] (_) in
            self?.searchBarView.endEditing(true)
        }.disposed(by: disposeBag)
        
        viewModel.recordPagination.elements.bind(to: tableView.rx.items) {[weak self] (tableView, row, element) in
            guard let self = self else { return  UITableViewCell()}
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "PromotionHistoryTableViewCell", cellType: PromotionHistoryTableViewCell.self)
            cell.config(element, tableView: self.tableView)
            return cell
        }.disposed(by: disposeBag)

        viewModel.recordPagination.elements.bind(onNext: {[weak self] couponHistories in
            self?.tableView.isHidden = couponHistories.count == 0
            self?.emptyView.isHidden = couponHistories.count != 0
        }).disposed(by: disposeBag)
        
        viewModel.recordPagination.error.subscribe(onNext: handleErrors).disposed(by: disposeBag)
        
        tableView.rx_reachedBottom
            .map{ _ in ()}
            .bind(to: viewModel.recordPagination.loadNextPageTrigger)
            .disposed(by: disposeBag)
    }
    
    private func fetchData(_ keyword: String) {
        self.viewModel.keyword = keyword
        self.viewModel.recordPagination.refreshTrigger.onNext(())
    }
    
    @objc private func pressDone(_ sender: UIButton) {
        self.searchBarView.endEditing(true)
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

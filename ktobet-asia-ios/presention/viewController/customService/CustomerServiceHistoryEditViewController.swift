import UIKit
import RxSwift
import RxCocoa
import SharedBu

class CustomerServiceHistoryEditViewController: LobbyViewController {
    static let segueIdentifier = "toCustomerServiceHistoryEditViewController"
    private var activityIndicator = UIActivityIndicatorView(style: .large)
    private var disposeBag = DisposeBag()
    private var isAllSelected = false
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var deleteBtn: UIButton!
    private var selectAllBtn: UIButton!
    
    var records: [ChatHistory] = []
    var selecteds: [ChatHistory] = []
    var deleteMode: DeleteMode = .include
    
    var viewModel = Injectable.resolve(CustomerServiceHistoryViewModel.self)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .close)
        initUI()
        dataBinding()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }

    private func initUI() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.setHeaderFooterDivider(headerHeight: 128)
        addHeaderView()
        tableView.rowHeight = UITableView.automaticDimension
        self.view.addSubview(activityIndicator, constraints: .center)
    }
    
    private func addHeaderView() {
        let headView = UIView(frame: .zero)
        headView.backgroundColor = UIColor.clear
        tableView.tableHeaderView?.addSubview(headView, constraints: [
                                .constraint(.equal, \.trailingAnchor, offset: 0),
                                .constraint(.equal, \.leadingAnchor, offset: 0),
                                .constraint(.equal, \.topAnchor, offset: 0),
                                .constraint(.equal, \.bottomAnchor, offset: 0)])
        
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.init(name: "PingFangSC-Semibold", size: 24)
        label.textColor = UIColor.whitePure
        label.text = Localize.string("customerservice_history_edit_title")
        headView.addSubview(label, constraints: [
            .constraint(.equal, \.trailingAnchor, offset: 30),
            .constraint(.equal, \.leadingAnchor, offset: 30),
            .constraint(.equal, \.topAnchor, offset: 30),
            .constraint(.equal, \.heightAnchor, length: 32)
        ])
        
        let button = UIButton(frame: .zero)
        button.titleLabel?.font =  UIFont(name: "PingFangSC-Medium", size: 14)
        button.setTitleColor(UIColor.yellowFFD500, for: .normal)
        button.contentHorizontalAlignment = .right
        headView.addSubview(button, constraints: [
            .constraint(.equal, \.trailingAnchor, offset: -16),
            .constraint(.equal, \.bottomAnchor, offset: -16),
            .constraint(.equal, \.heightAnchor, length: 20),
            .constraint(.greaterThanOrEqual, \.widthAnchor, length: 56)
        ])
        self.selectAllBtn = button
    }
    
    private func dataBinding() {
        fetchData(0)
        Observable.combineLatest(viewModel.getChatHistories(), viewModel.selectedHistory, viewModel.deleteMode)
            .catchError({ [weak self] (error) in
                self?.handleErrors(error)
                self?.activityIndicator.stopAnimating()
                return Observable.error(error)
            })
            .subscribe(onNext: { [weak self] (data, selected, deleteMode) in
                self?.records = data
                self?.selecteds = selected
                self?.deleteMode = deleteMode
                self?.activityIndicator.stopAnimating()
                self?.tableView.reloadData()
            }).disposed(by: disposeBag)
        
        viewModel.isAllHistorySelected.map({ [weak self] in
            self?.isAllSelected = $0
            return $0 ? Localize.string("common_unselect_all") : Localize.string("common_select_all")
        }).bind(to: selectAllBtn.rx.title(for: .normal)).disposed(by: disposeBag)
        
        selectAllBtn.rx.touchUpInside.flatMap({ [unowned self] _ -> Observable<DeleteMode> in
            self.isAllSelected.toggle()
            return Observable.just(self.isAllSelected ? .exclude : .include)
        }).bind(onNext: { [weak self] in
            self?.viewModel.updateDeleteMode($0)
        }).disposed(by: disposeBag)
        
        viewModel.isDeleteValid.bind(to: deleteBtn.rx.isValid).disposed(by: disposeBag)
        
        Observable.combineLatest(viewModel.isAllHistorySelected, viewModel.deleteCount).subscribe(onNext: { [weak self] (isAllselected, count) in
            var title: String = ""
            if isAllselected {
                title = Localize.string("common_delete_all")
            } else if count == 0 {
                title = Localize.string("common_delete")
            } else {
                title = Localize.string("common_delete_count", "\(count)")
            }
            self?.deleteBtn.setTitle(title, for: .normal)
        }).disposed(by: disposeBag)
        
        deleteBtn.rx.touchUpInside.bind(onNext: { [unowned self] _ in
            self.deleteBtn.isEnabled = false
            self.viewModel.deleteChatHistory().subscribe(onCompleted: { [weak self] in
                self?.deleteBtn.isEnabled = true
                self?.popThenToast()
            }, onError: { [weak self] in
                self?.handleErrors($0)
                self?.deleteBtn.isEnabled = true
            }).disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
    
    private func fetchData(_ lastIndex: Int) {
        self.activityIndicator.startAnimating()
        viewModel.fetchNext(from: lastIndex)
    }
    
    private func popThenToast() {
        NavigationManagement.sharedInstance.popViewController({
            if let topVc = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.topViewController {
                let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: topVc.view.frame.width, height: 48))
                toastView.show(on: topVc.view, statusTip: Localize.string("customerservice_chat_deleted"), img: UIImage(named: "Success"))
            }
        })
    }
}

extension CustomerServiceHistoryEditViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EditChatHistoryCell", cellType: EditChatHistoryCell.self).configure(item: self.records[indexPath.row], deleteMode: self.deleteMode, selectedHistory: self.selecteds)
        cell.removeBorder()
        if indexPath.row != 0 {
            cell.addBorder()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if isLoadingIndexPath(tableView, indexPath) && viewModel.hasNext(indexPath.row) {
            self.fetchData(indexPath.row)
        }
    }
    
    private func isLoadingIndexPath(_ tableView: UITableView, _ indexPath: IndexPath) -> Bool {
        let lastSectionIndex = tableView.numberOfSections - 1
        let lastRowIndex = tableView.numberOfRows(inSection: lastSectionIndex) - 1
        return indexPath.section == lastSectionIndex && indexPath.row == lastRowIndex
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.records[indexPath.row]
        viewModel.updateSelection(item)
    }
}

class EditChatHistoryCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var icon: UIImageView!
    
    func configure(item: ChatHistory, deleteMode: DeleteMode, selectedHistory: [ChatHistory]) -> Self {
        dateLabel.text = item.createDate.toDateTimeFormatString()
        messageLabel.text = item.title
        switch deleteMode {
        case .include:
            isChecked(selectedHistory.contains(item))
        case .exclude:
            isChecked(!selectedHistory.contains(item))
            break
        }
        return self
    }
    
    private func isChecked(_ b: Bool) {
        icon.image = b ? UIImage(named: "iconDoubleSelectionSelected24") : UIImage(named: "iconDoubleSelectionEmpty24")
    }
}

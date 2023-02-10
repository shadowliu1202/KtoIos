import UIKit
import RxSwift
import RxSwiftExt
import SharedBu

class NotificationSearchViewController: LobbyViewController {
    @IBOutlet weak var searchBarView: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var keywordLengthTipLabel: UILabel!
  
    private let viewModel = Injectable.resolve(NotificationViewModel.self)!
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        tableView.tableFooterView = UIView()
        initSearchTitle()
        dateBinding()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height + CoomonUISetting.bottomSpace, right: 0)
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: CoomonUISetting.bottomSpace, right: 0)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBarView.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
      
        Theme.shared.configNavigationBar(
          navigationController,
          backgroundColor: UIColor.black131313.withAlphaComponent(0.9))
    }

    private func dateBinding() {
        searchBarView.rx.text.orEmpty.bind(to: viewModel.input.keywod).disposed(by: disposeBag)
        searchBarView.rx.text.orEmpty.map { $0.count >= 3 }.bind(to: keywordLengthTipLabel.rx.isHidden).disposed(by: disposeBag)
        searchBarView.rx.text.orEmpty.map { $0.count < 3 }.bind(to: tableView.rx.isHidden).disposed(by: disposeBag)
        searchBarView.rx.searchButtonClicked.bind { [weak self] (_) in
            self?.searchBarView.endEditing(true)
        }.disposed(by: disposeBag)

        searchBarView.rx.text.orEmpty
            .distinctUntilChanged()
            .filter { $0.count >= 3 }
            .debounce(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
            .map { _ in () }
            .bind(to: viewModel.input.refreshTrigger)
            .disposed(by: disposeBag)

        viewModel.output.isHiddenEmptyView.drive(emptyView.rx.isHidden).disposed(by: disposeBag)
        viewModel.output.notifications.drive(tableView.rx.items(cellIdentifier: String(describing: NotificationTableViewCell.self), cellType: NotificationTableViewCell.self)) { [unowned self] (row, element, cell) in
            cell.setUp(element, keyword: self.searchBarView.text ?? "")
            cell.selectionStyle = .none
        }.disposed(by: disposeBag)

        tableView.rx.reachedBottom.bind(to: viewModel.input.loadNextPageTrigger).disposed(by: disposeBag)
        tableView.rx.modelSelected(NotificationItem.self).bind { [weak self] (data) in
            self?.performSegue(withIdentifier: NotificationDetailViewController.segueIdentifier, sender: data)
        }.disposed(by: disposeBag)
    }

    private func initSearchTitle() {
        Theme.shared.configNavigationBar(
          navigationController,
          backgroundColor: UIColor.gray303030.withAlphaComponent(0.9))
      
        let frame = CGRect(x: -10, y: 0, width: searchBarView.frame.width, height: 32)
        let titleView = UIView(frame: frame)
        searchBarView.removeMagnifyingGlass()
        searchBarView.setClearButtonColorTo(color: .white)
        searchBarView.setCursorColorTo(color: UIColor.redF20000)
        searchBarView.frame = .init(origin: .zero, size: titleView.frame.size)
        titleView.addSubview(searchBarView)
        navigationItem.titleView = titleView
        searchBarView.addDoneButton(title: "Done", target: self, selector: #selector(pressDone(_:)))
        searchBarView.searchTextField.borderStyle = .none
        searchBarView.searchTextField.backgroundColor = UIColor.black
        searchBarView.searchTextField.attributedPlaceholder = NSAttributedString(string: " \(Localize.string("common_search"))", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray9B9B9B])
    }

    @objc private func pressDone(_ sender: UIButton) {
        self.searchBarView.endEditing(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == NotificationDetailViewController.segueIdentifier,
           let dest = segue.destination as? NotificationDetailViewController,
           let notificationItem = sender as? NotificationItem {
            dest.data = notificationItem
        }
    }

    deinit {
        print("\(type(of: self)) deinit")
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

import UIKit
import SharedBu
import RxSwift

class SlotAllViewController: DisplayProduct {
    static let segueIdentifier = "toShowAllSlot"
    
    @IBOutlet weak var dropDownView: UIView!
    @IBOutlet weak var dropDownTableView: UITableView!
    @IBOutlet weak var dropDownTitleLabel: UILabel!
    @IBOutlet weak var iconArrowImageView: UIImageView!
    @IBOutlet weak var gamesCollectionView: WebGameCollectionView!
    @IBOutlet var gamesCollectionViewHeight: NSLayoutConstraint!
    
    lazy var gameDataSourceDelegate = { return ProductGameDataSourceDelegate(self) }()
    var viewModel: SlotViewModel!
    var barButtonItems: [UIBarButtonItem] = []
    var options: [SlotGameFilter] = []
    var dropDownItem: [(contentText: String, isSelected: Bool, sorting: GameSorting)] = [(Localize.string("product_hot_sorting"), true, .popular),
                                                                                         (Localize.string("product_name_sorting"), false, .gamename),
                                                                                         (Localize.string("product_release_sorting"), false, .releaseddate)]
    
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self)
        self.bind(position: .right, barButtonItems: .kto(.search), .kto(.filter))
        initUI()
        getAllGame(sorting: .popular)
    }
    
    deinit {
        print("all deinit")
    }
    
    private func initUI() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapDropDown))
        dropDownView.addGestureRecognizer(tapGesture)
        dropDownTableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .none)
        gamesCollectionView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        gamesCollectionView.registerCellFromNib(WebGameItemCell.className)
    }
    
    private func getAllGame(sorting: GameSorting, filter: [SlotGameFilter] = []) {
        viewModel.gatAllGame(sorting: sorting, filters: filter).subscribe {[weak self] (slotGames) in
            self?.reloadGameData(slotGames)
        } onError: {[weak self] (error) in
            self?.handleUnknownError(error)
        }.disposed(by: disposeBag)
    }
    
    @objc private func didTapDropDown() {
        dropDownTableView.isHidden = !dropDownTableView.isHidden
        iconArrowImageView.image = dropDownTableView.isHidden ? UIImage(named: "iconAccordionArrowUp") : UIImage(named: "iconAccordionArrowDown")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SlotFilterViewController.segueIdentifier {
            if let dest = segue.destination as? SlotFilterViewController {
                dest.options = options
                dest.conditionCallbck = {[weak self] (options) in
                    let sorting = self?.dropDownItem.first(where: { $0.isSelected }).map{ $0.sorting } ?? .popular
                    self?.getAllGame(sorting: sorting, filter: options)
                    self?.options = options
                }
            }
        }
    }
    
    // MARK: KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize" {
            if let obj = object as? UICollectionView , obj == gamesCollectionView {
                gamesCollectionViewHeight.constant = gamesCollectionView.contentSize.height
            }
        }
    }
    
    // MARK: ProductBaseCollection
    func setCollectionView() -> UICollectionView {
        return gamesCollectionView
    }
    
    func setProductGameDataSourceDelegate() -> ProductGameDataSourceDelegate {
        return gameDataSourceDelegate
    }
    
    func setViewModel() -> DisplayProductViewModel? {
        return viewModel
    }
}


extension SlotAllViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DropDownCell") as! DropDownTableViewCell
        cell.contentText.text = dropDownItem[indexPath.row].contentText
        cell.selectedImageView.isHidden = !dropDownItem[indexPath.row].isSelected
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dropDownTitleLabel.text = dropDownItem[indexPath.row].contentText
        dropDownItem[indexPath.row].isSelected = true
        dropDownTableView.isHidden = true
        iconArrowImageView.image = UIImage(named: "iconAccordionArrowUp")
        getAllGame(sorting: dropDownItem[indexPath.row].sorting, filter: options)
    }
    
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        dropDownItem[indexPath.row].isSelected = false
        dropDownTableView.reloadData()
        
        return indexPath
    }
}

extension SlotAllViewController: BarButtonItemable {
    func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
        switch sender {
        case is FilterBarButtonItem:
            performSegue(withIdentifier: SlotFilterViewController.segueIdentifier, sender: nil)
            break
        case is SearchButtonItem:
            guard let searchViewController = UIStoryboard(name: "Product", bundle: nil).instantiateViewController(withIdentifier: "SearchViewController") as? SearchViewController else { return }
            searchViewController.viewModel = self.viewModel
            self.navigationController?.pushViewController(searchViewController, animated: true)
            break
        default:
            break
        }
    }
}

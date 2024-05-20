import RxSwift
import sharedbu
import UIKit

class PromotionHistoryViewController: LobbyViewController {
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var dateView: KTODateView!
    @IBOutlet private weak var filterBtn: FilterButton!
    @IBOutlet private weak var searchTextField: UITextField!
    @IBOutlet private weak var summaryLabel: UILabel!
    @IBOutlet private weak var couponFilterStackView: UIStackView!
    @IBOutlet weak var tableView: UITableView!

    @Injected private(set) var viewModel: PromotionHistoryViewModel
    @Injected private var playerConfiguration: PlayerConfiguration
  
    private let disposeBag = DisposeBag()
  
    private var emptyStateView: EmptyStateView!

    private var currentFilter: [FilterItem]?

    var barButtonItems: [UIBarButtonItem] = []

    static func instantiate(viewModel: PromotionHistoryViewModel? = nil) -> PromotionHistoryViewController {
        let viewController = PromotionHistoryViewController.initFrom(storyboard: "PromotionHistory")

        if let viewModel {
            viewController._viewModel.wrappedValue = viewModel
        }

        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        binding()
    }
}

// MARK: - UI

extension PromotionHistoryViewController {
    private func setupUI() {
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)

        tableView.register(
            UINib(nibName: "PromotionHistoryTableViewCell", bundle: nil),
            forCellReuseIdentifier: "PromotionHistoryTableViewCell")

        let filterController = PromotionFilterViewController.initFrom(storyboard: "Filter")
        let filterPersenter = PromotionPresenter(supportLocale: playerConfiguration.supportLocale)

        filterBtn
            .set(filterPersenter)
            .setGotoFilterVC(vc: filterController)
            .set { [weak self] items in
                guard let self else { return }

                let condition = (items as? [PromotionItem])?.filter { $0.productType != ProductType.none }
                self.currentFilter = condition
                self.filterBtn.set(items)
                self.filterBtn.setPromotionStyleTitle(source: condition)

                let status = filterPersenter.getConditionStatus(condition!)
                self.viewModel.productTypes = status.prodcutTypes
                self.viewModel.privilegeTypes = status.privilegeTypes
                self.viewModel.sortingBy = status.sorting

                self.viewModel.fetchData()
            }

        dateView.callBackCondition = { [weak self] beginDate, endDate, _ in
            if
                let fromDate = beginDate,
                let toDate = endDate
            {
                self?.viewModel.beginDate = fromDate
                self?.viewModel.endDate = toDate
                self?.viewModel.fetchData()
            }
        }

        setupSearchField()
        initEmptyStateView()
    }
  
    private func initEmptyStateView() {
        emptyStateView = EmptyStateView(
            icon: UIImage(named: "No Records")!,
            description: Localize.string("common_no_record_temporarily"),
            keyboardAppearance: .possible)
    
        view.addSubview(emptyStateView)

        emptyStateView.snp.makeConstraints { make in
            make.top.equalTo(couponFilterStackView.snp.bottom)
            make.bottom.leading.trailing.equalToSuperview()
        }
    }

    private func binding() {
        searchTextField.rx.text
            .orEmpty
            .bind(to: viewModel.keywordRelay)
            .disposed(by: disposeBag)

        searchTextField.rx.text
            .orEmpty
            .map { !$0.isEmpty }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] in
                self?.searchTextField.rightViewMode = $0 ? .always : .never
            })
            .disposed(by: disposeBag)

        searchTextField.rightView?.rx
            .tapGesture()
            .subscribe(onNext: { [weak self] _ in
                self?.searchTextField.text = ""
                self?.searchTextField.resignFirstResponder()
            })
            .disposed(by: disposeBag)

        viewModel.totalCountAmountDriver
            .asObservable()
            .bind(to: summaryLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.historiesDriver
            .asObservable()
            .bind(to: tableView.rx.items) { [weak self] _, _, element in
                guard let self else { return .init() }

                let cell = self.tableView.dequeueReusableCell(
                    withIdentifier: "PromotionHistoryTableViewCell",
                    cellType: PromotionHistoryTableViewCell.self)

                cell.config(element, tableView: self.tableView)

                return cell
            }
            .disposed(by: disposeBag)

        viewModel.historiesDriver
            .drive(onNext: { [weak self] element in
                self?.tableView.isHidden = element.isEmpty
                self?.emptyStateView.isHidden = !element.isEmpty
            })
            .disposed(by: disposeBag)

        viewModel.errors()
            .subscribe(onNext: { [weak self] error in
                self?.handleErrors(error)
            })
            .disposed(by: disposeBag)

        scrollView.rx.reachedBottom
            .subscribe(onNext: { [weak self] in
                self?.viewModel.fetchNextPage()
            })
            .disposed(by: disposeBag)
    }

    private func setupSearchField() {
        searchTextField.cornerRadius = 8
        searchTextField.bordersColor = .textPrimary
        searchTextField.borderWidth = 0.5

        let search = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 48))
        let searchImage = UIImageView(
            image: .init(named: "Search")?.withRenderingMode(.alwaysTemplate))

        search.addSubview(searchImage)
        searchImage.tintColor = .textPrimary
        searchImage.frame = .init(origin: .init(x: 15, y: 15), size: .init(width: 18, height: 18))

        searchTextField.leftView = search
        searchTextField.leftViewMode = .always

        let close = UIView(frame: .init(origin: .zero, size: .init(width: 48, height: 48)))
        let closeImage = UIImageView(image: .init(named: "icon.close.fill"))

        close.addSubview(closeImage)
        closeImage.frame.size = .init(width: 20, height: 20)
        closeImage.center = close.center
        closeImage.isUserInteractionEnabled = false

        searchTextField.rightView = close
        searchTextField.rightViewMode = .never

        searchTextField.font = .init(name: "PingFangSC-Medium", size: 14)
        searchTextField.textColor = .greyScaleWhite
        searchTextField.attributedPlaceholder = Localize.string("common_search")
            .attributed
            .textColor(.textSecondary)
            .font(
                weight: .medium,
                locale: viewModel.getSupportLocale(),
                size: 14)
    }
}

final class ContentSizedTableView: UITableView {
    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}

import AlignedCollectionViewFlowLayout
import RxCocoa
import RxDataSources
import RxSwift
import sharedbu
import SnapKit
import UIKit

typealias FilterSectionModel = SectionModel<String, SlotFilterViewController.Category.Item>

class SlotFilterViewController: UIViewController {
    static let segueIdentifier = "toSlotFilter"
    let headerIdentifier = "Header"
    let footerIdentifier = "Footer"

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var selectedCountLabel: UILabel!

    private let playerConfiguration = Injectable.resolve(PlayerConfiguration.self)!

    private var collectionViewHeight: SnapKit.Constraint?
    private var viewModel = Injectable.resolve(SlotViewModel.self)!
    private var disposeBag = DisposeBag()

    var barButtonItems: [UIBarButtonItem] = []
    var options: [SlotGameFilter] = []
    var conditionCallback: ((_ dateType: [SlotGameFilter]) -> Void)?

    lazy var locale = playerConfiguration.supportLocale
    lazy var items = Category(options: options)
    var dataSource: RxCollectionViewSectionedReloadDataSource<FilterSectionModel>?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        initDataSource()
        bindData()
    }

    @IBAction
    func pressDone(_: UIButton) {
        conditionCallback?(options)
        self.dismiss(animated: true, completion: nil)
    }
}

extension SlotFilterViewController {
    func setupUI() {
        self.bind(position: .left, barButtonItems: .kto(.close))
        self.bind(position: .right, barButtonItems: .kto(.text(text: Localize.string("product_clear_filters"))))

        let flowLayout = AlignedCollectionViewFlowLayout(horizontalAlignment: .left, verticalAlignment: .top)
        flowLayout.sectionInset = UIEdgeInsets(top: 16, left: 8, bottom: 24, right: 0)
        flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        flowLayout.minimumInteritemSpacing = 10
        flowLayout.minimumLineSpacing = 16
        collectionView.collectionViewLayout = flowLayout

        collectionView.registerCellFromNib(SlotFilterItemCell.className)
        collectionView.register(
            SlotFilterHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: headerIdentifier)
        collectionView.register(
            SlotFilterFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: footerIdentifier)

        collectionView.snp.makeConstraints { make in
            collectionViewHeight = make.height.equalTo(100).priority(.high).constraint
        }
    }

    func initDataSource() {
        let dataSource = RxCollectionViewSectionedReloadDataSource<FilterSectionModel>(
            configureCell: { _, collectionView, indexPath, element in
                collectionView
                    .dequeueReusableCell(cellType: SlotFilterItemCell.self, indexPath: indexPath)
                    .setup(title: element.name, isSelected: element.isSelect)
            },
            configureSupplementaryView: { [unowned self] _, collectionView, kind, indexPath -> UICollectionReusableView in
                if
                    kind == UICollectionView.elementKindSectionHeader,
                    let headerView = collectionView
                        .dequeueReusableSupplementaryView(
                            ofKind: kind,
                            withReuseIdentifier: headerIdentifier,
                            for: indexPath) as? SlotFilterHeaderView
                {
                    let title = items.sectionText[indexPath.section]
                    /// Fixed an issue where the iPhone SE screen shakes when selecting a filter for the first time when the VN is
                    /// used
                    headerView.label.attributedText = title
                        .attributed
                        .font(
                            weight: .regular,
                            locale: locale,
                            size: 16)

                    return headerView
                }
                else if
                    kind == UICollectionView.elementKindSectionFooter,
                    let footer = collectionView
                        .dequeueReusableSupplementaryView(
                            ofKind: kind,
                            withReuseIdentifier: footerIdentifier,
                            for: indexPath) as? SlotFilterFooterView
                {
                    if indexPath.section == collectionView.numberOfSections - 1 {
                        footer.line.backgroundColor = .clear
                    }
                    return footer
                }

                return UICollectionReusableView()
            })

        self.dataSource = dataSource

        viewModel.slotFilter
            .map { Category(options: $0) }
            .do(onNext: { [unowned self] in
                self.items = $0
            })
            .map {
                var sectionModels: [FilterSectionModel] = []
                sectionModels.append(SectionModel(model: $0.sectionText[0], items: $0.feature))
                sectionModels.append(SectionModel(model: $0.sectionText[1], items: $0.theme))
                sectionModels.append(SectionModel(model: $0.sectionText[2], items: $0.payLineWay))
                return sectionModels
            }
            .bind(to: collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }

    func bindData() {
        viewModel.setOptions(filter: options)

        viewModel.gameCountWithSearchFilters
            .subscribe(onNext: { [weak self] count, filters in
                if filters.count == 0 {
                    self?.selectedCountLabel.text = Localize.string("product_all_games_selected")
                }
                else {
                    self?.selectedCountLabel.text = String(format: Localize.string("product_count_selected_games"), "\(count)")
                }
            }).disposed(by: disposeBag)

        collectionView.rx.observe(\.contentSize)
            .subscribe(onNext: { [weak self] in
                self?.collectionViewHeight?.update(offset: $0.height)
            })
            .disposed(by: disposeBag)

        collectionView.rx.modelSelected(SlotFilterViewController.Category.Item.self)
            .bind(onNext: { [unowned self] in
                $0.isSelect = !$0.isSelect
                setOptions($0)
            })
            .disposed(by: disposeBag)

        collectionView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
    }

    private func setOptions(_ item: SlotFilterViewController.Category.Item) {
        if
            item.isSelect,
            let option = SlotGameFilter.Companion().allFilters
                .first(where: { $0.isKind(of: item.type) && $0.getDecimalValue() == Double(item.tag) })
        {
            options.append(option)
        }
        else {
            options.removeAll { filter -> Bool in
                filter.isKind(of: item.type) && filter.getDecimalValue() == Double(item.tag)
            }
        }

        viewModel.setOptions(filter: options)
    }

    private func selfSizeSection(collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> CGSize {
        guard let dataSource else { return .zero }
        let sectionView = dataSource.collectionView(
            collectionView,
            viewForSupplementaryElementOfKind: kind,
            at: indexPath)

        return sectionView.systemLayoutSizeFitting(
            CGSize(width: collectionView.frame.width, height: UIView.layoutFittingExpandedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel)
    }
}

extension SlotFilterViewController {
    class Category {
        private let features = [
            Localize.string("product_slot_separate"),
            Localize.string("product_slot_wild"),
            Localize.string("product_slot_feature"),
            Localize.string("product_slot_freespin"),
            Localize.string("product_slot_bidirectional_win")
        ]
        private let themes = [
            Localize.string("product_slot_asia"),
            Localize.string("product_slot_west")
        ]
        private let payLineWays = [
            Localize.string("product_slot_below_15"),
            Localize.string("product_slot_from_15to30"),
            Localize.string("product_slot_above_30"),
            Localize.string("product_slot_all"),
            Localize.string("product_slot_others")
        ]

        let sectionText = [
            Localize.string("product_slot_game_feature"),
            Localize.string("product_slot_game_theme"),
            Localize.string("product_slot_game_payline")
        ]

        var feature: [Item] = []
        var theme: [Item] = []
        var payLineWay: [Item] = []

        init(options: [SlotGameFilter]) {
            generateItems(from: &feature, texts: features, options: options, type: SlotGameFilter.SlotGameFeature.self)
            generateItems(from: &theme, texts: themes, options: options, type: SlotGameFilter.SlotGameTheme.self)
            generateItems(from: &payLineWay, texts: payLineWays, options: options, type: SlotGameFilter.SlotPayLineWay.self)
        }

        func clear() {
            feature.forEach { $0.isSelect = false }
            theme.forEach { $0.isSelect = false }
            payLineWay.forEach { $0.isSelect = false }
        }

        private func generateItems(
            from items: inout [Item],
            texts: [String],
            options: [SlotGameFilter],
            type: SlotGameFilter.Type)
        {
            var previousIndex = 0
            for (index, text) in texts.enumerated() {
                if index == 0 {
                    previousIndex = 1
                }
                else {
                    previousIndex = previousIndex * 2
                }
                let isSelect = options.contains(where: {
                    $0.isKind(of: type) && $0.getDecimalValue() == Double(previousIndex)
                })
                items.append(Item(isSelect: isSelect, name: text, tag: previousIndex, type: type))
            }
        }

        class Item {
            var isSelect: Bool
            var name: String
            var tag: Int
            var type: SlotGameFilter.Type

            init(isSelect: Bool, name: String, tag: Int, type: SlotGameFilter.Type) {
                self.isSelect = isSelect
                self.name = name
                self.tag = tag
                self.type = type
            }
        }
    }

    class SlotFilterHeaderView: UICollectionReusableView {
        let label: UILabel = .init()

        override init(frame: CGRect) {
            super.init(frame: frame)
            label.textAlignment = .left
            label.textColor = UIColor.textPrimary

            self.addSubview(label)
            label.snp.makeConstraints { make in
                make.edges.equalTo(self).inset(UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0))
            }
        }

        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class SlotFilterFooterView: UICollectionReusableView {
        let line: UIView = .init()

        override init(frame: CGRect) {
            super.init(frame: frame)
            line.backgroundColor = .greyScaleDivider

            self.addSubview(line)
            line.snp.makeConstraints { make in
                make.height.equalTo(1)
                make.edges.equalTo(self).inset(UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0))
            }
        }

        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension SlotFilterViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout _: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int)
        -> CGSize
    {
        selfSizeSection(
            collectionView: collectionView,
            kind: UICollectionView.elementKindSectionHeader,
            indexPath: IndexPath(row: 0, section: section))
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout _: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int)
        -> CGSize
    {
        selfSizeSection(
            collectionView: collectionView,
            kind: UICollectionView.elementKindSectionFooter,
            indexPath: IndexPath(row: 0, section: section))
    }
}

extension SlotFilterViewController: BarButtonItemable {
    func pressedRightBarButtonItems(_: UIBarButtonItem) {
        items.clear()
        options = []
        viewModel.setOptions(filter: options)
    }

    func pressedLeftBarButtonItems(_: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
        self.presentationController?.delegate?.presentationControllerDidDismiss?(self.presentationController!)
    }
}

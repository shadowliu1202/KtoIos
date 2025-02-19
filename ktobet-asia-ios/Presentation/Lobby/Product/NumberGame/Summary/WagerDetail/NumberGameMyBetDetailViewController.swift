import RxCocoa
import RxSwift
import sharedbu
import UIKit

class NumberGameMyBetDetailViewController: LobbyViewController {
  static let segueIdentifier = "toNumberGameMyBetDetail"

  @IBOutlet weak var pagecontol: KTOPageControl!
  
  @Injected private var playerConfiguration: PlayerConfiguration
  
  var containerPageViewController: NumberGameMyBetPageViewController?

  var details: [NumberGameBetDetail]? {
    didSet {
      totalCount = details?.count ?? 0
    }
  }

  var isViewPager = true
  var selectedIndex = 0
  private var displayPage = 1
  private var totalCount = 1 {
    didSet {
      if totalCount == 0 { displayPage = 0 }
      self.refreshPage()
    }
  }

  private var hasNext = BehaviorRelay<Bool>(value: true)
  private var hasPrevious = BehaviorRelay<Bool>(value: false)
  private var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(
      vc: self,
      barItemType: .back,
      title: Localize.string("balancelog_wager_detail"))
    initUI()
    dataBinding()
  }

  private func initUI() {
    pagecontol.pageLabel.text = "\(displayPage)/\(totalCount)"
    pagecontol.isHidden = !isViewPager
  }

  private func dataBinding() {
    hasPrevious.bind(to: pagecontol.leftBtn.rx.isEnabled).disposed(by: disposeBag)
    hasNext.bind(to: pagecontol.rightBtn.rx.isEnabled).disposed(by: disposeBag)
    pagecontol.leftBtn.rx.touchUpInside.bind(onNext: { [weak self] _ in
      self?.containerPageViewController?.turnReversePage()
    }).disposed(by: disposeBag)
    pagecontol.rightBtn.rx.touchUpInside.bind(onNext: { [weak self] _ in
      self?.containerPageViewController?.turnForwardPage()
    }).disposed(by: disposeBag)
  }

  private func refreshPage() {
    hasNext.accept(displayPage < totalCount ? true : false)
    hasPrevious.accept(displayPage > 1 ? true : false)
    if pagecontol != nil {
      pagecontol.pageLabel.text = "\(displayPage)/\(totalCount)"
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
    if let pageViewController = segue.destination as? NumberGameMyBetPageViewController {
      self.containerPageViewController = pageViewController
      pageViewController.pageDelegate = self
      pageViewController.supportLocale = playerConfiguration.supportLocale
      pageViewController.initialPageIndex = self.selectedIndex
    }
  }
}

extension NumberGameMyBetDetailViewController: NumberGameMyBetPageViewDelegate {
  func updatePage(_ pageIndex: Int) {
    displayPage = pageIndex + 1
    refreshPage()
  }

  func getData() -> [NumberGameBetDetail]? {
    details
  }
}

class KTOPageControl: UIView {
  @IBOutlet weak var pageLabel: UILabel!
  @IBOutlet weak var leftBtn: UIButton!
  @IBOutlet weak var rightBtn: UIButton!
}

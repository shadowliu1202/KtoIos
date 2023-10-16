import sharedbu
import UIKit

protocol NumberGameMyBetPageViewDelegate: AnyObject {
  func updatePage(_ pageIndex: Int)
  func getData() -> [NumberGameBetDetail]?
}

class NumberGameMyBetPageViewController: UIPageViewController {
  lazy var data = pageDelegate?.getData()
  var initialPageIndex = 0 {
    didSet {
      self.page = initialPageIndex
    }
  }

  private(set) var page = 0 {
    didSet {
      pageDelegate?.updatePage(page)
    }
  }

  private lazy var maxPage = { () -> Int in
    if let d = self.data, d.count > 0 {
      return d.count - 1
    }
    return 0
  }()

  weak var pageDelegate: NumberGameMyBetPageViewDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()

    self.delegate = self
    self.dataSource = self
    if let detailVC = setupBetDetailViewController(initialPageIndex) {
      self.setViewControllers([detailVC], direction: .forward, animated: false, completion: nil)
    }
  }

  func turnForwardPage() {
    setBetDetailViewController(page + 1)
  }

  func turnReversePage() {
    setBetDetailViewController(page - 1)
  }

  private func setBetDetailViewController(_ page: Int) {
    guard let detailVC = setupBetDetailViewController(page) else { return }
    let direction: UIPageViewController.NavigationDirection = page > self.page ? .forward : .reverse
    self.page = page
    self.setViewControllers([detailVC], direction: direction, animated: false, completion: nil)
  }

  private func setupBetDetailViewController(_ page: Int) -> UIViewController? {
    if page < 0 || page > maxPage { return nil }
    let storyboard = UIStoryboard(name: "NumberGame", bundle: Bundle.main)
    guard
      let detailVC = storyboard
        .instantiateViewController(withIdentifier: "RecentDetailViewController") as? RecentDetailViewController
    else {
      return nil
    }
    detailVC.page = page
    if let data = pageDelegate?.getData() {
      detailVC.detailItem = data[page]
    }
    return detailVC
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

extension NumberGameMyBetPageViewController: UIPageViewControllerDataSource {
  func pageViewController(_: UIPageViewController, viewControllerBefore _: UIViewController) -> UIViewController? {
    setupBetDetailViewController(page - 1)
  }

  func pageViewController(_: UIPageViewController, viewControllerAfter _: UIViewController) -> UIViewController? {
    setupBetDetailViewController(page + 1)
  }
}

extension NumberGameMyBetPageViewController: UIPageViewControllerDelegate {
  func pageViewController(
    _: UIPageViewController,
    didFinishAnimating finished: Bool,
    previousViewControllers _: [UIViewController],
    transitionCompleted _: Bool)
  {
    if finished {
      guard let detailVC = viewControllers?.first as? RecentDetailViewController, let page = detailVC.page else { return }
      self.page = page
    }
  }
}

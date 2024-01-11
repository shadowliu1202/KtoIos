import sharedbu
import SwiftUI
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

  var supportLocale: SupportLocale!
  weak var pageDelegate: NumberGameMyBetPageViewDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()

    self.delegate = self
    self.dataSource = self
    if let detailVC = setupBetDetailContent(initialPageIndex) {
      self.setViewControllers([detailVC], direction: .forward, animated: false, completion: nil)
    }
  }

  func turnForwardPage() {
    setBetDetailContent(page + 1)
  }

  func turnReversePage() {
    setBetDetailContent(page - 1)
  }

  private func setBetDetailContent(_ page: Int) {
    guard let detailVC = setupBetDetailContent(page) else { return }
    let direction: UIPageViewController.NavigationDirection = page > self.page ? .forward : .reverse
    self.page = page
    self.setViewControllers([detailVC], direction: direction, animated: false, completion: nil)
  }

  private func setupBetDetailContent(_ page: Int) -> UIViewController? {
    guard
      page >= 0, page <= maxPage,
      let myBetDetails = pageDelegate?.getData()
    else { return nil }
    
    let contentVC = UIHostingController(
      rootView:
      NumberGameMyBetDetailContent(
        myBetDetail: myBetDetails[page],
        page: page,
        supportLocale: supportLocale))
    
    contentVC.view.backgroundColor = .greyScaleDefault
    
    return contentVC
  }
}

extension NumberGameMyBetPageViewController: UIPageViewControllerDataSource {
  func pageViewController(_: UIPageViewController, viewControllerBefore _: UIViewController) -> UIViewController? {
    setupBetDetailContent(page - 1)
  }

  func pageViewController(_: UIPageViewController, viewControllerAfter _: UIViewController) -> UIViewController? {
    setupBetDetailContent(page + 1)
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
      guard let detailContentVC = viewControllers?.first as? UIHostingController<NumberGameMyBetDetailContent> else { return }
      self.page = detailContentVC.rootView.page
    }
  }
}

import Foundation
import RxSwift
import UIKit

class P2PBetDetailViewController: LobbyViewController {
  private let viewModel: P2PBetDetailViewModel
  private let wagerID: String
  private let disposeBag = DisposeBag()
    
  init(
    viewModel: P2PBetDetailViewModel = .init(),
    wagerID: String)
  {
    self.viewModel = viewModel
    self.wagerID = wagerID
      
    super.init(nibName: nil, bundle: nil)
    Logger.shared.info("\(type(of: self)) init")
  }
    
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
    
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    bindErrorHandle()
  }
    
  private func setupUI() {
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
    
    addSubView(P2PBetDetailView(viewModel: viewModel, wagerID: wagerID), to: view)
  }
  
  private func bindErrorHandle() {
    viewModel.errorsSubject
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [unowned self] it in handleErrors(it) })
      .disposed(by: disposeBag)
  }
}

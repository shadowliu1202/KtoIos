import Combine
import Foundation
import UIKit

class CasinoBetDetailViewController: LobbyViewController {
  private let viewModel: CasinoBetDetailViewModel
  private let wagerID: String
  
  private var cancellables = Set<AnyCancellable>()
    
  init(
    viewModel: CasinoBetDetailViewModel = .init(),
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
    
    addSubView(CasinoBetDetailView(viewModel: viewModel, wagerID: wagerID), to: view)
  }
  
  private func bindErrorHandle() {
    viewModel.errorsSubject
      .receive(on: DispatchQueue.main)
      .sink(receiveValue: { [unowned self] it in handleErrors(it) })
      .store(in: &cancellables)
  }
}

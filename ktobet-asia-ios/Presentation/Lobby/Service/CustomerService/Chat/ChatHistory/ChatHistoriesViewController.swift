import Combine
import SwiftUI
import UIKit

class ChatHistoriesViewController: LobbyViewController {
    @Injected private var viewModel: ChatHistoriesViewModel
    @Injected private var httpClient: HttpClient
  
    private var cancellables = Set<AnyCancellable>()
  
    private let roomId: String

    init(roomId: String) {
        self.roomId = roomId
        super.init(nibName: nil, bundle: nil)
    }
  
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        binding()
    }
  
    private func setupUI() {
        view.backgroundColor = .greyScaleChatWindow
    
        NavigationManagement.sharedInstance.addBarButtonItem(
            vc: self,
            barItemType: .back,
            leftItemTitle: Localize.string("customerservice_history_title"))
    
        addSubView(from: { [unowned self] in
            ChatHistoriesView(
                viewModel: viewModel,
                roomId: roomId,
                onTapImage: { [unowned self] path in
                    let urlString = httpClient.host.absoluteString + path
                    toImageVC(url: urlString)
                })
                .environment(\.playerLocale, viewModel.getSupportLocale())
        }, to: view)
    }

    private func binding() {
        viewModel.errors()
            .sink(receiveValue: { [unowned self] in handleErrors($0) })
            .store(in: &cancellables)
    }
  
    private func toImageVC(url: String) {
        let imageVC = ImageViewController.instantiate(url: url)
        navigationController?.pushViewController(imageVC, animated: true)
    }
}

import Combine
import SwiftUI
import UIKit

class ChatHistoriesEditViewController: LobbyViewController {
    @Injected private var viewModel: ChatHistoriesEditViewModel
  
    private var activityIndicator = UIActivityIndicatorView(style: .large)
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        binding()
    }
  
    private func setupUI() {
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
    
        addSubView(from: { [unowned self] in
            ChatHistoriesEditView(
                viewModel: viewModel,
                onSelectedRow: { [unowned self] item in
                    viewModel.updateSelection(item)
                },
                onTapDelete: { [unowned self] in
                    popAndShowToast()
                })
                .environment(\.playerLocale, viewModel.getSupportLocale())
        }, to: view)
    }
  
    private func binding() {
        fetchData()
    
        viewModel.errors()
            .sink(receiveValue: { [unowned self] in
                activityIndicator.stopAnimating()
                handleErrors($0)
            })
            .store(in: &cancellables)
    }

    private func fetchData() {
        self.activityIndicator.startAnimating()
        viewModel.getChatHistory(1)
    }

    private func popAndShowToast() {
        NavigationManagement.sharedInstance.popViewController({
            @Injected var snackBar: SnackBar
            snackBar.show(tip: Localize.string("customerservice_chat_deleted"), image: UIImage(named: "Success"))
        })
    }
}

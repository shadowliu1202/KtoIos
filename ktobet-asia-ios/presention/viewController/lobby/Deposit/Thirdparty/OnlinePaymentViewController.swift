import UIKit
import SwiftUI
import SharedBu
import RxSwift

class OnlinePaymentViewController: LobbyViewController {

    var alert: AlertProtocol = Injectable.resolve(AlertProtocol.self)!
    
    private let onlineDepositViewModel: OnlineDepositViewModel
    private let httpClient = Injectable.resolve(HttpClient.self)!
    private let disposeBag = DisposeBag()
    
    static func instantiate(
      selectedOnlinePayment: PaymentsDTO.Online,
      viewModel: OnlineDepositViewModel? = nil)
    -> OnlinePaymentViewController {
        let vc = OnlinePaymentViewController.initFrom(storyboard: "Deposit", creator: {
          OnlinePaymentViewController.init(
            coder: $0,
            selectedOnlinePayment: selectedOnlinePayment,
            viewModel: viewModel)
        })
        
        return vc
    }
    
    required init?(
      coder: NSCoder,
      selectedOnlinePayment: PaymentsDTO.Online,
      viewModel: OnlineDepositViewModel? = nil) {
        self.onlineDepositViewModel = viewModel ?? .init(selectedOnlinePayment: selectedOnlinePayment)
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, action: #selector(back))
        onlineDepositViewModel.errors()
            .subscribe { [unowned self] error in
                self.handleErrors(error)
            }
            .disposed(by: disposeBag)
    }
    
    @IBSegueAction func toOnlinePayment(_ coder: NSCoder) -> UIViewController? {
        return UIHostingController(coder: coder, rootView: OnlinePaymentView(viewModel: self.onlineDepositViewModel, userGuideOnTap: {
            NavigationManagement.sharedInstance.viewController.performSegue(withIdentifier: JinYiDigitalViewController.segueIdentifier, sender: nil)
        }, remitButtonOnSuccess: { [unowned self] webPath in
            let host = self.httpClient.host.absoluteString
            let url = host + webPath.path + "&backUrl=\(host)"
            self.toOnlineWebPage(url: url)
        }))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == DepositThirdPartWebViewController.segueIdentifier {
            if let dest = segue.destination as? DepositThirdPartWebViewController {
                dest.url = sender as? String
            }
        }
    }
    
    private func toOnlineWebPage(url: String) {
        let title = Localize.string("common_kindly_remind")
        let message = Localize.string("deposit_thirdparty_transaction_remind")
        Alert.shared.show(title, message, confirm: {
            NavigationManagement.sharedInstance.viewController.performSegue(withIdentifier: DepositThirdPartWebViewController.segueIdentifier, sender: url)
        }, cancel: nil)
    }
    
    @objc func back() {
        Alert.shared.show(Localize.string("common_confirm_cancel_operation"), Localize.string("deposit_online_terminate"), confirm: { 
            NavigationManagement.sharedInstance.popViewController()
        }, cancel: { })
    }
    
    override func handleErrors(_ error: Error) {
        if error is PlayerDepositCountOverLimit {
            self.notifyTryLaterAndPopBack()
        } else {
            super.handleErrors(error)
        }
    }
    
    private func notifyTryLaterAndPopBack() {
        alert.show(nil, Localize.string("deposit_notify_request_later"), confirm: {
            NavigationManagement.sharedInstance.popViewController()
        }, cancel: nil)
    }
}

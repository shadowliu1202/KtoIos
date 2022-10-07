import UIKit
import SwiftUI
import SharedBu
import RxSwift

class OnlinePaymentViewController: LobbyViewController {
    static let segueIdentifier = "toOnlinePaymentSegue"
    
    var selectedOnlinePayment: PaymentsDTO.Online!
    
    private lazy var onlineDepositViewModel = OnlineDepositViewModel(selectedOnlinePayment: selectedOnlinePayment)
    
    private let httpClient = DI.resolve(HttpClient.self)!
    private let disposeBag = DisposeBag()
    
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
        Alert.show(title, message, confirm: {
            NavigationManagement.sharedInstance.viewController.performSegue(withIdentifier: DepositThirdPartWebViewController.segueIdentifier, sender: url)
        }, cancel: nil)
    }
    
    @objc func back() {
        Alert.show(Localize.string("common_confirm_cancel_operation"), Localize.string("deposit_online_terminate"), confirm: { 
            NavigationManagement.sharedInstance.popViewController()
        }, cancel: { })
    }
}

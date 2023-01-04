import UIKit
import SwiftUI
import RxSwift
import SharedBu
import Moya

class DepositViewController: LobbyViewController,
                             SwiftUIConverter {
    
    @Injected private var playerConfig: PlayerConfiguration
    @Injected private var viewModel: DepositViewModel
    
    private let disposeBag = DisposeBag()
    
    init?(coder: NSCoder, viewModel: DepositViewModel, playerConfig: PlayerConfiguration) {
        super.init(coder: coder)
        self.viewModel = viewModel
        self.playerConfig = playerConfig
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        binding()
    }
    
    deinit {
        Injectable.resetObjectScope(.depositFlow)
        print("\(type(of: self)) deinit")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case DepositGatewayViewController.segueIdentifier:
            if let dest = segue.destination as? DepositGatewayViewController {
                let depositType = sender as? DepositSelection
                dest.depositType = depositType
                dest.paymentIdentity = depositType?.id
            }
            
        case DepositCryptoViewController.segueIdentifier:
            if let dest = segue.destination as? DepositCryptoViewController {
                dest.url = sender as? String
            }
            
        case StarMergerViewController.segueIdentifier:
            if let dest = segue.destination as? StarMergerViewController {
                dest.paymentGatewayID = (sender as? String)!
            }
            
        case OnlinePaymentViewController.segueIdentifier:
            if let dest = segue.destination as? OnlinePaymentViewController {
                dest.selectedOnlinePayment = (sender as? OnlinePayment)!.paymentDTO
            }
            
        default:
            break
        }
    }
}


// MARK: - UI

private extension DepositViewController {
    
    func setupUI() {
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(
            vc: self,
            title: Localize.string("common_deposit")
        )
                
        addSubView(
            from: { [unowned self] in
                DepositView(
                    playerConfig: self.playerConfig,
                    viewModel: self.viewModel,
                    onMethodSelected: {
                        self.pushToMethodPage($0)
                    },
                    onHistorySelected: {
                        self.pushToRecordPage($0)
                    },
                    onDisplayAll: {
                        self.pushToAllRecordPage()
                    }
                )
            },
            to: view
        )
    }
    
    func binding() {
        viewModel.errors()
            .subscribe(onNext: { [weak self] in
                self?.handleErrors($0)
            })
            .disposed(by: disposeBag)
    }
    
    func presentCryptoDepositWarnings() {
        Alert.shared
            .show(
                Localize.string("common_tip_title_warm"),
                Localize.string("deposit_crypto_warning"),
                confirm: { [weak self] in
                    self?.performSegue(withIdentifier: CryptoSelectorViewController.segueIdentifier, sender: nil)
                },
                cancel: nil
            )
    }
}

// MARK: - Navigation

extension DepositViewController {
    
    func pushToMethodPage(_ selection: DepositSelection) {
        switch selection.type {
        case .OfflinePayment:
            navigationController?.pushViewController(OfflinePaymentViewController(), animated: true)
        case .Crypto:
            self.presentCryptoDepositWarnings()
        case .CryptoMarket:
            self.performSegue(withIdentifier: StarMergerViewController.segueIdentifier, sender: selection.id)
        case .JinYiDigital:
            self.performSegue(withIdentifier: OnlinePaymentViewController.segueIdentifier, sender: selection)
        default:
            self.performSegue(withIdentifier: DepositGatewayViewController.segueIdentifier, sender: selection)
        }
    }
    
    func pushToRecordPage(_ log: PaymentLogDTO.Log) {
        let container = DepositRecordContainer.initFrom(storyboard: "Deposit")
        
        container.displayId = log.displayId
        container.paymentCurrencyType = log.currencyType
        
        navigationController?.pushViewController(container, animated: true)
    }
    
    func pushToAllRecordPage() {
        performSegue(withIdentifier: DepositRecordViewController.segueIdentifier, sender: nil)
    }
    
    @IBAction func backToDeposit(segue: UIStoryboardSegue) {
        NavigationManagement.sharedInstance.viewController = self
        
        let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48))
        
        switch segue.source {
        case is _DepositOfflineConfirmViewController:
            let confirm = segue.source as! _DepositOfflineConfirmViewController
            
            if confirm.confirmSuccess {
                toastView.show(
                    on: self.view,
                    statusTip: Localize.string("deposit_offline_step3_title"),
                    img: UIImage(named: "Success")
                )
            }
            
        case is DepositThirdPartWebViewController:
            toastView.show(
                on: self.view,
                statusTip: Localize.string("common_request_submitted"),
                img: UIImage(named: "Success")
            )
        
        default:
            break
        }
    }
}

import UIKit
import RxSwift

enum TermsRow: Int {
    case privacy, service, gamblingResponsibility, aboutKto, legalSupervision
}

class TermsViewController: APPViewController, TermsTableDelegate {
    private static let embedSegue = "embedSegue"
    static let segueIdentifier = "toTerms"
    
    private var tableContainer: TermsTableViewController?
    private var viewModel = DI.resolve(TermsViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        viewModel.yearOfCopyRight.subscribe(onSuccess: { [weak self] in
            self?.tableContainer?.copyrightLabel.text = Localize.string("common_copyright", "\($0)")
        }, onError: { [weak self] in
            self?.handleErrors($0)
        }).disposed(by: disposeBag)
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == TermsViewController.embedSegue, let tableVC = segue.destination as? TermsTableViewController {
            self.tableContainer = tableVC
            tableVC.delegate = self
        }
    }
    
    func tableView(didSelectRowAt indexPath: IndexPath) {
        if let row = TermsRow.init(rawValue: indexPath.row) {
            switch row {
            case .privacy:
                navigateToPrivacyTerm()
            case .service:
                navigateToServiceTerms()
            case .gamblingResponsibility:
                navigateToGamblingResponsibility()
            case .aboutKto:
                navigateToAboutKTO()
            case .legalSupervision:
                navigateToLegalSupervision()
                break
            }
        }
    }
    
    private func navigateToPrivacyTerm() {
        navigateToTermsOfService(presnter: SecurityPrivacyTerms())
    }
    
    private func navigateToServiceTerms() {
        navigateToTermsOfService(presnter: ServiceTerms(barItemType: .back))
    }
    
    private func navigateToGamblingResponsibility() {
        navigateToTermsOfService(presnter: GameblingResponsibility())
    }
    
    private func navigateToAboutKTO() {
        self.performSegue(withIdentifier: AboutKTOViewController.segueIdentifier, sender: nil)
    }
    
    private func navigateToLegalSupervision() {
        self.performSegue(withIdentifier: LegalSupervisionViewController.segueIdentifier, sender: nil)
    }
    
    private func navigateToTermsOfService(presnter: TermsPresenter) {
        if let termsOfServiceViewController = UIStoryboard(name: "Signup", bundle: nil).instantiateViewController(withIdentifier: "TermsOfServiceViewController") as? TermsOfServiceViewController {
            termsOfServiceViewController.termsPresenter = presnter
            self.navigationController?.pushViewController(termsOfServiceViewController, animated: true)
        }
    }
}

protocol TermsTableDelegate: AnyObject {
    func tableView(didSelectRowAt indexPath: IndexPath)
}

class TermsTableViewController: UITableViewController {
    weak var delegate: TermsTableDelegate?
    @IBOutlet weak var copyrightLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorColor = .clear
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.tableView(didSelectRowAt: indexPath)
    }
}

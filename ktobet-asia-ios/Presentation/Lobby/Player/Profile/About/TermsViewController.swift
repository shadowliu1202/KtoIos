import RxSwift
import UIKit

enum TermsRow: Int {
    case privacy
    case service
    case gamblingResponsibility
    case aboutKto
    case legalSupervision
}

class TermsViewController: LobbyViewController, TermsTableDelegate {
    private static let embedSegue = "embedSegue"
    static let segueIdentifier = "toTerms"

    private var tableContainer: TermsTableViewController?
    private var viewModel = Injectable.resolve(TermsViewModel.self)!
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)

        viewModel.yearOfCopyRight
            .subscribe(onSuccess: { [weak self] in
                self?.tableContainer?.copyrightLabel.text = Localize.string("common_copyright", "\($0)")
            }, onFailure: { [weak self] in
                self?.handleErrors($0)
            })
            .disposed(by: disposeBag)
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == TermsViewController.embedSegue, let tableVC = segue.destination as? TermsTableViewController {
            self.tableContainer = tableVC
            tableVC.delegate = self
        }
    }

    func tableView(didSelectRowAt indexPath: IndexPath) {
        if let row = TermsRow(rawValue: indexPath.row) {
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
            }
        }
    }

    private func navigateToPrivacyTerm() {
        navigationController?.pushViewController(
            TermsOfServiceViewController.instantiate(SecurityPrivacyTerms()),
            animated: true)
    }

    private func navigateToServiceTerms() {
        navigationController?.pushViewController(
            TermsOfServiceViewController.instantiate(ServiceTerms()),
            animated: true)
    }

    private func navigateToGamblingResponsibility() {
        navigationController?.pushViewController(
            TermsOfServiceViewController.instantiate(GameblingResponsibility()),
            animated: true)
    }

    private func navigateToAboutKTO() {
        self.performSegue(withIdentifier: AboutKTOViewController.segueIdentifier, sender: nil)
    }

    private func navigateToLegalSupervision() {
        self.performSegue(withIdentifier: LegalSupervisionViewController.segueIdentifier, sender: nil)
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

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.tableView(didSelectRowAt: indexPath)
    }
}

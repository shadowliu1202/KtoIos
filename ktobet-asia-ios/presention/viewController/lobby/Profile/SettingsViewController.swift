import UIKit

class SettingsViewController: LobbyViewController, SettingsTableDelegate {
    private static let embedSegue = "embedSegue"
    static let segueIdentifier = "toSettings"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SettingsViewController.embedSegue, let tableVC = segue.destination as? SettingsTableViewController {
            tableVC.delegate = self
        }
    }
    
    func tableView(didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: SetMainPageViewController.segueIdentifier, sender: nil)
    }
}

protocol SettingsTableDelegate: AnyObject {
    func tableView(didSelectRowAt indexPath: IndexPath)
}

class SettingsTableViewController: UITableViewController {
    weak var delegate: SettingsTableDelegate?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.tableView(didSelectRowAt: indexPath)
    }
}

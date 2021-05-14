import UIKit

typealias UnsettleHelper = UIViewController & ProductGoWebGameVCProtocol & UnsettleTableViewDelegate & UITableViewDelegate

protocol UnsettleTableViewDelegate {
    func gameId(at indexPath: IndexPath) -> Int32
}

class UnsettleGameDelegate : NSObject {
    weak var helper: UnsettleHelper?
    init(_ vc: UnsettleHelper) {
        self.helper = vc
    }
}

extension UnsettleGameDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let helper = helper else { return }
        let storyboard = UIStoryboard(name: "Product", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "GameWebViewViewController") as! GameWebViewViewController
        vc.gameId = helper.gameId(at: indexPath)
        vc.viewModel = helper.getProductViewModel()
        helper.present(vc, animated: true, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        helper?.tableView?(tableView, heightForHeaderInSection: section) ?? 58
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        helper?.tableView?(tableView, heightForRowAt: indexPath) ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        helper?.tableView?(tableView, heightForFooterInSection: section) ?? 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        helper?.tableView?(tableView, viewForHeaderInSection: section)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        helper?.tableView?(tableView, willDisplayHeaderView: view, forSection: section)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        helper?.tableView?(tableView, willDisplay: cell, forRowAt: indexPath)
    }
}

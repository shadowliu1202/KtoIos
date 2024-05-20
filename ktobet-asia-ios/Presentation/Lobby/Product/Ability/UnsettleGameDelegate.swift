import UIKit

typealias UnsettleHelper = ProductGoWebGameVCProtocol & UITableViewDelegate & UIViewController & UnsettleTableViewDelegate &
    WebGameViewCallback

protocol UnsettleTableViewDelegate {
    func gameId(at indexPath: IndexPath) -> Int32
    func gameName(at indexPath: IndexPath) -> String
}

class UnsettleGameDelegate: NSObject {
    weak var helper: UnsettleHelper?
    init(_ vc: UnsettleHelper) {
        self.helper = vc
    }
}

extension UnsettleGameDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        helper?.tableView?(tableView, didSelectRowAt: indexPath)
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

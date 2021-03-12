import Foundation
import UIKit
import RxSwift

extension UITableView {
    
    /// Get customized "UITableViewCell" from "UITableView"
    /// - Parameters:
    ///     - identifier: The *identifier* is reuse identifier
    ///     - cellType: The *cellType* is table cell class type
    func dequeueReusableCell<T>(withIdentifier identifier: String = String(describing: T.self),
                                cellType: T.Type) -> T  {
        if let cell = self.dequeueReusableCell(withIdentifier: identifier) as? T {
            return cell
        } else {
            registerCellFromNib(identifier)
            return self.dequeueReusableCell(withIdentifier: identifier) as! T
        }
    }
    
    func dequeueReusableCell<T: UITableViewCell>(forIndexPath indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: String(describing: T.self), for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(String(describing: T.self))")
        }
        
        return cell
    }
    
    func registerCellFromNib(_ id: String?) {
        guard let id = id else { return }
        register(UINib(nibName: id, bundle: nil), forCellReuseIdentifier: id)
    }
    
    func setTransparentFooter() {
        tableFooterView = UIView()
        tableFooterView?.backgroundColor = .clear
    }
}

extension UIScrollView {
    var rx_reachedBottom: Observable<Void> {
        return rx.contentOffset
            .flatMap { [weak self] contentOffset -> Observable<Void> in
                guard let scrollView = self else {
                    return Observable.empty()
                }
                
                let visibleHeight = scrollView.frame.height - scrollView.contentInset.top - scrollView.contentInset.bottom
                let y = contentOffset.y + scrollView.contentInset.top
                let threshold = max(0.0, scrollView.contentSize.height - visibleHeight)
                
                return y > threshold ? Observable.just(()) : Observable.empty()
        }
    }
}

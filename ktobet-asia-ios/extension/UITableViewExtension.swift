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
    
    func setHeaderFooterDivider(dividerInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
                                dividerColor: UIColor = UIColor.dividerCapeCodGray2,
                                headerHeight: CGFloat = 30,
                                headerColor: UIColor = UIColor.clear,
                                headerDividerColor: UIColor = UIColor.dividerCapeCodGray2,
                                footerHeight: CGFloat = 96,
                                footerColor: UIColor = UIColor.clear,
                                footerDividerColor: UIColor = UIColor.dividerCapeCodGray2) {
        self.setHeader(headerHeight: headerHeight, headerColor: headerColor, headerDividerColor: headerDividerColor)
        self.setFooter(footerHeight: footerHeight, footerColor: footerColor, footerDividerColor: footerDividerColor)
        self.setDivider(dividerInset: dividerInset, dividerColor: dividerColor)
    }
    
    func setDivider(dividerInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
                    dividerColor: UIColor = UIColor.dividerCapeCodGray2) {
        self.separatorInset = dividerInset
        self.separatorStyle = .singleLine
        self.separatorColor = dividerColor
    }
    
    private func setHeader(headerHeight: CGFloat = 30,
                           headerColor: UIColor = UIColor.clear,
                           headerDividerColor: UIColor = UIColor.dividerCapeCodGray2) {
        self.tableHeaderView = UIView(frame: CGRect.init(x: 0, y: 0, width: self.bounds.width, height: headerHeight))
        self.tableHeaderView?.backgroundColor = headerColor
        self.tableHeaderView?.addBorder(.bottom, size: 0.5, color: headerDividerColor)
    }
    
    private func setFooter(footerHeight: CGFloat = 96,
                           footerColor: UIColor = UIColor.clear,
                           footerDividerColor: UIColor = UIColor.dividerCapeCodGray2) {
        self.tableFooterView = UIView(frame: CGRect.init(x: 0, y: 0, width: self.bounds.width, height: footerHeight))
        self.tableFooterView?.backgroundColor = footerColor
        self.tableFooterView?.addBorder(.top, size: 0.5, color: footerDividerColor)
    }
    
    func addTopBorder(size: CGFloat, color: UIColor) {
        if self.tableHeaderView == nil {
            self.tableHeaderView = UIView(frame: CGRect.init(x: 0, y: 0, width: self.bounds.width, height: 0))
        }
        self.tableHeaderView?.addBorder(.top, size: size, color: color)
    }
    
    func addBottomBorder(size: CGFloat, color: UIColor) {
        if self.tableFooterView == nil {
            self.tableFooterView = UIView(frame: CGRect.init(x: 0, y: 0, width: self.bounds.width, height: 0))
        }
        self.tableFooterView?.addBorder(.bottom, size: size, color: color)
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

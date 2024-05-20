import Foundation
import RxSwift
import UIKit

extension UITableView {
    /// Get customized "UITableViewCell" from "UITableView"
    /// - Parameters:
    ///     - identifier: The *identifier* is reuse identifier
    ///     - cellType: The *cellType* is table cell class type
    func dequeueReusableCell<T>(
        withIdentifier identifier: String = String(describing: T.self),
        cellType _: T.Type)
        -> T
    {
        if let cell = self.dequeueReusableCell(withIdentifier: identifier) as? T {
            return cell
        }
        else {
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
        guard let id else { return }
        register(UINib(nibName: id, bundle: nil), forCellReuseIdentifier: id)
    }

    func dequeueReusableHeaderFooter<T>(
        withIdentifier identifier: String = String(describing: T.self),
        cellType _: T.Type)
        -> T
    {
        if let cell = self.dequeueReusableHeaderFooterView(withIdentifier: identifier) as? T {
            return cell
        }
        else {
            registerHeaderFooterFromNib(identifier)
            return self.dequeueReusableHeaderFooterView(withIdentifier: identifier) as! T
        }
    }

    func registerHeaderFooterFromNib(_ id: String?) {
        guard let id else { return }
        register(UINib(nibName: id, bundle: nil), forHeaderFooterViewReuseIdentifier: id)
    }

    func setHeaderFooterDivider(
        headerHeight: CGFloat = 30,
        headerColor: UIColor = UIColor.clear,
        headerDividerColor: UIColor = UIColor.greyScaleDivider,
        footerHeight: CGFloat = 96,
        footerColor: UIColor = UIColor.clear,
        footerDividerColor: UIColor = UIColor.greyScaleDivider)
    {
        self.setHeader(headerHeight: headerHeight, headerColor: headerColor, headerDividerColor: headerDividerColor)
        self.setFooter(footerHeight: footerHeight, footerColor: footerColor, footerDividerColor: footerDividerColor)
        self.separatorColor = .clear
    }

    func setDivider(
        dividerInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
        dividerColor: UIColor = UIColor.greyScaleDivider)
    {
        self.separatorInset = dividerInset
        self.separatorStyle = .singleLine
        self.separatorColor = dividerColor
    }

    private func setHeader(
        headerHeight: CGFloat = 30,
        headerColor: UIColor = UIColor.clear,
        headerDividerColor: UIColor = UIColor.greyScaleDivider)
    {
        self.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: headerHeight))
        self.tableHeaderView?.backgroundColor = headerColor
        self.tableHeaderView?.addBorder(.bottom, color: headerDividerColor)
    }

    private func setFooter(
        footerHeight: CGFloat = 96,
        footerColor: UIColor = UIColor.clear,
        footerDividerColor: UIColor = UIColor.greyScaleDivider)
    {
        self.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: footerHeight))
        self.tableFooterView?.backgroundColor = footerColor
        self.tableFooterView?.addBorder(.top, color: footerDividerColor)
    }

    func addTopBorder(size: CGFloat = 1, color: UIColor = .greyScaleDivider) {
        if self.tableHeaderView == nil {
            self.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: 0))
        }
        self.tableHeaderView?.addBorder(.top, size: size, color: color)
    }

    func addBottomBorder(size: CGFloat = 1, color: UIColor = .greyScaleDivider) {
        if self.tableFooterView == nil {
            self.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: 0))
        }
        self.tableFooterView?.addBorder(.bottom, size: size, color: color)
    }

    func layoutTableHeaderView() {
        guard let headerView = self.tableHeaderView else { return }
        headerView.translatesAutoresizingMaskIntoConstraints = false

        let headerWidth = headerView.bounds.size.width
        let temporaryWidthConstraint = headerView.widthAnchor.constraint(equalToConstant: headerWidth)

        headerView.addConstraint(temporaryWidthConstraint)

        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()

        let headerSize = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let height = headerSize.height
        var frame = headerView.frame

        frame.size.height = height
        headerView.frame = frame

        self.tableHeaderView = headerView

        headerView.removeConstraint(temporaryWidthConstraint)
        headerView.translatesAutoresizingMaskIntoConstraints = true
    }
}

extension Reactive where Base: UIScrollView {
    var reachedBottom: Observable<Void> {
        base.rx.contentOffset
            .flatMap { contentOffset -> Observable<Void> in
                let scrollView = base
                let visibleHeight = scrollView.frame.height - scrollView.contentInset.top - scrollView.contentInset.bottom
                let y = contentOffset.y + scrollView.contentInset.top
                let threshold = max(0.0, scrollView.contentSize.height - visibleHeight)

                return y > threshold ? Observable.just(()) : Observable.empty()
            }
    }
}

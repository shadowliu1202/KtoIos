//
//  FilterButton.swift
//  ktobet-asia-ios
//
//  Created by Leo Hsu on 2021/3/4.
//

import UIKit
import RxSwift
import RxCocoa

class FilterButton: UIView {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var interactiveBtn: UIButton!
    var callback: (() -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadXib()
        setTitle(Localize.string("common_all"))
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadXib()
        setTitle(Localize.string("common_all"))
    }
    
    private func loadXib(){
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "FilterButton", bundle: bundle)
        let xibView = nib.instantiate(withOwner: self, options: nil)[0] as? UIView
        xibView?.layer.cornerRadius = 8
        xibView?.layer.masksToBounds = true
        addSubview(xibView!)
        xibView?.translatesAutoresizingMaskIntoConstraints = false
        let attributes: [NSLayoutConstraint.Attribute] = [.top, .bottom, .right, .left]
        NSLayoutConstraint.activate(attributes.map {
            NSLayoutConstraint(item: xibView!, attribute: $0, relatedBy: .equal, toItem: xibView!.superview, attribute: $0, multiplier: 1, constant: 0)
        })
    }
    
    @IBAction private func btnFilterPressed(_ sender : UIButton) {
        self.callback?()
    }
    
    func setTitle(_ title: String?) {
        self.titleLabel.text = title
    }
    
    func setTitle(_ source: [FilterItem]?) {
        var text = ""
        let allSelectCount = source?.filter({ $0.isSelected == true }).count
        let interactiveCount = source?.filter({$0.type != .static}).count
        //If all condition were selected, text should display with Localize.string("common_all")
        if allSelectCount == interactiveCount {
            text = Localize.string("common_all")
        } else {
            source?.filter({ $0.isSelected == true }).forEach { text.append("\($0.title)/") }
            text = String(text.dropLast())
        }
        self.setTitle(text)
    }
    
}

extension Reactive where Base: FilterButton {
    var touchUpInside: ControlEvent<Void> {
        base.interactiveBtn.rx.controlEvent(.touchUpInside)
    }
}
 

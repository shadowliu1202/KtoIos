import UIKit
import SharedBu

class GameTagStackView: UIStackView {
    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.addArrangedSubview(createOneChildView(self))
        let allBtn = createOneButton(title: Localize.string("common_all"), isSelected: true, callback: UIAction(){_ in })
        self.arrangedSubviews.last?.addSubview(allBtn)
    }
    
    func initialize(recommend: (ProductDTO.RecommendTag?, Bool) = (nil , false),
                    new: (ProductDTO.NewTag?, Bool) = (nil, false),
                    data: [(ProductDTO.GameTag, Bool)] = [],
                    allTagClick: @escaping () -> Void,
                    recommendClick: @escaping (() -> Void) = {},
                    newClick: @escaping (() -> Void) = {},
                    customClick: @escaping ((ProductDTO.GameTag) -> Void) = {_ in}) {
        self.removeAllArrangedSubviews()
        self.translatesAutoresizingMaskIntoConstraints = false
        self.spacing = 8
        self.axis = .vertical
        self.distribution = .equalSpacing
        self.addArrangedSubview(createOneChildView(self))
        
        let allBtn = createOneButton(title: Localize.string("common_all"), isSelected: data.allSatisfy({$0.1 == false}) && recommend.1 == false && new.1 == false, callback: UIAction() { _ in
            allTagClick()
        })
        self.arrangedSubviews.last?.addSubview(allBtn)
        
        if let recommendTag = recommend.0 {
            let recommendBtn = createOneButton(title: recommendTag.name, isSelected: recommend.1, callback: UIAction() { _ in
                recommendClick()
            })
            self.arrangedSubviews.last?.addSubview(recommendBtn)
        }
        if let newTag = new.0 {
            let newBtn = createOneButton( title: newTag.name, isSelected: new.1, callback: UIAction() { _ in
                newClick()
            })
            self.arrangedSubviews.last?.addSubview(newBtn)
        }
        
        data.forEach { (key, isSelected) in
            let button = createOneButton(title: key.name, isSelected: isSelected, callback: UIAction() { _ in
                customClick(key)
            })
            
            self.arrangedSubviews.last?.addSubview(button)
        }
    }
    
    private func getCurrentOffsetX()->CGFloat{
        return self.arrangedSubviews.last?.subviews.reduce(0){ (total, view) -> CGFloat in
            return total + view.frame.size.width + 8
        } ?? 0
    }
    
    private func isRowWidthExceed(_ btnWidth: CGFloat) -> Bool {
        getCurrentOffsetX() + btnWidth > self.frame.size.width
    }
    
    private func createOneButton(title: String, isSelected: Bool, callback: UIAction) -> UIButton {
        let frame = CGRect(x: getCurrentOffsetX(), y: 0, width: 180, height: 40 )
        
        let button = UIButton(frame: frame, primaryAction: callback)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font =  UIFont(name: "PingFangSC-Medium", size: 12)
        button.titleLabel?.numberOfLines = 0
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 18, bottom: 8, right: 18)
        button.sizeToFit()
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        if isSelected {
            button.applyGradient(vertical: [UIColor(rgb: 0xf74d25).cgColor, UIColor(rgb: 0xf20000).cgColor])
            button.setTitleColor(UIColor.whiteFull, for: .normal)
        } else {
            button.applyGradient(vertical: [UIColor(rgb: 0x32383e).cgColor, UIColor(rgb: 0x17191c).cgColor])
            button.setTitleColor(UIColor.textPrimaryDustyGray, for: .normal)
        }
        if isRowWidthExceed(button.frame.size.width) {
            let childRow = createOneChildView(self)
            self.addArrangedSubview(childRow)
            button.frame.origin.x = 0
        }
        return button
    }
    
    private func createOneChildView(_ parentView: UIStackView) -> UIView {
        let childRow = UIView(frame: .zero)
        childRow.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        childRow.widthAnchor.constraint(equalToConstant: parentView.frame.size.width).isActive = true
        return childRow
    }
}

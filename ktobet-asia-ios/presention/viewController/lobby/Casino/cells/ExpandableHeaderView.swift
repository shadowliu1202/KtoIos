import UIKit


protocol ExpandableHeaderViewDelegate: AnyObject {
    func toggleSection(header: ExpandableHeaderView, section: Int)
}

class ExpandableHeaderView: UITableViewHeaderFooterView {
    weak var delegate: ExpandableHeaderViewDelegate?
    var section: Int!
    var imageView = UIImageView()
    var dateTimeLabel = UILabel()
    
    func customInit(title: String, section: Int, delegate: ExpandableHeaderViewDelegate, date: String? = nil){
        self.textLabel?.text = title
        self.dateTimeLabel.text = date ?? ""
        self.section = section
        self.delegate = delegate
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clickSecionHeader)))
        self.addBorder(.top, size: 0.5, color: UIColor.dividerCapeCodGray2)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func clickSecionHeader(gesture: UITapGestureRecognizer){
        let cell = gesture.view as! ExpandableHeaderView
        delegate?.toggleSection(header: self, section: cell.section)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.textLabel?.textColor = UIColor.whiteFull
        self.contentView.backgroundColor = UIColor.black_two
    }
}

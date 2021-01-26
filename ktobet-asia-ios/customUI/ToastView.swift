import Foundation
import UIKit


class ToastView: UIView {
    @IBOutlet private weak var labStatusTip: UILabel!
    @IBOutlet private weak var imgStatusTip : UIImageView!
    
    var xibView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadXib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadXib()
    }
    
    func loadXib(){
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "Toast", bundle: bundle)
        xibView = nib.instantiate(withOwner: self, options: nil)[0] as? UIView
        xibView.layer.cornerRadius = 8
        xibView.layer.masksToBounds = true
        addSubview(xibView)
    }
    
    func show(statusTip: String, img: UIImage?) {
        xibView.isHidden = false
        labStatusTip.text = statusTip
        imgStatusTip.image = img
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.xibView.removeFromSuperview()
        }
    }
    
    func show(on view: UIView, statusTip: String, img: UIImage?) {
        xibView.isHidden = false
        labStatusTip.text = statusTip
        imgStatusTip.image = img
        xibView.backgroundColor = UIColor.red
        view.addSubview(xibView)
        
        xibView.translatesAutoresizingMaskIntoConstraints = false
        xibView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        xibView.widthAnchor.constraint(equalToConstant: view.frame.width).isActive = true
        xibView.heightAnchor.constraint(equalToConstant: 48).isActive = true
        xibView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.xibView.removeFromSuperview()
        }
    }

}

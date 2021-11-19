import Foundation
import UIKit

class ToastView: UIView {
    @IBOutlet private weak var labStatusTip: UILabel!
    @IBOutlet private weak var imgStatusTip : UIImageView!
    private var bgColor = UIColor.toastBackgroundGray
    private var shadowLayer: CAShapeLayer!
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
        xibView.clipsToBounds = true
        xibView.layer.masksToBounds = false
        xibView.layer.shadowRadius = 4
        xibView.layer.shadowOpacity = 1
        xibView.layer.shadowOffset = CGSize(width: 0, height: 0)
        xibView.layer.shadowColor = bgColor.cgColor
        
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
        xibView.backgroundColor = bgColor
        view.addSubview(xibView)
        
        xibView.translatesAutoresizingMaskIntoConstraints = false
        xibView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        xibView.widthAnchor.constraint(equalToConstant: view.frame.width - 20).isActive = true
        xibView.heightAnchor.constraint(equalToConstant: 48).isActive = true
        xibView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.xibView.removeFromSuperview()
        }
    }
    
    func show(on window: UIWindow? = nil, statusTip: String, img: UIImage?) {
        var lastWindow: UIWindow?
        if window != nil {
            lastWindow = window
        } else {
            lastWindow = UIApplication.shared.windows.first
        }
        guard let win = lastWindow else { return }
        xibView.isHidden = false
        labStatusTip.text = statusTip
        imgStatusTip.image = img
        xibView.backgroundColor = bgColor
        win.addSubview(xibView)
        
        xibView.translatesAutoresizingMaskIntoConstraints = false
        xibView.centerXAnchor.constraint(equalTo: win.centerXAnchor).isActive = true
        xibView.widthAnchor.constraint(equalToConstant: win.frame.width - 20).isActive = true
        xibView.heightAnchor.constraint(equalToConstant: 48).isActive = true
        xibView.bottomAnchor.constraint(equalTo: win.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.xibView.removeFromSuperview()
        }
    }

}

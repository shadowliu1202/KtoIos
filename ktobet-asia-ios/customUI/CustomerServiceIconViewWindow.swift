import UIKit
import RxSwift


class CustomerServiceIconViewWindow: UIWindow {
    var viewModel: CustomerServiceViewModel!
    var unReadNumberLabel: UILabel!
    var img: UIImageView!
    var backgroundView: UIView!
    var count = 0
    var touchUpInside: (() -> ())?
    let disposeBag = DisposeBag()
    
    init(frame: CGRect, viewModel: CustomerServiceViewModel) {
        super.init(frame: frame)
        self.viewModel = viewModel
        backgroundView = UIView()
        backgroundView.backgroundColor = .yellowFull
        backgroundView.frame.size = CGSize(width: 56, height: 56)
        backgroundView.roundCorners(corners: .allCorners, radius: backgroundView.frame.width / 2)
        addSubview(backgroundView)
        img = UIImageView(image: UIImage(named: "CS Floating"))
        img.center = backgroundView.center
        backgroundView.addSubview(img)
        unReadNumberLabel = UILabel(frame: CGRect(x: 36, y: 0, width: 20, height: 20))
        unReadNumberLabel.textColor = .white
        unReadNumberLabel.textAlignment = .center
        unReadNumberLabel.font = UIFont(name: "PingFangSC-Semibold", size: 12)
        unReadNumberLabel.roundCorners(corners: .allCorners, radius: unReadNumberLabel.frame.width / 2)
        addSubview(unReadNumberLabel)
        unReadNumberLabel.backgroundColor = .red
        windowLevel = UIWindow.Level.alert + 1
        
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(dragga)))
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
        
        let chatRoomUnreadMessageOb = viewModel.chatRoomUnreadMessage.observeOn(MainScheduler.asyncInstance).share(replay: 1)
        chatRoomUnreadMessageOb.map{ $0.count > 9 ? "9+" : "\($0.count)" }.bind(to: unReadNumberLabel.rx.text).disposed(by: disposeBag)
        chatRoomUnreadMessageOb.map{ $0.count <= 0 }.bind(to: unReadNumberLabel.rx.isHidden).disposed(by: disposeBag)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func dragga(pan: UIPanGestureRecognizer) {
        let translation = pan.translation(in: UIWindow.key)
        let originalCenter = center
        center = CGPoint(x: originalCenter.x + translation.x, y: originalCenter.y + translation.y)
        pan.setTranslation(CGPoint.zero, in: UIWindow.key)
    }
    
    @objc func tap(gesture: UITapGestureRecognizer) {
        touchUpInside?()
    }
}

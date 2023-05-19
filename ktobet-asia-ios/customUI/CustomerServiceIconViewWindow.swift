import RxSwift
import UIKit

class CustomerServiceIconViewWindow: UIWindow {
  var viewModel: CustomerServiceViewModel!
  var unReadNumberLabel: UILabel!
  var img: UIImageView!
  var backgroundView: UIView!
  var count = 0
  var touchUpInside: (() -> Void)?
  let disposeBag = DisposeBag()

  init(frame: CGRect, viewModel: CustomerServiceViewModel) {
    super.init(frame: frame)
    self.viewModel = viewModel
    backgroundView = UIView()
    backgroundView.backgroundColor = .complementaryDefault
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
    unReadNumberLabel.backgroundColor = .primaryDefault
    windowLevel = UIWindow.Level.alert + 1

    addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(dragga)))
    addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))

    let chatRoomUnreadMessageOb = viewModel.chatRoomUnreadMessage.observe(on: MainScheduler.asyncInstance).share(replay: 1)
    chatRoomUnreadMessageOb.map { $0.count > 9 ? "9+" : "\($0.count)" }.bind(to: unReadNumberLabel.rx.text)
      .disposed(by: disposeBag)
    chatRoomUnreadMessageOb.map { $0.count <= 0 }.bind(to: unReadNumberLabel.rx.isHidden).disposed(by: disposeBag)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc
  func dragga(pan: UIPanGestureRecognizer) {
    let width = self.frame.size.width / 2
    let height = self.frame.size.height / 2
    let window = UIApplication.shared.windows[0]
    let safeFrame = window.safeAreaLayoutGuide.layoutFrame
    let location = pan.location(in: window)
    let draggedView = pan.view
    draggedView?.center = location

    if pan.state == .ended {
      if self.frame.midX >= safeFrame.maxX - width {
        self.center.x = safeFrame.maxX - width
      }

      if self.frame.midX <= safeFrame.minX + width {
        self.center.x = safeFrame.minX + width
      }

      if self.frame.midY >= safeFrame.maxY - height {
        self.center.y = safeFrame.maxY - height
      }

      if self.frame.midY <= safeFrame.minY + height {
        self.center.y = safeFrame.minY + height
      }
    }
  }

  @objc
  func tap(gesture _: UITapGestureRecognizer) {
    touchUpInside?()
  }
}

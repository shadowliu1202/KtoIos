import UIKit

class NetworkControlWindow: UIWindow {
  var label: UILabel!
  var backgroundView: UIView!
  var count = 0
  var touchUpInside: ((Bool) -> Void)?
  var isNetworkConnected = true

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundView = UIView()
    backgroundView.backgroundColor = .green
    backgroundView.frame.size = CGSize(width: 56, height: 56)
    backgroundView.roundCorners(corners: .allCorners, radius: backgroundView.frame.width / 2)
    addSubview(backgroundView)
    label = UILabel(frame: .zero)
    label.center = backgroundView.center
    label.textColor = .white
    label.font = UIFont(name: "PingFangSC-Semibold", size: 14)
    label.roundCorners(corners: .allCorners, radius: label.frame.width / 2)
    label.text = "連線中"
    addSubview(label, constraints: .fill())
    label.backgroundColor = .primaryDefault
    windowLevel = UIWindow.Level.alert + 1

    addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(dragga)))
    addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
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
    isNetworkConnected.toggle()
    NetworkStateMonitor.shared.setIsNetworkConnected(isNetworkConnected)
    if isNetworkConnected {
      label.text = "連線中"
    }
    else {
      label.text = "斷網中"
    }
    touchUpInside?(isNetworkConnected)
  }
}

import RxRelay
import RxSwift
import SnapKit
import UIKit

protocol SnackBar: AnyObject {
  func show(tip: String, image: UIImage?)
}

class SnackBarImpl: SnackBar {
  static let shared: SnackBar = SnackBarImpl()

  private let toastRelay: PublishRelay<(tip: String, image: UIImage?)> = .init()
  private let disposeBag = DisposeBag()

  private var bottomConstraint: SnapKit.Constraint?

  let AnimationDuration: TimeInterval = 0.2
  let DisappearTime: TimeInterval = 2.5
  let snackBarView = SnackBarView()

  private init() {
    setupUI()
    bindData()
  }

  func show(tip: String, image: UIImage?) {
    toastRelay.accept((tip, image))
  }
  
  func getToastObservable(scheduler: SchedulerType = MainScheduler.instance)
    -> Observable<(tip: String, image: UIImage?)>
  {
    toastRelay
      .throttle(.seconds(3), scheduler: scheduler)
  }
}

extension SnackBarImpl {
  private func setupUI() {
    if
      snackBarView.superview == nil,
      let keyWindow = UIWindow.key
    {
      keyWindow.addSubview(snackBarView)

      snackBarView.snp.makeConstraints { make in
        make.leading.trailing.equalToSuperview().inset(10)
        bottomConstraint = make.bottom.equalTo(keyWindow.safeAreaLayoutGuide.snp.bottom).offset(100).constraint
      }
      keyWindow.layoutIfNeeded()
    }
  }

  private func bindData() {
    getToastObservable()
      .bind(onNext: { [weak self] in
        self?.snackBarView.setText($0.0)
        self?.snackBarView.setImage($0.1)
        self?.displayWithAnimate()
      })
      .disposed(by: disposeBag)
  }

  private func displayWithAnimate() {
    UIView.animate(
      withDuration: AnimationDuration,
      delay: 0,
      options: .curveLinear,
      animations: { [weak self] () in
        guard let self else { return }
        UIWindow.key?.bringSubviewToFront(self.snackBarView)
        self.bottomConstraint?.update(offset: -10)
        UIWindow.key?.layoutIfNeeded()
      })

    DispatchQueue.main.asyncAfter(deadline: .now() + DisappearTime) {
      self.hideWithAnimate()
    }
  }

  private func hideWithAnimate() {
    UIView.animate(
      withDuration: AnimationDuration,
      delay: 0,
      options: .curveLinear,
      animations: { [weak self] () in
        guard let self else { return }
        self.bottomConstraint?.update(offset: 100)
        UIWindow.key?.layoutIfNeeded()
      })
  }
}

import RxSwift
import UIKit

extension Loading {
  func bindPlaceholder(
    _ placeholder: LoadingPlaceholderViewController,
    to observable: Observable<Bool>,
    at viewController: UIViewController)
    -> Disposable
  {
    observable
      .take(
        until: { [weak placeholder] _ in
          !(placeholder?.viewModel.isLoading ?? false)
        },
        behavior: .exclusive)
      .observe(on: MainScheduler.instance)
      .distinctUntilChanged()
      .subscribe(onNext: { [weak viewController, weak placeholder] in
        guard
          let viewController,
          let placeholder
        else { return }

        if $0 {
          placeholder.addAsContainer(at: viewController)
        }
        else {
          placeholder.setIsLoading(false)
        }
      })
  }
}

import Foundation

protocol ApplicationStorable: LocalStorable {
  func getAppIsFirstLaunch() -> Bool
  func setAppWasLaunch()
  
  func getIsPoppedAutoUpdate() -> Bool
  func setIsPoppedAutoUpdate(_ popped: Bool)
}

class ApplicationStorage: ApplicationStorable {
  
  func getAppIsFirstLaunch() -> Bool {
    get(key: .isFirstLaunch) ?? true
  }

  func setAppWasLaunch() {
    set(value: false, key: .isFirstLaunch)
  }
  
  func getIsPoppedAutoUpdate() -> Bool {
    get(key: .isPoppedAutoUpdate) ?? false
  }
  
  func setIsPoppedAutoUpdate(_ popped: Bool) {
    set(value: popped, key: .isPoppedAutoUpdate)
  }
}

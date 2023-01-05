import Foundation

protocol ApplicationStorable: LocalStorable {
    func getAppIsFirstLaunch() -> Bool
    func setAppWasLaunch()
}

class ApplicationStorage: ApplicationStorable {
    
    func getAppIsFirstLaunch() -> Bool {
        let isFirst: Bool? = get(key: .isFirstLaunch)
        return isFirst ?? true
    }
    
    func setAppWasLaunch() {
        set(value: false, key: .isFirstLaunch)
    }
    
}

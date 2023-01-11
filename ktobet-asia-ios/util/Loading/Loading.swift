import UIKit
import RxSwift

protocol Loading: AnyObject {
    var isLoading: Bool { get }
    func setAppearance(isHidden: Bool)
}

class LoadingImpl: Loading {
    static let shared: Loading = LoadingImpl()
    
    private let loadingView = LoadingView()

    var isLoading: Bool { !loadingView.isHidden }    
    
    private init() { }
    
    func setAppearance(isHidden: Bool) {
        if loadingView.superview == nil {
            UIWindow.key?.addSubview(loadingView)
            
            loadingView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        if isHidden {
            loadingView.isHidden = true
        }
        else {
            UIWindow.key?.bringSubviewToFront(loadingView)
            loadingView.isHidden = false
        }
    }
}

extension ActivityIndicator {
    
    func bind(to loading: Loading) -> Disposable {
        asObservable()
            .subscribe(onNext: {
                loading.setAppearance(isHidden: !$0)
            })
    }
}

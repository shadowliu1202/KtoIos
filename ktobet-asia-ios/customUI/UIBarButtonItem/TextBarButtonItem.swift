import UIKit
import RxSwift

class TextBarButtonItem: UIBarButtonItem {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init(title: String?) {
        super.init()
        self.title = title
        self.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "PingFangSC-Semibold", size: 16)!], for: .normal)
        self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.whiteFull], for: .normal)
    }
}

let registerBarBtnId = 1001
let customerServiceBarBtnId = 1002
let loginBarBtnId = 1003

class CustomerServiceButtonItem: TextBarButtonItem {
    weak var delegate: CustomServiceDelegate? = nil
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init(_ delegate: CustomServiceDelegate? = nil, _ disposeBag: DisposeBag) {
        super.init(title: Localize.string("customerservice_title"))
        self.senderId(customerServiceBarBtnId)
        self.delegate = delegate
        self.delegate?.monitorChatRoomStatus(disposeBag)
        self.actionHandler({ [weak self] _ in
            guard let `self` = self, let vc = self.delegate as? UIViewController else { return }
            self.isEnabled = false
            CustomService.startCustomerService(from: vc, delegate: self.delegate)
                .subscribe(onCompleted: { [weak self] in
                    self?.isEnabled = true
                }, onError: { [weak self] in
                    self?.isEnabled = true
                    vc.handleErrors($0)
                }).disposed(by: disposeBag)
        })
    }
}

class RegisterButtonItem: TextBarButtonItem {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init() {
        super.init(title: Localize.string("common_register"))
        self.senderId(registerBarBtnId)
    }
}

class LoginButtonItem: TextBarButtonItem {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init() {
        super.init(title: Localize.string("common_login"))
        self.senderId(loginBarBtnId)
    }
}

import Foundation
import RxSwift
import RxCocoa
import SharedBu

class RealNameValidator {
    private let InitAndKeyboardFirstEvent = 2
    private(set) var editAccountName: BehaviorRelay<String>
    private var accountPatternGenerator: AccountPatternGenerator
    
    lazy var verifyAccountNameError: Observable<AccountNameException?> = self.editAccountName.skip(InitAndKeyboardFirstEvent).map { [unowned self] (accountName) -> AccountNameException? in
        return self.accountPatternGenerator.withdrawalName().validate(name: accountName)
    }
    lazy var isAccountNameValid: Observable<Bool> = self.verifyAccountNameError.map({ $0 == nil })
    
    init(editAccountName: BehaviorRelay<String>, accountPatternGenerator: AccountPatternGenerator) {
        self.editAccountName = editAccountName
        self.accountPatternGenerator = accountPatternGenerator
    }
    
}

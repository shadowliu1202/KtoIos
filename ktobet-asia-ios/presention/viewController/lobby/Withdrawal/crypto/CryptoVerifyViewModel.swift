import Foundation
import SharedBu
import RxSwift
import RxCocoa


class CryptoVerifyViewModel {
    lazy var phone = self.playerUseCase.loadPlayer().do(onSuccess: { self.relayMobile.accept($0.playerInfo.contact.mobile ?? "") }).map{ $0.playerInfo.contact.mobile }
    lazy var email = self.playerUseCase.loadPlayer().do(onSuccess: { self.relayMobile.accept($0.playerInfo.contact.email ?? "") }).map{ $0.playerInfo.contact.email }
    
    var relayAccountType = BehaviorRelay(value: AccountType.phone)
    var relayEmail = BehaviorRelay(value: "")
    var relayMobile = BehaviorRelay(value: "")
    var locale : SupportLocale = SupportLocale.China()
    var code1 = BehaviorRelay(value: "")
    var code2 = BehaviorRelay(value: "")
    var code3 = BehaviorRelay(value: "")
    var code4 = BehaviorRelay(value: "")
    var code5 = BehaviorRelay(value: "")
    var code6 = BehaviorRelay(value: "")
    
    private var playerUseCase : PlayerDataUseCase!
    private var withdrawalUseCase: WithdrawalUseCase!
    private var systemUseCase : GetSystemStatusUseCase!
    
    init(playerUseCase: PlayerDataUseCase, withdrawalUseCase: WithdrawalUseCase, systemUseCase : GetSystemStatusUseCase) {
        self.playerUseCase = playerUseCase
        self.withdrawalUseCase = withdrawalUseCase
        self.systemUseCase = systemUseCase
    }
    
    func verify(playerCryptoBankCardId: String) -> Completable {
        return withdrawalUseCase.sendCryptoOtpVerify(accountType: relayAccountType.value, playerCryptoBankCardId: playerCryptoBankCardId)
    }
    
    func verifyOtp() -> Completable {
        var verifyCode = ""
        for c in [code1, code2, code3, code4, code5, code6]{
            verifyCode += c.value
        }
        return withdrawalUseCase.verifyOtp(verifyCode: verifyCode, accountType: relayAccountType.value)
    }
    
    func resendOtp() -> Completable {
        return withdrawalUseCase.resendOtp(accountType: relayAccountType.value)
    }
    
    func checkCodeValid()-> Observable<Bool>{
        return Observable
            .combineLatest(code1, code2, code3, code4, code5, code6)
            .map { (code1, code2, code3, code4, code5, code6) -> Bool in
                return code1.count == 1 && code2.count == 1 && code3.count == 1 && code4.count == 1 && code5.count == 1 && code6.count == 1
            }
    }
    
    func otpValid() -> Observable<UserInfoStatus> {
        let typeChange = relayAccountType.asObservable()
        return systemUseCase
            .getOtpStatus()
            .asObservable()
            .concatMap { otpStatus  in
                return typeChange.map { (type)  -> UserInfoStatus in
                    if !otpStatus.isMailActive && !otpStatus.isSmsActive {
                        return .errOtpServiceDown
                    }
                    
                    switch type {
                    case .email: return otpStatus.isMailActive ? .valid : .errEmailOtpInactive
                    case .phone: return otpStatus.isSmsActive ? .valid : .errSMSOtpInactive
                    }
                }
            }
    }
}

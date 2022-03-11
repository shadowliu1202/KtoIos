import Foundation
import SharedBu
import RxSwift
import RxCocoa


class CryptoVerifyViewModel {
    lazy var phone = self.playerUseCase.loadPlayer().do(onSuccess: { self.relayMobile.accept($0.playerInfo.contact.mobile ?? "") }).map{ $0.playerInfo.contact.mobile }
    lazy var email = self.playerUseCase.loadPlayer().do(onSuccess: { self.relayEmail.accept($0.playerInfo.contact.email ?? "") }).map{ $0.playerInfo.contact.email }
    
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
    
    private var otpStatusRefreshSubject = PublishSubject<()>()
    private let otpStatus: ReplaySubject<OtpStatus> = .create(bufferSize: 1)
    private let disposeBag = DisposeBag()
    
    init(playerUseCase: PlayerDataUseCase, withdrawalUseCase: WithdrawalUseCase, systemUseCase : GetSystemStatusUseCase) {
        self.playerUseCase = playerUseCase
        self.withdrawalUseCase = withdrawalUseCase
        self.systemUseCase = systemUseCase
        
        otpStatusRefreshSubject.asObservable()
            .flatMapLatest{[unowned self] in self.systemUseCase.getOtpStatus().asObservable() }
            .bind(to: otpStatus)
            .disposed(by: disposeBag)
    }
    
    func verify(playerCryptoBankCardId: String) -> Completable {
        return withdrawalUseCase.sendCryptoOtpVerify(accountType: relayAccountType.value, playerCryptoBankCardId: playerCryptoBankCardId)
    }
    
    func verifyOtp(otp: String, accountType: AccountType) -> Completable {
        return withdrawalUseCase.verifyOtp(verifyCode: otp, accountType: accountType)
    }
    
    func resendOtp() -> Completable {
        return withdrawalUseCase.resendOtp(accountType: relayAccountType.value)
    }
    
    func inputAccountType(_ type: AccountType){
        refreshOtpStatus()
        relayAccountType.accept(type)
    }
    
    func refreshOtpStatus() {
        otpStatusRefreshSubject.onNext(())
    }
    
    func otpValid() -> Observable<UserInfoStatus> {
        let typeChange = relayAccountType.asObservable()
        return Observable.combineLatest(otpStatus, typeChange)
            .map { (otpStatus, type) -> UserInfoStatus in
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

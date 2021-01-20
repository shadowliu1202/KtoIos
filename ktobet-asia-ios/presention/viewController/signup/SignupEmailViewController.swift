//
//  SignupEmailViewController.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/30.
//

import UIKit
import RxSwift
import RxCocoa
import share_bu

class SignupEmailViewController: UIViewController {
    
    @IBOutlet private weak var naviItem : UINavigationItem!
    @IBOutlet private weak var scrollView : UIScrollView!
    @IBOutlet private weak var labTitle: UILabel!
    @IBOutlet private weak var labDesc: UILabel!
    @IBOutlet private weak var labTip : UILabel!
    @IBOutlet private weak var labSendOtpLabel : UILabel!
    @IBOutlet private weak var btnBack: UIBarButtonItem!
    @IBOutlet private weak var btnOpenMail: UIButton!
    @IBOutlet private weak var btnResend: UIButton!
    @IBOutlet private weak var btnCheckVerify : UIButton!
    @IBOutlet private weak var imgSendOtpIcon : UIImageView!
    @IBOutlet private weak var viewSendOtpTip : UIView!
    
    private let segueUserInfo = "BackToUserInfo"
    private let segueDefault = "GoToDefault"
    private var viewModel = DI.resolve(SignupEmailViewModel.self)!
    private var disposebag = DisposeBag()
    private var timerResend = KTOTimer()
    private var timerVerify = KTOTimer()
    private var checking = false
    private var btnQatCancelAutoVerify : UIButton?

    var account : String = ""
    var password : String = ""
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        addNotificationCenter()
        localize()
        defaultStyle()
        showTipOtpSend()
        resendTimer(launch: true)
        verifyTimer(launch: true)
        #if QAT
        addQATButton()
        #endif
    }
    
    func addQATButton(){
        btnQatCancelAutoVerify?.removeFromSuperview()
        btnQatCancelAutoVerify = nil
        btnQatCancelAutoVerify = UIButton()
        btnQatCancelAutoVerify?.frame = {
            let x = CGFloat(view.bounds.size.width * 0.5)
            let y = CGFloat(30)
            let width = CGFloat(200)
            let height = CGFloat(40)
            return CGRect(x: x, y: y, width: width, height: height)
        }()
        btnQatCancelAutoVerify?.setImage(UIImage(named: "Double Selection (Empty)"), for: .normal)
        btnQatCancelAutoVerify?.setImage(UIImage(named: "Double Selection (Selected)"), for: .selected)
        btnQatCancelAutoVerify?.setTitle("取消自動驗證", for: .normal)
        btnQatCancelAutoVerify?.setTitleColor(.black, for: .normal)
        btnQatCancelAutoVerify?.backgroundColor = .lightGray
        btnQatCancelAutoVerify?.addTarget(self, action: #selector(btnQatCancelAutoVerifyPressed(_:)), for: .touchUpInside)
        view.addSubview(btnQatCancelAutoVerify!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    deinit {
        removeNotificationCenter()
        resendTimer(launch: false)
        verifyTimer(launch: false)
    }
    
    // MARK: METHOD
    private func localize(){
        labTitle.text = Localize.string("register_step3_title_1")
        labDesc.text = Localize.string("register_step3_verify_by_email_title")
        labTip.text = String(format: Localize.string("register_step3_content_email"), account)
        labSendOtpLabel.text = Localize.string("common_otp_mail_send_success")
        btnOpenMail.setTitle(Localize.string("register_step3_open_mail"), for: .normal)
        btnResend.setTitle("", for: .normal)
        btnCheckVerify.setAttributedTitle({
            let str1 = Localize.string("register_step3_mail_varify_hint")
            let str2 = " "
            let str3 = Localize.string("register_step3_mail_varify_hint_highlight")
            let greyColor = UIColor(red: 155.0/255.0, green: 155.0/255.0, blue: 155.0/255.0, alpha: 1.0)
            let redColor = UIColor(red: 242.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1.0)
            let attriText = NSMutableAttributedString()
            let attriText1 = NSAttributedString(string: str1, attributes: [.foregroundColor : greyColor])
            let attriText2 = NSAttributedString(string: str2)
            let attriText3 = NSAttributedString(string: str3, attributes: [.foregroundColor : redColor])
            attriText.append(attriText1)
            attriText.append(attriText2)
            attriText.append(attriText3)
            return attriText
        }(), for: .normal)
    }
    
    private func defaultStyle(){
        naviItem.titleView = UIImageView(image: UIImage(named: "KTO (D)"))
        btnOpenMail.layer.masksToBounds = true
        btnOpenMail.layer.cornerRadius = 8
        viewSendOtpTip.layer.cornerRadius = 8
        viewSendOtpTip.layer.masksToBounds = true
    }
    
    private func setResendButton(_ seconds : Int){
        let enable = seconds == 0
        self.btnResend.setAttributedTitle({
            let descColor = UIColor(rgb: 0x9b9b9b)
            let enableColor = UIColor(red: 242.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1.0)
            let disableColor = UIColor(red: 242.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 0.5)
            let time : String = {
                let mm = seconds / 60
                let ss = seconds % 60
                return String(format: "%02d:%02d", mm, ss)
            }()
            let str1 = String(format: Localize.string("common_verify_mail_resend_tips"), time)
            let str2 = " "
            let str3 = Localize.string("common_resendotp")
            let attriText = NSMutableAttributedString()
            let attriText1 = NSAttributedString(string: str1, attributes: [.foregroundColor : descColor])
            let attriText2 = NSAttributedString(string: str2)
            let attriText3 = NSAttributedString(string: str3, attributes: [.foregroundColor : (enable ? enableColor : disableColor)])
            attriText.append(attriText1)
            attriText.append(attriText2)
            attriText.append(attriText3)
            return attriText
        }(), for: .normal)
        self.btnResend.isEnabled = enable
    }
    
    // MARK: SHOW TIP
    private func showTipOtpSend(){
        viewSendOtpTip.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.viewSendOtpTip.isHidden = true
        }
    }
    
    private func handleError(_ error : Error){
        let type = ErrorType(rawValue: (error as NSError).code)
        switch type {
        case .PlayerIdOverOtpLimit, .PlayerIpOverOtpDailyLimit:
            let title = Localize.string("common_tip_title_warm")
            let message = Localize.string("common_email_otp_exeed_send_limit")
            Alert
                .show(title, message, confirm: {
                    self.navigationController?.popToRootViewController(animated: true)
                }, cancel: nil)
            break
        case .PlayerOverOtpRetryLimit, .PlayerResentOtpOverTenTimes:
            let title = Localize.string("common_tip_title_warm")
            let message = Localize.string("common_email_otp_exeed_send_limit")
            Alert
                .show(title, message, confirm: {
                    self.navigationController?.popToRootViewController(animated: true)
                }, cancel: nil)
            break
        default:
            self.handleUnknownError(error)
        }
    }
    
    // MARK: TIMER
    func resendTimer(launch : Bool){
        if launch{
            timerResend
                .countDown(timeInterval: 1, duration: 180, block: {(index, second, finish) in
                    self.setResendButton(second)
                })
        } else {
            timerResend.stop()
        }
    }
    
    func verifyTimer(launch : Bool){
        if launch{
            timerVerify
                .repeate(timeInterval: 5, block: { index  in
                    self.checkRegistration(manual: false)
                })
        } else {
            timerVerify.stop()
        }
    }
    
    // MARK: API
    private func checkRegistration(manual: Bool){
        if !checking{
            checking = true
            viewModel
                .checkRegistration(account, password)
                .subscribe(onSuccess: { valid in
                    switch valid{
                    case .valid(let player): self.goToLobby(player)
                    default:
                        self.checking = false
                        if manual {
                            let title = Localize.string("common_tip_title_warm")
                            let message = Localize.string("register_step3_verification_pending")
                            Alert.show(title, message, confirm: nil, cancel: nil)
                        }
                    }
                }, onError: { error in
                    self.checking = false
                    if manual { self.handleError(error) }
                }).disposed(by: self.disposebag)
        }
    }
        
    // MARK: NOTIFICATION CENTER
    private func addNotificationCenter(){
        NotificationCenter
            .default
            .addObserver(forName: UIApplication.willEnterForegroundNotification,
                         object: nil,
                         queue: nil,
                         using: {notification in
                            #if QAT
                            if let btn = self.btnQatCancelAutoVerify,
                               btn.isSelected == false  {
                                self.checkRegistration(manual: false)
                            }
                            #else
                                self.checkRegistration(manual: false)
                            #endif
                            
                         })
    }
    
    private func removeNotificationCenter(){
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: BUTTON ACTION
    @IBAction func btnVerifyPressed(_ sender : UIButton){
        self.checkRegistration(manual: true)
        self.view.isUserInteractionEnabled = true
    }
    
    @IBAction func btnResendPressed(_ sender: UIButton){
        btnResend.isEnabled = false
        self.viewModel.resendOtp()
            .subscribe(onCompleted: {
                self.resendTimer(launch: true)
                self.showTipOtpSend()
            }, onError: { error in
                self.btnResend.isEnabled = true
                self.handleError(error)
            }).disposed(by: self.disposebag)
    }
    
    @IBAction func btnEmailPressed(_ sender: UIButton){
        if let mailUrl = URL(string: "message://"),
           UIApplication.shared.canOpenURL(mailUrl){
            UIApplication.shared.open(mailUrl, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func btnBackPressed(_ sender : UIButton){
        let title = Localize.string("common_tip_title_unfinished")
        let message = Localize.string("common_tip_content_unfinished")
        Alert.show(title, message) {
            self.navigationController?.popToRootViewController(animated: true)
        } cancel: {}
    }
    
    @objc private func btnQatCancelAutoVerifyPressed(_ sender : UIButton){
        sender.isSelected = !sender.isSelected
        verifyTimer(launch: !sender.isSelected)
    }
    
    // MARK: PAGE ACTION
    private func goToLobby(_ player : Player){
        let storyboard = UIStoryboard(name: "Lobby", bundle: nil)
        if let initVc = storyboard.instantiateInitialViewController() as? UINavigationController,
           let lobby = initVc.viewControllers.first as? LobbyViewController {
            lobby.player = player
            UIApplication.shared.keyWindow?.rootViewController = initVc
        }
    }
}

extension SignupEmailViewController{
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {}
    override func unwind(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) {}
}

import Foundation
import RxCocoa
import SnapKit
import UIKit

class SMSVerifyCodeInputView: UIView {
  @IBOutlet private var codeStackView: UIStackView!

  private var otpLength = 0
  private var codes: [SMSCodeTextField] = []

  override func awakeFromNib() {
    super.awakeFromNib()
  }

  func setOtpMaxLength(otpLength: Int32) {
    self.otpLength = Int(otpLength)
    
    let isVN = Int(otpLength) == OTPVerifyTextField.VNMobileLength
    codeStackView.spacing = isVN ? 12 : 0
    if !isVN {
      codeStackView.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }
    }
    
    for index in 0..<Int(otpLength) {
      let otpCodeCell = SMSCodeTextField(
        onInput: { [unowned self]  in focusToNext(current: index) },
        onDelete: { [unowned self]  in focusToPrevious(current: index) })
      
      codes.append(otpCodeCell)
      codeStackView.insertArrangedSubview(otpCodeCell, at: index)
    }

    backgroundColor = .clear
  }
  
  func getOtpCode() -> Observable<String> {
    let codeObs = codes.map { $0.rx.text.orEmpty }

    return Observable.combineLatest(codeObs)
      .map { stringElement -> String in
        stringElement.reduce("") { $0 + $1 }
      }
  }
  
  private func focusToNext(current index: Int) {
    guard index < codes.count - 1 else { return }
    
    codes[index + 1].becomeFirstResponder()
  }
  
  private func focusToPrevious(current index: Int) {
    guard index > 0 else { return }
    
    codes[index - 1].becomeFirstResponder()
  }
}

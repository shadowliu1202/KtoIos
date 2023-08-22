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
      let code = SMSCodeTextField()

      code.myDelegate = self
      code.tag = index
      code.addTarget(self, action: #selector(textEditingChaged(_:)), for: .editingChanged)
      
      codes.append(code)
      codeStackView.insertArrangedSubview(code, at: index)
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

  @objc
  private func textEditingChaged(_ sender: UITextField) {
    if let text = sender.text, text.count >= 1, text.count < otpLength {
      guard let lastText = text.last else { return }
      sender.text = String(lastText)

      let index = sender.tag + 1 > otpLength - 1 ? otpLength - 1 : sender.tag + 1
      codes[index].becomeFirstResponder()
    }
  }
}

extension SMSVerifyCodeInputView: SMSCodeTextFieldDelegate, UITextFieldDelegate {
  func textFieldDidDelete(_ sender: SMSCodeTextField) {
    if (sender.text?.count ?? 0) == 0 {
      let index = sender.tag - 1 < 0 ? 0 : sender.tag - 1
      codes[index].becomeFirstResponder()
    }
  }
}

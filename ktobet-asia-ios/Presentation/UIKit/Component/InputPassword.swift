import RxCocoa
import RxSwift
import UIKit

protocol InputPasswordDelegate {
  func shouldHidePassword(_ hide: Bool)
  func shouldFocus(_ focus: Bool)
  func getFocus() -> Bool
}

class InputPassword: UIView {
  private var firstPosition = true
  private var isEditing = false
  private var editingChangedHandler: ((String) -> Void)?

  private var labTitle = UILabel()
  private var textContent = PasswordTextField()
  private var btnHideContent = UIButton()
  private var underline = UIView()
  var text: ControlProperty<String> {
    textContent.rx.text.orEmpty
  }

  var confirmPassword: InputPasswordDelegate?
  var isFocus = false

  // MARK: LIFE CYCLE
  override func awakeFromNib() {
    super.awakeFromNib()

    backgroundColor = UIColor.inputFocus
    labTitle.font = UIFont(name: "PingFangSC-Regular", size: 12)
    labTitle.textColor = UIColor.textPrimary
    labTitle.backgroundColor = .clear

    textContent.keyboardType = .alphabet
    textContent.tintColor = .primaryDefault
    textContent.textColor = .white
    textContent.backgroundColor = .clear
    textContent.font = UIFont(name: "PingFangSC-Regular", size: 16)
    textContent.borderStyle = .none
    textContent.delegate = self
    textContent.isSecureTextEntry = true
    textContent.disableAutoFillOnIos16()
    textContent.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)

    btnHideContent.backgroundColor = .clear
    btnHideContent.setImage(UIImage(named: "Eye-Show"), for: .normal)
    btnHideContent.setImage(UIImage(named: "Eye-Hide"), for: .selected)
    btnHideContent.addTarget(self, action: #selector(btnHidePressed(_:)), for: .touchUpInside)
    btnHideContent.imageView?.contentMode = .center
    btnHideContent.isSelected = true

    underline.backgroundColor = UIColor.alert
    underline.isHidden = true

    addSubview(labTitle)
    addSubview(textContent)
    addSubview(btnHideContent)
    addSubview(underline)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    adjustPosition()
  }

  // MARK: POSITION
  func adjustPosition() {
    var position: (titleFont: UIFont, title: CGRect, hideBtn: CGRect, content: CGRect)

    if !isEditing, textContent.text?.count == 0 {
      position = emptyPosition()
    }
    else {
      position = editedPosition()
    }
    self.textContent.frame = position.content
    let changePosition = {
      self.labTitle.font = position.titleFont
      self.labTitle.frame = position.title
      self.btnHideContent.frame = position.hideBtn
      self.underline.frame = CGRect(x: 0, y: self.bounds.maxY - 2, width: self.bounds.width, height: 2)
      self.backgroundColor = self.getAllFocus() ? UIColor.inputFocus : UIColor.inputDefault
    }
    if firstPosition {
      changePosition()
      firstPosition = false
    }
    else {
      UIView.animate(withDuration: 0.2, animations: changePosition, completion: nil)
    }
  }

  private func emptyPosition() -> (titleFont: UIFont, title: CGRect, hideBtn: CGRect, content: CGRect) {
    let titleFont = UIFont(name: "PingFangSC-Regular", size: 14)!
    let border: CGFloat = 15
    let title: CGRect = {
      let width: CGFloat = labTitle.text?.width(withConstrainedHeight: bounds.height, font: titleFont) ?? 0
      let height: CGFloat = labTitle.text?.height(withConstrainedWidth: width, font: titleFont) ?? 0
      let x: CGFloat = border
      let y = bounds.midY - height * 0.5
      return CGRect(x: x, y: y, width: width, height: height)
    }()
    let hideButton: CGRect = {
      let width: CGFloat = 24 + 8
      let height: CGFloat = 24 + 8
      let x: CGFloat = bounds.width - border - width
      let y: CGFloat = bounds.midY - height * 0.5
      return CGRect(x: x, y: y, width: width, height: height)
    }()
    let content: CGRect = {
      let width: CGFloat = bounds.width - title.maxX - (hideButton.width - 8) - border * 3
      let height: CGFloat = bounds.height - border * 2
      let x: CGFloat = title.maxX + border
      let y: CGFloat = bounds.midY - height * 0.5
      return CGRect(x: x, y: y, width: width, height: height)
    }()
    return (titleFont, title, hideButton, content)
  }

  private func editedPosition() -> (titleFont: UIFont, title: CGRect, hideBtn: CGRect, content: CGRect) {
    let titleFont = UIFont(name: "PingFangSC-Regular", size: 12)!
    let border: CGFloat = 15
    let title: CGRect = {
      let width = labTitle.text?.width(withConstrainedHeight: bounds.height, font: titleFont) ?? 0 + 2
      let height = labTitle.text?.height(withConstrainedWidth: width, font: titleFont) ?? 0
      let x = border
      let y: CGFloat = 8
      return CGRect(x: x, y: y, width: width, height: height)
    }()
    let hideButton: CGRect = {
      let width: CGFloat = 24 + 8
      let height: CGFloat = 24 + 8
      let x: CGFloat = bounds.width - border - width
      let y: CGFloat = bounds.midY - height * 0.5
      return CGRect(x: x, y: y, width: width, height: height)
    }()
    let content: CGRect = {
      let width = bounds.width - (hideButton.width - 8) - border * 3
      let height = bounds.height - title.maxY - 8 - 8
      let x = border
      let y = title.maxY + 8
      return CGRect(x: x, y: y, width: width, height: height)
    }()
    return (titleFont, title, hideButton, content)
  }

  // MARK: BUTTON EVENT
  @objc
  private func btnHidePressed(_: UIButton) {
    btnHideContent.isSelected = !btnHideContent.isSelected
    textContent.isSecureTextEntry = btnHideContent.isSelected
    confirmPassword?.shouldHidePassword(btnHideContent.isSelected)
  }

  // MARK: SETUP UI
  func setTitle(_ title: String) {
    labTitle.text = title
  }

  func setCorner(topCorner: Bool, bottomCorner: Bool) {
    layer.masksToBounds = true
    layer.cornerRadius = 8
    if topCorner, bottomCorner {
      layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }
    else if topCorner {
      layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    else if bottomCorner {
      layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }
  }

  // MARK: PRESENT
  func showKeyboard() {
    _ = textContent.becomeFirstResponder()
  }

  func showUnderline(_ show: Bool) {
    underline.isHidden = !show
  }

  // MARK: TEXT HANDLER
  @objc
  private func textFieldEditingChanged(_ textField: UITextField) {
    editingChangedHandler?(textField.text ?? "")
  }

  func setEditingChangedHandler(_ editingChangedHandler: ((String) -> Void)?) {
    self.editingChangedHandler = editingChangedHandler
  }

  func getAllFocus() -> Bool {
    self.isFocus || self.isEditing || (confirmPassword?.getFocus() ?? false)
  }
}

extension InputPassword: UITextFieldDelegate {
  func textFieldShouldBeginEditing(_: UITextField) -> Bool {
    isEditing = true
    confirmPassword?.shouldFocus(true)
    adjustPosition()
    return true
  }

  func textFieldDidEndEditing(_: UITextField) {
    isEditing = false
    confirmPassword?.shouldFocus(false)
    adjustPosition()
  }
}

extension InputPassword {
  override func touchesBegan(_: Set<UITouch>, with _: UIEvent?) {
    if !textContent.isFirstResponder {
      _ = textContent.becomeFirstResponder()
      isEditing = true
    }
  }
}

extension InputPassword: InputConfirmPasswordDelegate {
  func getFocus() -> Bool {
    isFocus || isEditing
  }

  func shouldFocus(_ focus: Bool) {
    isFocus = focus
    self.backgroundColor = {
      guard self.getAllFocus() else {
        return UIColor.inputDefault
      }
      return UIColor.inputFocus
    }()
  }
}

class PasswordTextField: UITextField {
  override var isSecureTextEntry: Bool {
    didSet {
      if isFirstResponder {
        _ = becomeFirstResponder()
      }
    }
  }

  @discardableResult
  override func becomeFirstResponder() -> Bool {
    let success = super.becomeFirstResponder()
    if isSecureTextEntry, let text = self.text {
      self.text?.removeAll()
      insertText(text)
      self.text = text
    }

    return success
  }
}

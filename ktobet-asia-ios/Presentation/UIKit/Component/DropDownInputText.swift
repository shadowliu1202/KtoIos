import RxCocoa
import RxSwift
import UIKit

let ArrowSize: CGFloat = 12
class DropDownInputText: UIView {
    private var firstPosition = true
    private var isEditing = false
    private var isShowing = false
    private var dropDownOffsetOnece = true
    private var didSelectCompletion: (String, Int, String) -> Void = { _, _, _ in }
    var isEdited: Bool {
        isEditing
    }

    var isShowed: Bool {
        isShowing
    }

    var editingChangedHandler: ((String) -> Void)?
    var maxLength = Int32.max
    var numberOnly = false

    private var labTitle = UILabel()
    private var labSubTitle = UILabel()
    private var arrow: Arrow = {
        let arrow = Arrow(origin: CGPoint(x: 0, y: 0), size: ArrowSize)
        arrow.arrowColor = UIColor.textPrimary
        return arrow
    }()

    var dropDownText: DropDown = {
        let mainDropDown = DropDown(frame: .zero)
        mainDropDown.arrowSize = 0
        mainDropDown.rowBackgroundColor = UIColor.greyScaleToast
        mainDropDown.rowTextColor = UIColor.textPrimary
        mainDropDown.selectedRowColor = UIColor.clear
        mainDropDown.checkMarkEnabled = false
        return mainDropDown
    }()

    private var underline = UIView()
    var text: ControlProperty<String> {
        dropDownText.rx.text.orEmpty
    }

    var selectedIndex = BehaviorRelay<Int?>(value: nil)
    var selectedID = BehaviorRelay<String?>(value: nil)

    public var optionArray = [String]() {
        didSet {
            self.dropDownText.optionArray = self.optionArray
        }
    }

    public var optionIds: [String]? {
        didSet {
            self.dropDownText.optionIds = self.optionIds
        }
    }

    @IBInspectable public var isSearchEnable = true {
        didSet {
            dropDownText.isSearchEnable = isSearchEnable
            if !isSearchEnable {
                dropDownText.didDropDownTap = { [weak self] in
                    self?.touchAction()
                }
            }
        }
    }

    @IBInspectable public var arrowSize: CGFloat = ArrowSize {
        didSet {
            self.arrow.frame.size = CGSize(width: arrowSize, height: arrowSize)
        }
    }

    @IBInspectable public var isEnable = true {
        didSet {
            self.isUserInteractionEnabled = isEnable
            self.arrow.arrowColor = isEnable ? UIColor.textPrimary : UIColor.textSecondary
            self.labTitle.textColor = isEnable ? UIColor.textPrimary : UIColor.textSecondary
        }
    }

    @IBInspectable public var isEmptyTip = false {
        didSet {
            self.dropDownText.emptyTip = isEmptyTip
        }
    }

    var arrowSolid: Solid = .linear {
        didSet {
            self.arrow.solid = arrowSolid
        }
    }

    var customizeBackgroundColor: (UIColor, UIColor)?

    // MARK: LIFE CYCLE
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.inputFocus
        if let color = customizeBackgroundColor {
            backgroundColor = color.0
        }
        labTitle.font = UIFont(name: "PingFangSC-Regular", size: 12)
        labTitle.textColor = UIColor.textPrimary
        labTitle.backgroundColor = .clear

        labSubTitle.font = UIFont(name: "PingFangSC-Regular", size: 16)
        labSubTitle.textColor = .white
        labSubTitle.backgroundColor = .clear

        dropDownText.textColor = .white
        dropDownText.backgroundColor = .clear
        dropDownText.font = UIFont(name: "PingFangSC-Regular", size: 16)
        dropDownText.borderStyle = .none
        dropDownText.delegate = self
        dropDownText.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
        dropDownText.didSelect { [weak self] text, index, id in
            self?.dropDownText.text = text
            self?.selectedIndex.accept(index)
            self?.selectedID.accept(id)
            self?.dropDownText.sendActions(for: .valueChanged)
            self?.adjustPosition()
            self?.didSelectCompletion(text, index, id)
        }
        dropDownText.listWillAppear { [weak self] in
            UIView.animate(
                withDuration: 0.5,
                delay: 0.1,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: 0.1,
                options: .curveEaseInOut,
                animations: { () in
                    self?.arrow.position = .up
                },
                completion: { _ in
                    self?.layoutIfNeeded()

                })
        }
        dropDownText.listDidDisappear { [weak self] in
            if let self, !self.isSearchEnable {
                self.isShowing = false
            }
        }

        dropDownText.listWillDisappear { [weak self] in
            if let self, !self.isSearchEnable {
                self.isEditing = false
            }
            UIView.animate(
                withDuration: 0.5,
                delay: 0.1,
                usingSpringWithDamping: 0.9,
                initialSpringVelocity: 0.1,
                options: .curveEaseInOut,
                animations: { () in
                    self?.arrow.position = .down
                },
                completion: { _ in
                    self?.layoutIfNeeded()

                })
        }

        underline.backgroundColor = UIColor.alert
        underline.isHidden = true

        addSubview(labTitle)
        addSubview(labSubTitle)
        addSubview(dropDownText)
        addSubview(underline)
        addSubview(arrow)
    }

    @objc
    public func touchAction() {
        superview?.endEditing(true)
        isEditing = true
        isShowing = true
        adjustPosition()
        dropDownText.showList()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        adjustPosition()
    }

    // MARK: POSITION
    func adjustPosition() {
        var position: (titleFont: UIFont, title: CGRect, subTitle: CGRect, content: CGRect)

        if !isEditing, dropDownText.text?.count == 0 {
            position = emptyPosition()
        }
        else {
            position = editedPosition()
            if self.dropDownOffsetOnece {
                self.dropDownText.ktoOffset = CGRect(
                    origin: CGPoint(x: position.content.origin.x, y: position.content.origin.y),
                    size: CGSize(width: position.content.origin.x, height: self.bounds.height))
                self.dropDownOffsetOnece = false
            }
        }
        self.labSubTitle.frame = position.subTitle
        let changePosition = {
            self.labTitle.font = position.titleFont
            self.labTitle.frame = position.title
            self.dropDownText.frame = position.content
            self.underline.frame = CGRect(x: 0, y: self.bounds.maxY - 1, width: self.bounds.width, height: 1)
            if let color = self.customizeBackgroundColor {
                self.backgroundColor = self.isEditing ? color.0 : color.1
            }
            else {
                self.backgroundColor = self.isEditing ? UIColor.inputFocus : UIColor.inputDefault
            }
        }
        if firstPosition {
            changePosition()
            self.arrow.frame.origin = CGPoint(
                x: self.frame.width - (15 + ArrowSize + 4.5),
                y: self.bounds.maxY / 2 - ArrowSize / 2)
            firstPosition = false
        }
        else {
            UIView.animate(withDuration: 0.2, animations: changePosition, completion: nil)
        }
    }

    private func emptyPosition() -> (titleFont: UIFont, title: CGRect, subTitle: CGRect, content: CGRect) {
        let titleFont = UIFont(name: "PingFangSC-Regular", size: 14)!
        let border: CGFloat = 15
        let title: CGRect = {
            let width: CGFloat = labTitle.text?.width(withConstrainedHeight: bounds.height, font: titleFont) ?? 0
            let height: CGFloat = labTitle.text?.height(withConstrainedWidth: width, font: titleFont) ?? 0
            let x: CGFloat = border
            let y = bounds.midY - height * 0.5
            return CGRect(x: x, y: y, width: width, height: height)
        }()
        let subTitle = CGRect.zero
        let content: CGRect = {
            let width: CGFloat = bounds.width - border * 2
            let height: CGFloat = bounds.height - border * 2
            let x: CGFloat = title.maxX + border
            let y: CGFloat = bounds.midY - height * 0.5
            return CGRect(x: x, y: y, width: width, height: height)
        }()
        return (titleFont, title, subTitle, content)
    }

    private func editedPosition() -> (titleFont: UIFont, title: CGRect, subTitle: CGRect, content: CGRect) {
        let titleFont = UIFont(name: "PingFangSC-Regular", size: 12)!
        let border: CGFloat = 15
        let title: CGRect = {
            let width = labTitle.text?.width(withConstrainedHeight: bounds.height, font: titleFont) ?? 0 + 2
            let height = labTitle.text?.height(withConstrainedWidth: width, font: titleFont) ?? 0
            let x = border
            let y: CGFloat = 8
            return CGRect(x: x, y: y, width: width, height: height)
        }()
        let subTitle: CGRect = {
            guard (labSubTitle.text ?? "").count > 0 else { return CGRect.zero }
            let height = bounds.height - title.maxY - 8 - 8
            let width = labSubTitle.text?.width(withConstrainedHeight: height, font: labSubTitle.font) ?? 0
            let x = border
            let y = title.maxY + 8
            return CGRect(x: x, y: y, width: width, height: height)
        }()
        let content: CGRect = {
            let width = bounds.width - subTitle.maxX - (subTitle.equalTo(CGRect.zero) ? 0 : 8) - border
            let height = bounds.height - title.maxY - 8 - 8
            let x = subTitle.equalTo(CGRect.zero) ? border : subTitle.maxX + 8
            let y = title.maxY + 8
            return CGRect(x: x, y: y, width: width, height: height)
        }()
        return (titleFont, title, subTitle, content)
    }

    // MARK: SETUP UI
    func setTitle(_ title: String) {
        labTitle.text = title
    }

    func setContent(_ content: String) {
        dropDownText.text = content
    }

    func setSubTitle(_ subTitle: String) {
        labSubTitle.text = subTitle
    }

    func setKeyboardType(_ keyboardType: UIKeyboardType) {
        dropDownText.keyboardType = keyboardType
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
        dropDownText.becomeFirstResponder()
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

    func didSelect(completion: @escaping (_ selectedText: String, _ index: Int, _ id: String) -> Void) {
        didSelectCompletion = completion
    }
}

extension DropDownInputText: UITextFieldDelegate {
    func textFieldDidBeginEditing(_: UITextField) {
        isEditing = true
        adjustPosition()
//        if isSearchEnable {
//            dropDownText.textFieldDidBeginEditing(textField)
//        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        let _ = dropDownText.textFieldShouldReturn(textField)
        isEditing = false
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentString: NSString = (textField.text ?? "") as NSString
        if string != "\n" {
            let _ = dropDownText.textField(textField, shouldChangeCharactersIn: range, replacementString: string)
        }
        if numberOnly {
            return isNumber(replacementString: string) && isLessThanLimitLength(
                currentString: currentString,
                shouldChangeCharactersIn: range,
                replacementString: string)
        }
        else {
            return isLessThanLimitLength(currentString: currentString, shouldChangeCharactersIn: range, replacementString: string)
        }
    }

    public func textFieldShouldBeginEditing(_: UITextField) -> Bool {
        isSearchEnable
    }

    private func isNumber(replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: string)
        return allowedCharacters.isSuperset(of: characterSet)
    }

    private func isLessThanLimitLength(
        currentString: NSString,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String)
        -> Bool
    {
        let newString: NSString =
            currentString.replacingCharacters(in: range, with: string) as NSString
        return newString.length <= maxLength
    }
}

extension DropDownInputText {
    override func touchesBegan(_: Set<UITouch>, with _: UIEvent?) {
        if !dropDownText.isFirstResponder, isSearchEnable {
            dropDownText.becomeFirstResponder()
        }
        if !isSearchEnable {
            superview?.endEditing(true)
            touchAction()
        }
    }
}

extension Reactive where Base: DropDownInputText {
    var isEnable: Binder<Bool> {
        Binder<Bool>(base, binding: { dropDownInputText, enable in
            dropDownInputText.isEnable = enable
        })
    }
}

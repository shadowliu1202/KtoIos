//
//  InputTextField.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/12/16.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

protocol InputTextFieldProtocol {
    func shouldHidePassword(_ hide: Bool)
}

class InputTextField : UIView{
    
    private var labTitle = UILabel()
    private var textContent = UITextField()
    private var btnHideContent = UIButton()
    private var underline = UIView()
    private var isFirst = true
    private var isEditing = false
    private var isAnimate = false
    private var cancelAnimate = false
    private var editingChangedHandler : ((String)->Void)?
    var confirmPassword : InputTextFieldProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = UIColor(rgb: 0x454545)
        labTitle.font = UIFont.systemFont(ofSize: 12)
        labTitle.textColor = UIColor(rgb: 0x9b9b9b)
        labTitle.backgroundColor = .clear
        
        textContent.textColor = .white
        textContent.backgroundColor = .clear
        textContent.font = UIFont.systemFont(ofSize: 16)
        textContent.borderStyle = .none
        textContent.delegate = self
        textContent.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
        
        btnHideContent.backgroundColor = .clear
        btnHideContent.setImage(UIImage(named: "Eye-Show"), for: .normal)
        btnHideContent.setImage(UIImage(named: "Eye-Hide"), for: .selected)
        btnHideContent.addTarget(self, action: #selector(btnHidePressed(_:)), for: .touchUpInside)
        btnHideContent.isHidden = true
        
        underline.backgroundColor = UIColor.init(rgb: 0xff8000)
        underline.isHidden = true
        
        addSubview(labTitle)
        addSubview(textContent)
        addSubview(btnHideContent)
        addSubview(underline)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var position : (title: CGRect, hideBtn: CGRect, content: CGRect)
        var start = false
        
        if !isEditing && textContent.text?.count == 0{
            position = startPosition()
            start = true
        } else {
            position = endPosition()
            start = false
        }
        
        let positionChange : ()->Void = {
            self.labTitle.font = UIFont.systemFont(ofSize: start ? 14 : 12)
            self.labTitle.frame = position.title
            self.textContent.frame = position.content
            self.btnHideContent.frame = position.hideBtn
            self.underline.frame = CGRect(x: 0, y: self.bounds.maxY - 1, width: self.bounds.width, height: 1)
            self.backgroundColor = UIColor.init(rgb: start ? 0x333333 : 0x454545)
        }
        
        if isFirst{
            positionChange()
            isFirst = false
        } else {
            if (!labTitle.frame.equalTo(position.title) ||
                !textContent.frame.equalTo(position.content) ||
                !btnHideContent.frame.equalTo(position.hideBtn)) &&
                !isAnimate{
                isAnimate = true
                if cancelAnimate{
                    isAnimate = false
                    cancelAnimate = false
                    positionChange()
                } else {
                    UIView.animate(withDuration: 0.2, animations: positionChange) { (complete) in
                        self.isAnimate = false
                    }
                }

            }
        }
    }
    
    private func startPosition()->(title: CGRect, hideBtn: CGRect, content: CGRect){
        let border : CGFloat = 15
        let title : CGRect = {
            let font = UIFont.systemFont(ofSize: 14)
            let width : CGFloat = labTitle.text?.width(withConstrainedHeight: bounds.height, font: font) ?? 0
            let height : CGFloat = labTitle.text?.height(withConstrainedWidth: width, font: font) ?? 0
            let x : CGFloat = border
            let y = bounds.midY - height * 0.5
            return CGRect(x: x, y: y, width: width, height: height)
        }()
        let hideButton : CGRect = {
            let width : CGFloat = 24
            let height : CGFloat = 24
            let x : CGFloat = bounds.width - border - width
            let y : CGFloat = bounds.midY - height * 0.5
            return CGRect(x: x, y: y, width: width, height: height)
        }()
        let content : CGRect = {
            let width : CGFloat = bounds.width - title.maxX - hideButton.width - border * 3
            let height : CGFloat = bounds.height - border * 2
            let x : CGFloat = title.maxX + border
            let y : CGFloat = bounds.midY - height * 0.5
            return CGRect(x: x, y: y, width: width, height: height)
        }()
        return (title, hideButton, content)
    }
    
    private func endPosition()->(title: CGRect, hideBtn: CGRect, content: CGRect){
        let border : CGFloat = 15
        let title : CGRect = {
            let font = UIFont.systemFont(ofSize: 12)
            let width = labTitle.text?.width(withConstrainedHeight: bounds.height, font: font) ?? 0
            let height = labTitle.text?.height(withConstrainedWidth: width, font: font) ?? 0
            let x = border
            let y : CGFloat = 8
            return CGRect(x: x, y: y, width: width, height: height)
        }()
        let hideButton : CGRect = {
            let width : CGFloat = 24
            let height : CGFloat = 24
            let x : CGFloat = bounds.width - border - width
            let y : CGFloat = bounds.midY - height * 0.5
            return CGRect(x: x, y: y, width: width, height: height)
        }()
        let content : CGRect = {
            let width = bounds.width - hideButton.width - border * 3
            let height = bounds.height - title.maxY - 8 - 8
            let x = border
            let y = title.maxY + 8
            return CGRect(x: x, y: y, width: width, height: height)
        }()
        return (title, hideButton, content)
    }
    
    // MARK: EVENT
    @objc private func textFieldEditingChanged(_ textField : UITextField){
        if self.editingChangedHandler != nil {
            self.editingChangedHandler!(textField.text ?? "")
        }
    }
    
    @objc private func btnHidePressed(_ sender : UIButton){
        btnHideContent.isSelected = !btnHideContent.isSelected
        textContent.isSecureTextEntry = btnHideContent.isSelected
        confirmPassword?.shouldHidePassword(btnHideContent.isSelected)
    }
    
    // MARK: SETUP
    func setTitle(_ title: String){
        labTitle.text = title
        cancelAnimate = true
        layoutSubviews()
    }
    
    func setContent(_ content : String){
        textContent.text = content
        textFieldEditingChanged(textContent)
    }
    
    func setEditingChangedHandler(_ editingChangedHandler : ((String)->Void)?){
        self.editingChangedHandler = editingChangedHandler
    }
    
    func setKeyboardType(_ keyboardType : UIKeyboardType){
        textContent.keyboardType = keyboardType
        if textContent.isFirstResponder{
            textContent.resignFirstResponder()
            textContent.becomeFirstResponder()
        }
    }
    
    func isPassword(){
        btnHideContent.isSelected = true
        btnHideContent.isHidden = false
        textContent.isSecureTextEntry = true
        layoutSubviews()
    }
    
    func isConfirmPassword(){
        btnHideContent.isSelected = true
        btnHideContent.isHidden = true
        textContent.isSecureTextEntry = true
        layoutSubviews()
    }
    
    func setCorner(topCorner : Bool, bottomCorner : Bool){
        layer.masksToBounds = true
        layer.cornerRadius = 8
        if topCorner && bottomCorner{
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if topCorner {
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if bottomCorner{
            layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
    }
    
    func showUnderline(_ show : Bool){
        underline.isHidden = !show
    }
}

extension InputTextField: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        isEditing = true
        layoutSubviews()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        isEditing = false
        layoutSubviews()
    }
}

extension InputTextField : InputTextFieldProtocol{
    func shouldHidePassword(_ hide: Bool){
        btnHideContent.isSelected = hide
        textContent.isSecureTextEntry = btnHideContent.isSelected
    }
}

extension InputTextField {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !textContent.isFirstResponder{
            textContent.becomeFirstResponder()
        }
    }
}

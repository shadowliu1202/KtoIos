
import UIKit

extension UILabel {
    @objc var substituteFontFamilyName : String {
        get {
            return self.font.fontName
        }
        set {
            let fontName: String
            let fontNameToConvert = self.font.fontName.lowercased()
            
            if isCNFontFamilyName(self.font.fontName) && isVNFontFamilyName(newValue) {
                fontName = toVNFontName(familyName: newValue, fontNameToConvert)
            } else if isVNFontFamilyName(self.font.fontName) && isCNFontFamilyName(newValue) {
                fontName = toCNFontName(familyName: newValue, fontNameToConvert)
            } else if isSystemDefaultFont(self.font.fontName){
                fontName = toLocaleFontName(familyName: newValue, self.font.fontName)
            } else {
                fontName = self.font.fontName
            }
            
            self.font = UIFont(name: fontName, size: self.font.pointSize)
        }
    }
    
    private func isCNFontFamilyName(_ fontName: String) -> Bool {
        if fontName.range(of: "PingFangSC") != nil {
            return true
        } else {
            return false
        }
    }
    
    private func isVNFontFamilyName(_ fontName: String) -> Bool {
        if fontName.range(of: "HelveticaNeue") != nil {
            return true
        } else {
            return false
        }
    }
    
    private func isSystemDefaultFont(_ fontName: String) -> Bool {
        if fontName.range(of: ".SFUI") != nil {
            return true
        } else {
            return false
        }
    }
    
    private func toCNFontName(familyName: String, _ fontNameToConvert: String) -> String {
        var fontName = familyName
        if fontNameToConvert.range(of: "light") != nil {
            fontName += "-Regular"
        } else if fontNameToConvert.range(of: "bold") != nil {
            fontName += "-Semibold"
        } else if fontNameToConvert.range(of: "medium") != nil {
            fontName += "-Medium"
        }
        
        return fontName
    }
    
    private func toVNFontName(familyName: String, _ fontNameToConvert: String) -> String {
        var fontName = familyName
        if fontNameToConvert.range(of: "medium") != nil {
            fontName += "-Medium"
        } else if fontNameToConvert.range(of: "regular") != nil {
            fontName += "-Light"
        } else if fontNameToConvert.range(of: "semibold") != nil {
            fontName += "-Bold"
        }
        
        return fontName
    }
    
    private func toLocaleFontName(familyName: String, _ fontNameToConvert: String) -> String {
        var fontName = familyName
        if isCNFontFamilyName(familyName) {
            fontName = systemFontToCNFontName(familyName: familyName, fontNameToConvert.lowercased())
        } else if isVNFontFamilyName(familyName) {
            fontName = systemFontToVNFontName(familyName: familyName, fontNameToConvert.lowercased())
        } else {
            fontName = fontNameToConvert
        }
        
        return fontName
    }
    
    private func systemFontToCNFontName(familyName: String, _ fontNameToConvert: String) -> String {
        var fontName = familyName
        if fontNameToConvert.range(of: "semibold") != nil {
            fontName += "-Medium"
        } else if fontNameToConvert.range(of: "regular") != nil {
            fontName += "Regular"
        } else if fontNameToConvert.range(of: "bold") != nil {
            fontName += "-Semibold"
        }
        
        return fontName
    }
    
    private func systemFontToVNFontName(familyName: String, _ fontNameToConvert: String) -> String {
        var fontName = familyName
        if fontNameToConvert.range(of: "semibold") != nil {
            fontName += "-Medium"
        } else if fontNameToConvert.range(of: "regular") != nil {
            fontName += "-Light"
        } else if fontNameToConvert.range(of: "bold") != nil {
            fontName += "-Bold"
        }
        
        return fontName
    }
}

extension UITextView {
    @objc var substituteFontFamilyName : String {
        get {
            return self.font?.fontName ?? ""
        }
        set {
            if let font = self.font {
                let fontName: String
                let fontNameToConvert = font.fontName.lowercased()
                
                if isCNFontFamilyName(font.fontName) && isVNFontFamilyName(newValue) {
                    fontName = toVNFontName(familyName: newValue, fontNameToConvert)
                } else if isVNFontFamilyName(font.fontName) && isCNFontFamilyName(newValue) {
                    fontName = toCNFontName(familyName: newValue, fontNameToConvert)
                } else if isSystemDefaultFont(font.fontName){
                    fontName = toLocaleFontName(familyName: newValue, font.fontName)
                } else {
                    fontName = font.fontName
                }
                
                self.font = UIFont(name: fontName, size: font.pointSize)
            }
        }
    }
    
    private func isCNFontFamilyName(_ fontName: String) -> Bool {
        if fontName.range(of: "PingFangSC") != nil {
            return true
        } else {
            return false
        }
    }
    
    private func isVNFontFamilyName(_ fontName: String) -> Bool {
        if fontName.range(of: "HelveticaNeue") != nil {
            return true
        } else {
            return false
        }
    }
    
    private func isSystemDefaultFont(_ fontName: String) -> Bool {
        if fontName.range(of: ".SFUI") != nil {
            return true
        } else {
            return false
        }
    }
    
    private func toCNFontName(familyName: String, _ fontNameToConvert: String) -> String {
        var fontName = familyName
        if fontNameToConvert.range(of: "light") != nil {
            fontName += "-Regular"
        } else if fontNameToConvert.range(of: "bold") != nil {
            fontName += "-Semibold"
        } else if fontNameToConvert.range(of: "medium") != nil {
            fontName += "-Medium"
        }
        
        return fontName
    }
    
    private func toVNFontName(familyName: String, _ fontNameToConvert: String) -> String {
        var fontName = familyName
        if fontNameToConvert.range(of: "medium") != nil {
            fontName += "-Medium"
        } else if fontNameToConvert.range(of: "regular") != nil {
            fontName += "-Light"
        } else if fontNameToConvert.range(of: "semibold") != nil {
            fontName += "-Bold"
        }
        
        return fontName
    }
    
    private func toLocaleFontName(familyName: String, _ fontNameToConvert: String) -> String {
        var fontName = familyName
        if isCNFontFamilyName(familyName) {
            fontName = systemFontToCNFontName(familyName: familyName, fontNameToConvert.lowercased())
        } else if isVNFontFamilyName(familyName) {
            fontName = systemFontToVNFontName(familyName: familyName, fontNameToConvert.lowercased())
        } else {
            fontName = fontNameToConvert
        }
        
        return fontName
    }
    
    private func systemFontToCNFontName(familyName: String, _ fontNameToConvert: String) -> String {
        var fontName = familyName
        if fontNameToConvert.range(of: "semibold") != nil {
            fontName += "-Medium"
        } else if fontNameToConvert.range(of: "regular") != nil {
            fontName += "Regular"
        } else if fontNameToConvert.range(of: "bold") != nil {
            fontName += "-Semibold"
        }
        
        return fontName
    }
    
    private func systemFontToVNFontName(familyName: String, _ fontNameToConvert: String) -> String {
        var fontName = familyName
        if fontNameToConvert.range(of: "semibold") != nil {
            fontName += "-Medium"
        } else if fontNameToConvert.range(of: "regular") != nil {
            fontName += "-Light"
        } else if fontNameToConvert.range(of: "bold") != nil {
            fontName += "-Bold"
        }
        
        return fontName
    }
}

extension UITextField {
    @objc var substituteFontFamilyName : String {
        get {
            return self.font?.fontName ?? "";
        }
        set {
            if let font = self.font {
                let fontName: String
                let fontNameToConvert = font.fontName.lowercased()
                
                if isCNFontFamilyName(font.fontName) && isVNFontFamilyName(newValue) {
                    fontName = toVNFontName(familyName: newValue, fontNameToConvert)
                } else if isVNFontFamilyName(font.fontName) && isCNFontFamilyName(newValue) {
                    fontName = toCNFontName(familyName: newValue, fontNameToConvert)
                } else if isSystemDefaultFont(font.fontName){
                    fontName = toLocaleFontName(familyName: newValue, font.fontName)
                } else {
                    fontName = font.fontName
                }
                
                self.font = UIFont(name: fontName, size: font.pointSize)
            }
        }
    }
    
    private func isCNFontFamilyName(_ fontName: String) -> Bool {
        if fontName.range(of: "PingFangSC") != nil {
            return true
        } else {
            return false
        }
    }
    
    private func isVNFontFamilyName(_ fontName: String) -> Bool {
        if fontName.range(of: "HelveticaNeue") != nil {
            return true
        } else {
            return false
        }
    }
    
    private func isSystemDefaultFont(_ fontName: String) -> Bool {
        if fontName.range(of: ".SFUI") != nil {
            return true
        } else {
            return false
        }
    }
    
    private func toCNFontName(familyName: String, _ fontNameToConvert: String) -> String {
        var fontName = familyName
        if fontNameToConvert.range(of: "light") != nil {
            fontName += "-Regular"
        } else if fontNameToConvert.range(of: "bold") != nil {
            fontName += "-Semibold"
        } else if fontNameToConvert.range(of: "medium") != nil {
            fontName += "-Medium"
        }
        
        return fontName
    }
    
    private func toVNFontName(familyName: String, _ fontNameToConvert: String) -> String {
        var fontName = familyName
        if fontNameToConvert.range(of: "medium") != nil {
            fontName += "-Medium"
        } else if fontNameToConvert.range(of: "regular") != nil {
            fontName += "-Light"
        } else if fontNameToConvert.range(of: "semibold") != nil {
            fontName += "-Bold"
        }
        
        return fontName
    }
    
    private func toLocaleFontName(familyName: String, _ fontNameToConvert: String) -> String {
        var fontName = familyName
        if isCNFontFamilyName(familyName) {
            fontName = systemFontToCNFontName(familyName: familyName, fontNameToConvert.lowercased())
        } else if isVNFontFamilyName(familyName) {
            fontName = systemFontToVNFontName(familyName: familyName, fontNameToConvert.lowercased())
        } else {
            fontName = fontNameToConvert
        }
        
        return fontName
    }
    
    private func systemFontToCNFontName(familyName: String, _ fontNameToConvert: String) -> String {
        var fontName = familyName
        if fontNameToConvert.range(of: "semibold") != nil {
            fontName += "-Medium"
        } else if fontNameToConvert.range(of: "regular") != nil {
            fontName += "Regular"
        } else if fontNameToConvert.range(of: "bold") != nil {
            fontName += "-Semibold"
        }
        
        return fontName
    }
    
    private func systemFontToVNFontName(familyName: String, _ fontNameToConvert: String) -> String {
        var fontName = familyName
        if fontNameToConvert.range(of: "semibold") != nil {
            fontName += "-Medium"
        } else if fontNameToConvert.range(of: "regular") != nil {
            fontName += "-Light"
        } else if fontNameToConvert.range(of: "bold") != nil {
            fontName += "-Bold"
        }
        
        return fontName
    }
}

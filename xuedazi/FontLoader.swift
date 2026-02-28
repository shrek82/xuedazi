import SwiftUI
import AppKit
import CoreText

class FontLoader {
    static let shared = FontLoader()
    var registeredFontName: String?
    var registeredChineseFontName: String?
    var registeredInputFontName: String?
    var registeredFredokaFontName: String?

    func registerFont() {
        // 注册拼音字体
        if let fontURL = Bundle.main.url(forResource: "tssqApdaRQokwFjFJjvM6h2moYbyg3tS2w", withExtension: "woff2") {
            _ = registerFont(at: fontURL, nameStore: &self.registeredFontName)
        }
        
        // 注册中文字体 (ZCOOL 快乐体)
        if let fontURL = Bundle.main.url(forResource: "ZCOOLKuaiLe-Regular", withExtension: "ttf") {
            _ = registerFont(at: fontURL, nameStore: &self.registeredChineseFontName)
        }

        // 注册输入框字体 (font2)
        if let fontURL = Bundle.main.url(forResource: "font2", withExtension: "woff2") {
            _ = registerFont(at: fontURL, nameStore: &self.registeredInputFontName)
        }

        // 注册 Fredoka 字体
        if let fontURL = Bundle.main.url(forResource: "Fredoka", withExtension: "ttf") {
            _ = registerFont(at: fontURL, nameStore: &self.registeredFredokaFontName)
        }
    }
    
    private func registerFont(at fontURL: URL, nameStore: inout String?) -> Bool {
        var error: Unmanaged<CFError>?
        if CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
            if let fontData = try? Data(contentsOf: fontURL),
               let dataProvider = CGDataProvider(data: fontData as CFData),
               let cgFont = CGFont(dataProvider) {
                nameStore = cgFont.postScriptName as String?
                return true
            }
        }
        return false
    }
    
    func pinyinFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let name = registeredFredokaFontName {
            return .custom(name, size: size).weight(weight)
        }
        if let name = registeredFontName {
            if weight != .regular, let nsFont = NSFont(name: name, size: size) {
                let boldFont = NSFontManager.shared.convert(nsFont, toHaveTrait: .boldFontMask)
                return Font(boldFont as CTFont)
            }
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight, design: .rounded)
    }
    
    func chineseFont(size: CGFloat) -> Font {
        if let name = registeredChineseFontName {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: .black, design: .rounded)
    }

    func inputFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let name = registeredFredokaFontName {
            return .custom(name, size: size).weight(weight)
        }
        if let name = registeredInputFontName {
            if weight != .regular, let nsFont = NSFont(name: name, size: size) {
                let boldFont = NSFontManager.shared.convert(nsFont, toHaveTrait: .boldFontMask)
                return Font(boldFont as CTFont)
            }
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight, design: .rounded)
    }
}

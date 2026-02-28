//
//  Color+Theme.swift
//  xuedazi
//
//  Created by up on 2026/2/12.
//

import SwiftUI

extension Color {
    static let themeBgSky50 = Color(red: 0.08, green: 0.09, blue: 0.10)
    static let themeSkyBlue = Color(red: 0.2, green: 0.7, blue: 1.0)
    static let themeAmberYellow = Color(red: 1.0, green: 0.75, blue: 0.2)
    static let themeMintGreen = Color(red: 0.4, green: 0.9, blue: 0.7) // 新增
    static let themeCoralPink = Color(red: 1.0, green: 0.6, blue: 0.6) // 新增
    static let themeGreen100 = Color(red: 0.86, green: 1.0, blue: 0.86)
    static let themeYellow50 = Color(red: 1.0, green: 1.0, blue: 0.9)
    static let themeSuccessGreen = Color(red: 0.3, green: 0.8, blue: 0.4)
    static let themeKeyboardBg = Color(red: 0.14, green: 0.16, blue: 0.20)
    
    static let fingerPink = Color(red: 0.9, green: 0.4, blue: 0.5)
    static let fingerOrange = Color(red: 0.9, green: 0.5, blue: 0.2)
    static let fingerYellow = Color(red: 0.8, green: 0.7, blue: 0.0)
    static let fingerGreen = Color(red: 0.3, green: 0.7, blue: 0.4)
    
    func darker(by amount: CGFloat = 0.2) -> Color {
        let nsColor = NSColor(self)
        guard let convertedColor = nsColor.usingColorSpace(.deviceRGB) else {
            return self
        }
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        convertedColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return Color(nsColor: NSColor(hue: hue, saturation: saturation, brightness: max(brightness - amount, 0), alpha: alpha))
    }
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

//
//  KeyboardView.swift
//  xuedazi
//
//  Created by up on 2026/2/12.
//

import SwiftUI

struct KeyboardView: View, Equatable {
    let lastPressedKey: String?
    let lastWrongKey: String?
    let hintKey: String?
    let pressTrigger: Int
    let currentFingerType: String?
    let accentColor: Color
    
    // Implement Equatable manually to ensure efficient diffing
    static func == (lhs: KeyboardView, rhs: KeyboardView) -> Bool {
        return lhs.lastPressedKey == rhs.lastPressedKey &&
               lhs.lastWrongKey == rhs.lastWrongKey &&
               lhs.hintKey == rhs.hintKey &&
               lhs.pressTrigger == rhs.pressTrigger &&
               lhs.currentFingerType == rhs.currentFingerType &&
               lhs.accentColor == rhs.accentColor
    }
    
    let rows = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"]
    ]
    
    private func fingerColor(for key: String) -> Color {
        switch key {
        case "q", "a", "z", "p": return Color(red: 0.9, green: 0.4, blue: 0.5)
        case "w", "s", "x", "o", "l": return Color(red: 0.9, green: 0.5, blue: 0.2)
        case "e", "d", "c", "i", "k": return Color(red: 0.8, green: 0.7, blue: 0.0)
        default: return Color(red: 0.3, green: 0.7, blue: 0.4)
        }
    }
    
    private func fingerName(for key: String) -> String {
        switch key {
        case "q", "a", "z": return "左小"
        case "p": return "右小"
        case "w", "s", "x": return "左无"
        case "o", "l": return "右无"
        case "e", "d", "c": return "左中"
        case "i", "k": return "右中"
        case "r", "f", "v", "t", "g", "b": return "左食"
        case "y", "h", "n", "u", "j", "m": return "右食"
        default: return ""
        }
    }
    
    var body: some View {
        HStack(spacing: 20) {
            LeftHandView(currentFingerType: currentFingerType, hintKey: hintKey)
                .frame(height: 260)
            
            VStack(spacing: 6) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(row, id: \.self) { key in
                            let isPressed = lastPressedKey == key
                            let isWrongKey = lastWrongKey == key
                            let isHint = hintKey == key
                            let color = fingerColor(for: key)
                            let name = fingerName(for: key)
                            
                            KeyView(
                                key: key,
                                isHighlighted: isPressed,
                                isWrong: isWrongKey,
                                isHint: isHint,
                                accentColor: accentColor,
                                fingerHint: isHint ? name : "",
                                keyColor: color,
                                triggerValue: pressTrigger
                            )
                            .equatable() // Optimization: Skip redraw for unchanged keys
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(
                                        key: KeyPositionPreferenceKey.self,
                                        value: [key: geo.frame(in: .named("LetterGameSpace"))]
                                    )
                                }
                            )
                        }
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.themeKeyboardBg)
                    .shadow(color: .black.opacity(0.6), radius: 25, x: 0, y: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(.white.opacity(0.06), lineWidth: 2)
                    )
            )
            
            RightHandView(currentFingerType: currentFingerType, hintKey: hintKey)
                .frame(height: 260)
        }
    }
}

struct LeftHandView: View {
    let currentFingerType: String?
    let hintKey: String?
    
    private let pink = Color(red: 0.9, green: 0.4, blue: 0.5)
    private let orange = Color(red: 0.9, green: 0.5, blue: 0.2)
    private let yellow = Color(red: 0.8, green: 0.7, blue: 0.0)
    private let green = Color(red: 0.3, green: 0.7, blue: 0.4)
    
    var body: some View {
        HStack(spacing: 10) {
            FingerShape(isActive: currentFingerType == "左-小指", color: pink, height: 100, letter: currentFingerType == "左-小指" ? hintKey : nil)
            FingerShape(isActive: currentFingerType == "左-无名指", color: orange, height: 125, letter: currentFingerType == "左-无名指" ? hintKey : nil)
            FingerShape(isActive: currentFingerType == "左-中指", color: yellow, height: 145, letter: currentFingerType == "左-中指" ? hintKey : nil)
            FingerShape(isActive: currentFingerType == "左-食指", color: green, height: 125, letter: currentFingerType == "左-食指" ? hintKey : nil)
        }
    }
}

struct RightHandView: View {
    let currentFingerType: String?
    let hintKey: String?
    
    private let pink = Color(red: 0.9, green: 0.4, blue: 0.5)
    private let orange = Color(red: 0.9, green: 0.5, blue: 0.2)
    private let yellow = Color(red: 0.8, green: 0.7, blue: 0.0)
    private let green = Color(red: 0.3, green: 0.7, blue: 0.4)
    
    var body: some View {
        HStack(spacing: 10) {
            FingerShape(isActive: currentFingerType == "右-食指", color: green, height: 125, letter: currentFingerType == "右-食指" ? hintKey : nil)
            FingerShape(isActive: currentFingerType == "右-中指", color: yellow, height: 145, letter: currentFingerType == "右-中指" ? hintKey : nil)
            FingerShape(isActive: currentFingerType == "右-无名指", color: orange, height: 125, letter: currentFingerType == "右-无名指" ? hintKey : nil)
            FingerShape(isActive: currentFingerType == "右-小指", color: pink, height: 100, letter: currentFingerType == "右-小指" ? hintKey : nil)
        }
    }
}

struct FingerShape: View {
    let isActive: Bool
    let color: Color
    let height: CGFloat
    let letter: String?
    
    @State private var scale: CGFloat = 1.0
    @State private var glowRadius: CGFloat = 8
    @State private var bounce: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isActive ? color : color.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .shadow(color: isActive ? color.opacity(0.8) : .clear, radius: glowRadius)
                
                if isActive, let letter = letter {
                    Text(letter.uppercased())
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: isActive ? [color, color.opacity(0.6)] : [color.opacity(0.15), color.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 28, height: height)
                .shadow(color: isActive ? color.opacity(0.7) : .clear, radius: glowRadius)
        }
        .scaleEffect(isActive ? scale : 1.0)
        .offset(y: isActive ? bounce : 0)
        .id("\(isActive)")
        .onAppear {
            if isActive {
                startAnimations()
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startAnimations()
            }
        }
    }
    
    private func startAnimations() {
        scale = 1.0
        glowRadius = 8
        bounce = 0
        
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            scale = 1.12
        }
        
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            glowRadius = 16
        }
        
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            bounce = -6
        }
    }
}

struct FingerLabel: View {
    let text: String
    let color: Color
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isActive ? color : .gray.opacity(0.3))
                .frame(width: 12, height: 12)
            
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(isActive ? .white.opacity(0.9) : .white.opacity(0.3))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isActive ? .white.opacity(0.1) : .white.opacity(0.03))
        )
    }
}

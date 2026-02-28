//
//  GameStatsViews.swift
//  xuedazi
//
//  Created by up on 2026/2/22.
//

import SwiftUI

// MARK: - Animated Rolling Text
struct RollingText: View {
    var value: Double
    var font: Font = .system(size: 20, weight: .bold, design: .rounded)
    var color: Color = .primary
    var format: String = "%.0f"
    
    var body: some View {
        Text(String(format: format, value))
            .font(font)
            .foregroundColor(color)
            .modifier(AnimatableNumberModifier(number: value, format: format, font: font, color: color))
            .animation(.interpolatingSpring(stiffness: 50, damping: 10), value: value)
    }
}

struct AnimatableNumberModifier: AnimatableModifier {
    var number: Double
    var format: String
    var font: Font
    var color: Color
    
    var animatableData: Double {
        get { number }
        set { number = newValue }
    }
    
    func body(content: Content) -> some View {
        Text(String(format: format, number))
            .font(font)
            .foregroundColor(color)
            // Fix for layout jitter: ensure monospaced digits if possible, or fixed frame
            .monospacedDigit() 
    }
}

// MARK: - Score Display
struct ScoreDisplay: View {
    let score: Int
    
    @State private var scale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.0
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.themeSkyBlue)
            
            Text("分数")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.themeSkyBlue.opacity(0.9))
            
            RollingText(
                value: Double(score),
                font: .system(size: 20, weight: .bold, design: .rounded),
                color: .themeSkyBlue
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(Color.themeSkyBlue.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(scale)
        .shadow(color: .themeSkyBlue.opacity(glowOpacity), radius: 8, x: 0, y: 0)
        .onChange(of: score) { oldValue, newValue in
            guard newValue > oldValue else { return }
            
            // Trigger animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                scale = 1.2
                glowOpacity = 0.8
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                    glowOpacity = 0.0
                }
            }
        }
    }
}

// MARK: - Money Display
struct MoneyDisplay: View {
    let amount: Double
    let change: Double
    
    @State private var scale: CGFloat = 1.0
    @State private var changeOpacity: Double = 0.0
    @State private var changeOffset: CGFloat = 0
    @State private var displayChange: Double = 0.0 // Store the change value for display
    
    var body: some View {
        ZStack {
            // Main Display
            HStack(spacing: 4) {
                Image(systemName: "centsign.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeAmberYellow)
                
                Text("金币")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.themeAmberYellow.opacity(0.9))
                
                RollingText(
                    value: amount,
                    font: .system(size: 20, weight: .bold, design: .rounded),
                    color: .themeAmberYellow,
                    format: "%.3f" // 增加小数位精度，从 2 位到 3 位
                )
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(Color.themeAmberYellow.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(scale)
            
            // Flying Change Text
            if changeOpacity > 0 {
                Text(displayChange > 0 ? "+\(String(format: "%.3f", displayChange))" : "\(String(format: "%.3f", displayChange))") // 增加小数位精度
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(displayChange > 0 ? .green : .red)
                    .shadow(color: .black.opacity(0.5), radius: 1)
                    .opacity(changeOpacity)
                    .offset(y: changeOffset)
                    .padding(.leading, 40) // Offset to not overlap too much
            }
        }
        .onChange(of: amount) { _, _ in
             // Use amount change to trigger scale, change value is passed separately but likely synced
        }
        .onChange(of: change) { _, newValue in
            guard newValue != 0 else { return }
            
            // Update display value immediately
            displayChange = newValue
            
            // Scale effect
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.2
            }
            
            // Fly up effect - Reset first
            changeOffset = 0
            changeOpacity = 1.0
            
            withAnimation(.easeOut(duration: 0.8)) {
                changeOffset = -40
                changeOpacity = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
        }
    }
}

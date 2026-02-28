//
//  ComboEvaluationView.swift
//  xuedazi
//
//  Created by up on 2026/2/22.
//

import SwiftUI

struct ComboEvaluationView: View {
    let comboCount: Int
    
    @State private var showEffect: Bool = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    @State private var rotation: Double = 0.0
    @State private var currentText: String = ""
    @State private var currentColor: Color = .white
    
    var body: some View {
        ZStack {
            if showEffect {
                Text(currentText)
                    .font(.system(size: 60, weight: .heavy, design: .rounded))
                    .foregroundStyle(currentColor)
                    .shadow(color: currentColor.opacity(0.8), radius: 10, x: 0, y: 0)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                    .opacity(opacity)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: comboCount) { oldValue, newValue in
            if newValue > oldValue {
                checkComboThreshold(newValue)
            }
        }
    }
    
    private func checkComboThreshold(_ count: Int) {
        let (text, color) = getComboEvaluation(count)
        
        guard !text.isEmpty else { return }
        
        // Reset state
        currentText = text
        currentColor = color
        scale = 0.5
        opacity = 0.0
        rotation = Double.random(in: -15...15)
        showEffect = true
        
        // Animate in
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            scale = 1.2
            opacity = 1.0
            rotation = 0
        }
        
        // Play sound
        if count >= 10 {
            SoundManager.shared.playGetBigMoney()
        }
        
        // Animate out
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 0.0
                scale = 1.5
            }
        }
        
        // Cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            showEffect = false
        }
    }
    
    private func getComboEvaluation(_ count: Int) -> (String, Color) {
        switch count {
        case 5: return ("不错哦!", .green)
        case 10: return ("太棒了!", .blue)
        case 20: return ("超级棒!", .purple)
        case 30: return ("完美!", .orange)
        case 40: return ("惊人!", .red)
        case 50: return ("势不可挡!", .yellow)
        case 80: return ("超神了!", .white)
        case 100: return ("传说!", .cyan)
        default:
            if count > 100 && count % 50 == 0 {
                return ("\(count) 连击!", .themeSuccessGreen)
            }
            return ("", .clear)
        }
    }
}

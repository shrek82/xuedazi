//
//  KeyView.swift
//  xuedazi
//
//  Created by up on 2026/2/12.
//

import SwiftUI

struct KeyView: View, Equatable {
    let key: String
    let isHighlighted: Bool
    let isWrong: Bool
    let isHint: Bool
    let accentColor: Color
    let fingerHint: String
    let keyColor: Color
    let triggerValue: Int
    
    static func == (lhs: KeyView, rhs: KeyView) -> Bool {
        // If both are inactive (not highlighted and not wrong), ignore triggerValue change
        // This prevents redrawing the entire keyboard when pressTrigger changes
        let lhsActive = lhs.isHighlighted || lhs.isWrong
        let rhsActive = rhs.isHighlighted || rhs.isWrong
        
        if !lhsActive && !rhsActive {
            return lhs.key == rhs.key &&
                   lhs.isHint == rhs.isHint &&
                   lhs.accentColor == rhs.accentColor &&
                   lhs.fingerHint == rhs.fingerHint &&
                   lhs.keyColor == rhs.keyColor
        }
        
        return lhs.key == rhs.key &&
               lhs.isHighlighted == rhs.isHighlighted &&
               lhs.isWrong == rhs.isWrong &&
               lhs.isHint == rhs.isHint &&
               lhs.accentColor == rhs.accentColor &&
               lhs.fingerHint == rhs.fingerHint &&
               lhs.keyColor == rhs.keyColor &&
               lhs.triggerValue == rhs.triggerValue
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isWrong ? .red.darker() :
                        (isHighlighted ? accentColor.darker() :
                        keyColor.darker(by: 0.1))
                    )
                    .offset(y: 5)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isWrong ? .red :
                        (isHighlighted ? accentColor :
                        keyColor)
                    )
                    .offset(y: (isHighlighted || isWrong) ? 2 : 0)
                
                VStack(spacing: 0) {
                    Text(key.uppercased())
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                    
                    if !fingerHint.isEmpty {
                        Text(fingerHint)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.top, -2)
                    }
                }
                .foregroundColor(
                    (isWrong || isHighlighted) ? .white :
                    isHint ? .red :
                    .white.opacity(0.95)
                )
                .offset(y: (isHighlighted || isWrong) ? 2 : 0)
            }
        }
        .frame(width: 42, height: 46)
        .scaleEffect((isHighlighted || isWrong) ? 0.96 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isHighlighted)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isWrong)
        .overlay(
            Group {
                if isHighlighted {
                    KeyPressEffect(color: accentColor)
                } else if isWrong {
                    KeyPressEffect(color: .red)
                }
            }
            .id(triggerValue)
        )
    }
}

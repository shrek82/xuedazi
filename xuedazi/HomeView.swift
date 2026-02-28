//
//  HomeView.swift
//  xuedazi
//
//  Created by up on 2026/2/12.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showSettings: Bool
    
    var body: some View {
        ZStack {
            // 背景装饰（可选，增加氛围）
            Color.clear // 占位，保持原有背景
            
            // 右上角设置按钮 (已移除，通过菜单 Game -> Settings 访问)
            /*
            VStack {
                HStack {
                    Spacer()
                    
                    // 设置按钮
                    Button {
                        withAnimation(.spring()) {
                            showSettings = true
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.themeSkyBlue)
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(30)
                    .help("设置")
                }
                
                Spacer()
            }
            */
            // .zIndex(10) // 确保在最上层
            
            VStack(spacing: 40) {
                VStack(spacing: 15) {
                    Text("拼音大冒险")
                        .font(FontLoader.shared.chineseFont(size: 80).weight(.black))
                        .foregroundColor(.themeSkyBlue)
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 6)
                        .onTapGesture {
                            NSApplication.shared.windows.first?.toggleFullScreen(nil)
                        }
                        .onHover { isHovered in
                            if isHovered {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    
                    Text("学习打字，认识汉字！")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 40)
                .padding(.horizontal, 40)
                
                let columns = [GridItem(.adaptive(minimum: 220), spacing: 30)]
                
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 30) {
                        ForEach(Array(Difficulty.allCases.enumerated()), id: \.element) { index, difficulty in
                            // Calculate shortcut
                            let shortcutChars = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "["]
                            let shortcutKey: KeyEquivalent? = index < shortcutChars.count ? KeyEquivalent(Character(shortcutChars[index])) : nil
                            let shortcutLabel: String? = index < shortcutChars.count ? "⌘\(shortcutChars[index])" : nil
                            
                            DifficultyCard(
                                difficulty: difficulty,
                                shortcutKey: shortcutKey,
                                shortcutLabel: shortcutLabel
                            ) {
                                withAnimation(.spring()) {
                                    viewModel.startGame(with: difficulty)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
                
                Spacer()
            }
            
            // Settings Panel
            if showSettings {
                SettingsPanel(isPresented: $showSettings)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .ignoresSafeArea()
    }
}

struct DifficultyCard: View {
    let difficulty: Difficulty
    let shortcutKey: KeyEquivalent?
    let shortcutLabel: String?
    let action: () -> Void
    
    @State private var isHovered = false
    
    init(difficulty: Difficulty, shortcutKey: KeyEquivalent? = nil, shortcutLabel: String? = nil, action: @escaping () -> Void) {
        self.difficulty = difficulty
        self.shortcutKey = shortcutKey
        self.shortcutLabel = shortcutLabel
        self.action = action
    }
    
    var body: some View {
        let theme = Color(red: difficulty.themeColor.r, green: difficulty.themeColor.g, blue: difficulty.themeColor.b)
        let bgColor = Color(hex: difficulty.cardColors.bg)
        let shadowColor = Color(hex: difficulty.cardColors.shadow)
        
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(shadowColor)
                    .offset(y: 12)
                
                RoundedRectangle(cornerRadius: 30)
                    .fill(bgColor)
                    .offset(y: isHovered ? -12 : 0)
                
                VStack(spacing: 20) {
                    Text(difficulty.icon)
                        .font(.system(size: 60))
                    
                    VStack(spacing: 8) {
                        Text(difficulty.rawValue.replacingOccurrences(of: "教学", with: "").replacingOccurrences(of: "模式", with: ""))
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(theme.darker(by: 0.2))
                        
                        Text(difficulty.ageGroup)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(theme))
                    }
                    
                    Text(difficulty.description)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(theme.darker(by: 0.3))
                        .multilineTextAlignment(.center)
                        .frame(height: 40)
                        .padding(.horizontal, 10)
                }
                .padding(20)
                .offset(y: isHovered ? -12 : 0)
                
                // Shortcut Badge
                if let label = shortcutLabel {
                    VStack {
                        HStack {
                            Spacer()
                            Text(label)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .offset(y: isHovered ? -12 : 0)
                }
            }
            .frame(width: 220, height: 320)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isHovered = hovering
            }
        }
        .ifLet(shortcutKey) { view, key in
            view.keyboardShortcut(key, modifiers: .command)
        }
    }
}

extension View {
    @ViewBuilder func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

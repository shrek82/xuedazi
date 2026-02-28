//
//  ContentView.swift
//  xuedazi
//
//  Created by up on 2026/2/12.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @FocusState var isFocused: Bool
    
    // 状态控制：配置窗口
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            BackgroundView()
            
            if viewModel.selectedDifficulty == nil {
                HomeView(viewModel: viewModel, showSettings: $showSettings)
            } else if viewModel.selectedDifficulty == .letterGame || viewModel.selectedDifficulty == .homeRow {
                LetterGameView(viewModel: viewModel, isFocused: _isFocused)
            } else {
                GameView(viewModel: viewModel, isFocused: _isFocused)
            }
            
            // Global Settings Overlay (Accessible from anywhere via shortcut)
            if showSettings && viewModel.selectedDifficulty != nil {
                SettingsPanel(isPresented: $showSettings)
                    .zIndex(200)
            }
            
            // Hidden shortcut handler for Command + Home
            Button(action: {
                if viewModel.selectedDifficulty != nil {
                    withAnimation(.spring()) {
                        viewModel.exitToHome()
                    }
                }
            }) {
                Color.clear
            }
            .keyboardShortcut(.home, modifiers: .command)
            .frame(width: 0, height: 0)
            .opacity(0)
            .allowsHitTesting(false)

        }
        .preferredColorScheme(.dark)
        // Global Keyboard Shortcuts
        .background {
            // Invisible view to handle keyboard events
            Color.clear
                .focusable()
                .onKeyPress(.home) {
                    // Home key: Exit to Home
                    if viewModel.selectedDifficulty != nil {
                        withAnimation(.spring()) {
                            viewModel.exitToHome()
                        }
                        return .handled
                    }
                    return .ignored
                }
        }
        // Menu Commands Handling via EventBus
        .onReceive(EventBus.shared.events) { event in
            switch event {
            case .resetGameProgress:
                // GameViewModel handles this internally via its own listener to EventBus
                // But we can trigger new game setup here if needed
                // Currently GameViewModel listens to resetGameProgress to reset state
                break
                
            case .toggleSettings:
                withAnimation {
                    showSettings.toggle()
                }
            case .difficultySelected(_):
                // GameViewModel handles this
                break
            }
        }
    }
}

struct BackgroundView: View {
    @ObservedObject var settings = GameSettings.shared
    
    var body: some View {
        Group {
            Color.themeBgSky50
        }
        .ignoresSafeArea()
    }
}

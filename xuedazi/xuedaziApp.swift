//
//  xuedaziApp.swift
//  xuedazi
//
//  Created by up on 2026/2/12.
//

import SwiftUI

@main
struct xuedaziApp: App {
    @Environment(\.openWindow) private var openWindow
    
    init() {
        FontLoader.shared.registerFont()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            // 添加 Game 菜单
            CommandMenu("Game") {
                Button("New Game") {
                    // Reset global progress (which will post .resetGameProgress)
                    PlayerProgress.shared.resetGlobalProgress()
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Settings") {
                    // 发送切换设置事件
                    EventBus.shared.post(.toggleSettings)
                }
                .keyboardShortcut("s", modifiers: .command)
            }
            
            // 语音合成菜单
            CommandMenu("语音合成") {
                Button("语音合成管理") {
                    openWindow(id: "speech-synthesis")
                }
            }
            
            // 添加全屏菜单命令
            CommandGroup(replacing: .windowSize) {
                Button("全屏") {
                    toggleFullScreen()
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }
        
        // 语音合成管理窗口
        Window("语音合成管理", id: "speech-synthesis") {
            SpeechSynthesisView()
        }
    }
    
    // 切换全屏函数
    private func toggleFullScreen() {
        guard let window = NSApplication.shared.keyWindow else { return }
        window.toggleFullScreen(nil)
    }
}

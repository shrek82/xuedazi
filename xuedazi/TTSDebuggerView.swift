//
//  TTSDebuggerView.swift
//  xuedazi
//
//  Created by up on 2026/2/22.
//

import SwiftUI

struct TTSDebuggerView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var cacheRefreshTrigger = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.showTTSDebugger = false
                }
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("TTS 调试器")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        viewModel.showTTSDebugger = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 10)
                
                if viewModel.words.isEmpty {
                    Text("无当前任务")
                        .foregroundColor(.gray)
                } else {
                    let word = viewModel.currentWord
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // 1. 完整句子/词组
                            TTSItemRow(
                                text: word.character,
                                isMemoryCached: checkMemoryCache(word.character),
                                isFileCached: checkFileCache(word.character),
                                onPlay: {
                                    speak(word.character)
                                },
                                onDelete: {
                                    deleteCache(word.character)
                                }
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.horizontal, 8)
                            
                            // 2. 单字拆解
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(Array(word.character), id: \.self) { char in
                                    let charStr = String(char)
                                    // 过滤标点符号
                                    if !isPunctuation(charStr) {
                                        TTSItemRow(
                                            text: charStr,
                                            isMemoryCached: checkMemoryCache(charStr),
                                            isFileCached: checkFileCache(charStr),
                                            onPlay: {
                                                speak(charStr)
                                            },
                                            onDelete: {
                                                deleteCache(charStr)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(20)
                    }
                    .background(Color(hex: "#1f2a22").opacity(0.8))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                
                Spacer()
                
                Text("点击外部关闭")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(30)
            .frame(maxWidth: 500, maxHeight: 600)
            .background(
                ZStack {
                    Color(hex: "#121212")
                    Color(hex: "#1f2a22").opacity(0.5)
                }
            )
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.5), radius: 30, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .onTapGesture {
                // 拦截点击，防止关闭
            }
        }
    }
    
    private func checkMemoryCache(_ text: String) -> Bool {
        // 触发刷新
        _ = cacheRefreshTrigger
        let voiceName = XunFeiTTSManager.shared.currentVoice
        return TTSCacheManager.shared.isMemoryCached(text: text, voice: voiceName)
    }
    
    private func checkFileCache(_ text: String) -> Bool {
        // 触发刷新
        _ = cacheRefreshTrigger
        let voiceName = XunFeiTTSManager.shared.currentVoice
        return TTSCacheManager.shared.isFileCached(text: text, voice: voiceName)
    }
    
    private func deleteCache(_ text: String) {
        let voiceName = XunFeiTTSManager.shared.currentVoice
        TTSCacheManager.shared.deleteCache(for: text, voice: voiceName)
        // 强制刷新视图
        cacheRefreshTrigger += 1
    }
    
    private func speak(_ text: String) {
        XunFeiTTSManager.shared.speak(text: text)
    }
    
    private func isPunctuation(_ char: String) -> Bool {
        let punctuationChars: [String] = [
            "，", "。", "、", "？", "！", "：", "；",
            "\u{201C}", "\u{201D}", "\u{2018}", "\u{2019}",
            "（", "）", "【", "】", "《", "》", "…", "—",
            ",", ".", "?", "!", ":", ";",
            "\"", "'", "(", ")", "[", "]", "<", ">", " "
        ]
        return punctuationChars.contains(char)
    }
}

struct TTSItemRow: View {
    let text: String
    let isMemoryCached: Bool
    let isFileCached: Bool
    let onPlay: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Text Info (Clickable for Play)
            Button(action: onPlay) {
                HStack(spacing: 12) {
                    // Play Icon
                    ZStack {
                        Circle()
                            .fill(Color.themeSkyBlue.opacity(0.2))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.themeSkyBlue)
                    }
                    
                    Text(text)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("点击朗读")
            
            Spacer()
            
            // Status Badges
            HStack(spacing: 8) {
                // Memory Badge
                StatusBadge(
                    icon: "memorychip",
                    isActive: isMemoryCached,
                    activeColor: .green,
                    tooltip: "内存缓存"
                )
                
                // File Badge
                StatusBadge(
                    icon: "externaldrive",
                    isActive: isFileCached,
                    activeColor: .blue,
                    tooltip: "文件缓存"
                )
                
                // Delete Button (Only visible if cached)
                if isMemoryCached || isFileCached {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.8))
                            .frame(width: 28, height: 28)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("删除缓存")
                    .padding(.leading, 8)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovering ? Color.themeSkyBlue.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
        )
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hover
            }
        }
    }
}

struct StatusBadge: View {
    let icon: String
    let isActive: Bool
    let activeColor: Color
    let tooltip: String
    
    var body: some View {
        Image(systemName: isActive ? icon + ".fill" : icon)
            .font(.system(size: 12))
            .foregroundColor(isActive ? activeColor : .gray.opacity(0.4))
            .frame(width: 24, height: 24)
            .background(isActive ? activeColor.opacity(0.15) : Color.white.opacity(0.05))
            .clipShape(Circle())
            .help(isActive ? "\(tooltip): 已缓存" : "\(tooltip): 未缓存")
    }
}

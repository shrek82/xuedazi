//
//  TTSSettingsView.swift
//  xuedazi
//
//  Created by up on 2026/2/21.
//

import SwiftUI
import AppKit

struct TTSSettingsView: View {
    @ObservedObject private var ttsManager = XunFeiTTSManager.shared
    @AppStorage("useSystemTTS") private var useSystemTTS = true
    @AppStorage("ttsEnabled") private var ttsEnabled = true
    @AppStorage("autoOnlineTTS") private var autoOnlineTTS = true
    @State private var isTesting = false
    @State private var testText = "你好，我是拼音大冒险的语音助手！"
    
    // 预定义一组可爱的颜色，用于音色卡片
    private let cardColors: [Color] = [
        .themeSkyBlue, .themeMintGreen, .themeAmberYellow, .themeCoralPink,
        .purple.opacity(0.7), .orange.opacity(0.8), .blue.opacity(0.6), .green.opacity(0.6)
    ]
    
    // 缓存 VoiceType 列表以避免重复创建
    private let voiceTypes = Array(XunFeiTTSManager.VoiceType.allCases.enumerated())
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 24) { // 使用 LazyVStack 提高滚动性能
                // 1. 语音开关卡片
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: ttsEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ttsEnabled ? .themeSkyBlue : .gray)
                            .frame(width: 40, height: 40)
                            .background(ttsEnabled ? Color.themeSkyBlue.opacity(0.1) : Color.gray.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("语音朗读")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text(ttsEnabled ? "已开启，点击右侧关闭" : "已关闭，点击右侧开启")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $ttsEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .themeSkyBlue))
                            .labelsHidden()
                    }
                    
                    if ttsEnabled {
                        Divider().background(Color.white.opacity(0.1))
                        
                        // 引擎选择
                        HStack(spacing: 0) {
                            engineOption(title: "系统语音", icon: "gearshape.2", isSelected: useSystemTTS) {
                                withAnimation(.spring()) { useSystemTTS = true }
                            }
                            
                            engineOption(title: "讯飞超拟人", icon: "sparkles", isSelected: !useSystemTTS) {
                                withAnimation(.spring()) { useSystemTTS = false }
                            }
                        }
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(12)
                        .padding(.top, 4)
                        
                        if !useSystemTTS {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("自动调用在线语音")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("若本地无缓存且未开启此项，将降级使用系统语音")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $autoOnlineTTS)
                                    .toggleStyle(SwitchToggleStyle(tint: .themeSkyBlue))
                                    .labelsHidden()
                                    .onChange(of: autoOnlineTTS) { newValue in
                                        print("📝 [TTS-SETTINGS] 自动在线语音设置已更改: \(newValue)")
                                    }
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                
                if ttsEnabled && !useSystemTTS {
                    // 2. 音色选择区域
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("🎙️ 选择喜欢的声音")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                            
                            Spacer()
                            
                            if let currentVoice = XunFeiTTSManager.VoiceType(rawValue: ttsManager.currentVoice) {
                                Text("当前：\(currentVoice.displayName)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.themeSkyBlue)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.themeSkyBlue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                            ForEach(voiceTypes, id: \.element) { index, voice in
                                VoiceCard(
                                    voice: voice,
                                    isSelected: ttsManager.currentVoice == voice.rawValue,
                                    color: cardColors[index % cardColors.count]
                                ) {
                                    if ttsManager.currentVoice != voice.rawValue {
                                        ttsManager.currentVoice = voice.rawValue
                                        // 自动试听
                                        SoundManager.shared.speak(text: "你好，我是\(voice.displayName)。")
                                    }
                                }
                            }
                        }
                    }

                    
                    // 3. 声音微调
                    VStack(alignment: .leading, spacing: 16) {
                        Text("🎚️ 声音微调")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            
                        VStack(spacing: 20) {
                            parameterSlider(title: "语速", value: Binding(
                                get: { Double(ttsManager.speed) },
                                set: { ttsManager.speed = Int($0) }
                            ), range: 10...100, icon: "hare.fill")
                            
                            parameterSlider(title: "音量", value: Binding(
                                get: { Double(ttsManager.volume) },
                                set: { ttsManager.volume = Int($0) }
                            ), range: 0...100, icon: "speaker.wave.3.fill")
                            
                            parameterSlider(title: "音高", value: Binding(
                                get: { Double(ttsManager.pitch) },
                                set: { ttsManager.pitch = Int($0) }
                            ), range: 0...100, icon: "music.note")
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            // 单字朗读倍速
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.themeAmberYellow)
                                        .frame(width: 20)
                                    
                                    Text("单字播放倍速 (客户端加速)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    Spacer()
                                }
                                
                                HStack {
                                    Slider(value: Binding(
                                        get: { GameSettings.shared.singleCharSpeedMultiplier },
                                        set: { 
                                            GameSettings.shared.singleCharSpeedMultiplier = $0
                                            GameSettings.shared.save()
                                        }
                                    ), in: 1.0...3.0, step: 0.1)
                                    .accentColor(.themeAmberYellow)
                                    
                                    Text(String(format: "%.1fx", GameSettings.shared.singleCharSpeedMultiplier))
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundColor(.themeAmberYellow)
                                        .frame(width: 50, alignment: .trailing)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(Color.themeAmberYellow.opacity(0.1))
                                        .cornerRadius(6)
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }

                    // 4. 测试与缓存
                    HStack(spacing: 12) {
                        // 测试按钮
                        Button {
                            isTesting = true
                            SoundManager.shared.speak(text: testText)
                            
                            // 简单的动画反馈
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                isTesting = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 20))
                                Text("完整测试")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [.themeSkyBlue, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(12)
                            .shadow(color: .themeSkyBlue.opacity(0.3), radius: 5, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(isTesting ? 0.95 : 1.0)
                        .animation(.spring(), value: isTesting)
                        
                        // 清除缓存按钮
                        Button {
                            XunFeiTTSManager.shared.clearCache()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16))
                                Text(String(format: "%.1f MB", XunFeiTTSManager.shared.getCacheSize()))
                                    .font(.system(size: 10))
                            }
                            .frame(width: 80, height: 48) // 稍微加高一点以容纳两行
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("清除语音缓存")
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("缓存目录")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button {
                            NSWorkspace.shared.open(cacheDirectoryURL)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.themeSkyBlue)
                                
                                Text(cacheDirectoryURL.path)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(2)
                                    .truncationMode(.middle)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top, 6)
                }
                
                // 底部提示
                if ttsEnabled {
                    Text(useSystemTTS ? "系统语音不需要网络，但音色较单一。" : "讯飞超拟人语音需要联网，音色更生动自然。")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 10)
                }
            }
            .padding(10)
        }
    }
    
    private var cacheDirectoryURL: URL {
        TTSCacheManager.shared.cacheDirectoryURL
    }
    
    // 引擎选择按钮组件
    private func engineOption(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected ? Color.themeSkyBlue : Color.clear
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 参数滑块组件
    private func parameterSlider(title: String, value: Binding<Double>, range: ClosedRange<Double>, icon: String) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
            }
            
            HStack {
                // 自定义 Slider
                ZStack(alignment: .leading) {
                    // 背景轨道
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    
                    // 激活轨道
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.themeSkyBlue)
                            .frame(width: max(0, min(geometry.size.width * CGFloat((value.wrappedValue - range.lowerBound) / (range.upperBound - range.lowerBound)), geometry.size.width)), height: 4)
                    }
                    .frame(height: 4)
                    
                    // 原生 Slider (半透明，保证可交互且略微可见)
                    Slider(value: value, in: range, step: 1)
                        .opacity(0.8) 
                        .accentColor(.clear) // 隐藏系统的高亮色，因为我们有自定义轨道
                }
                
                // 实时显示数值，确保足够醒目
                Text("\(Int(value.wrappedValue))")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.themeSkyBlue)
                    .frame(width: 35, alignment: .trailing)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.themeSkyBlue.opacity(0.1))
                    .cornerRadius(6)
            }
        }
    }
}

// 音色卡片组件
struct VoiceCard: View {
    let voice: XunFeiTTSManager.VoiceType
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 10) {
                    // 头像/图标
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 48, height: 48)
                        
                        Text(String(voice.displayName.prefix(1)))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(color)
                    }
                    
                    // 名称
                    Text(voice.displayName.components(separatedBy: "（").first ?? voice.displayName)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                        .lineLimit(1)
                    
                    // 描述
                    Text(descriptionFor(voice))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? color.opacity(0.15) : Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? color : (isHovered ? Color.white.opacity(0.2) : Color.clear), lineWidth: 2)
                )
                
                // 选中标记
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(color)
                        .background(Circle().fill(Color.white))
                        .offset(x: 6, y: -6)
                        .font(.system(size: 16))
                }
            }
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private func descriptionFor(_ voice: XunFeiTTSManager.VoiceType) -> String {
        if voice.displayName.contains("儿童") { return "适合孩子" }
        if voice.displayName.contains("少女") { return "活泼可爱" }
        if voice.displayName.contains("男声") { return "温暖沉稳" }
        return "特色语音"
    }
}

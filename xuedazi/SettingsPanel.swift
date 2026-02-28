//
//  SettingsPanel.swift
//  xuedazi
//
//  Created by up on 2026/2/12.
//

import SwiftUI

struct SettingsPanel: View {
    @Binding var isPresented: Bool
    @ObservedObject var settings = GameSettings.shared
    @ObservedObject var narratorManager = NarratorManager.shared
    
    @State private var selectedTab = 0
    @State private var moneyPerLetterText = ""
    @State private var penaltyPerErrorText = ""
    @State private var comboBonusMoneyText = ""
    @State private var randomRewardMinText = ""
    @State private var randomRewardMaxText = ""
    @State private var randomTreasureMinText = ""
    @State private var randomTreasureMaxText = ""
    @State private var randomMeteorMinText = ""
    @State private var randomMeteorMaxText = ""
    @State private var milestoneBonusMoneyText = ""
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Panel
            HStack(spacing: 0) {
                // Sidebar
                VStack(spacing: 20) {
                    Text("设置")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    VStack(spacing: 10) {
                        TabButton(title: "奖励配置", icon: "gift.fill", isSelected: selectedTab == 0) { selectedTab = 0 }
                        TabButton(title: "语音配置", icon: "speaker.wave.2.fill", isSelected: selectedTab == 1) { selectedTab = 1 }
                        TabButton(title: "延迟配置", icon: "timer", isSelected: selectedTab == 2) { selectedTab = 2 }
                        TabButton(title: "旁白配置", icon: "person.wave.2.fill", isSelected: selectedTab == 3) { selectedTab = 3 }
                        TabButton(title: "游戏配置", icon: "gamecontroller.fill", isSelected: selectedTab == 4) { selectedTab = 4 }
                    }
                    .padding(.horizontal, 10)
                    
                    Spacer()
                    
                    Button {
                        isPresented = false
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("关闭")
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 30)
                    }
                    .buttonStyle(.plain)
                }
                .frame(width: 200)
                .background(Color.black.opacity(0.4))
                
                // Content
                ZStack {
                    Color.themeBgSky50.opacity(0.95)
                    
                    if selectedTab == 0 {
                        rewardSettingsView
                    } else if selectedTab == 1 {
                        voiceSettingsView
                    } else if selectedTab == 2 {
                        delaySettingsView
                    } else if selectedTab == 3 {
                        narratorSettingsView
                    } else {
                        gameSettingsView
                    }
                }
                .frame(width: 700)
            }
            .frame(width: 900, height: 650)
            .background(Color.themeBgSky50)
            .cornerRadius(24)
            .shadow(radius: 40)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .onAppear {
            loadSettings()
        }
        .onDisappear {
            // Auto-save sliders (direct bindings) when closing
            settings.save()
        }
    }
    
    private func loadSettings() {
        moneyPerLetterText = String(format: "%.3f", settings.moneyPerLetter)
        penaltyPerErrorText = String(format: "%.3f", settings.penaltyPerError)
        comboBonusMoneyText = String(format: "%.3f", settings.comboBonusMoney)
        randomRewardMinText = String(format: "%.3f", settings.randomRewardMin)
        randomRewardMaxText = String(format: "%.3f", settings.randomRewardMax)
        randomTreasureMinText = String(format: "%.3f", settings.randomTreasureMin)
        randomTreasureMaxText = String(format: "%.3f", settings.randomTreasureMax)
        randomMeteorMinText = String(format: "%.3f", settings.randomMeteorMin)
        randomMeteorMaxText = String(format: "%.3f", settings.randomMeteorMax)
        milestoneBonusMoneyText = String(format: "%.3f", settings.milestoneBonusMoney)
    }
    
    // Helper to parse double string
    private func parseDouble(_ text: String) -> Double? {
        let cleanText = text
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "，", with: ".")
            .replacingOccurrences(of: "。", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleanText)
    }
    
    private func autoSave(_ text: String, to keyPath: ReferenceWritableKeyPath<GameSettings, Double>) {
        if let value = parseDouble(text) {
            settings[keyPath: keyPath] = value
            settings.save()
        }
    }

    // MARK: - Reward Settings
    private var rewardSettingsView: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("奖励配置")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 1. Basic Reward
                    RewardCard(title: "字母输入奖励", icon: "centsign.circle.fill", color: .themeSkyBlue) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("每正确输入一个拼音字母")
                                    .foregroundColor(.white.opacity(0.7))
                                Text("获得金币 (非汉字/整词)")
                                    .foregroundColor(.white.opacity(0.5))
                                    .font(.caption)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 10) {
                                TextField("0.01", text: $moneyPerLetterText)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 90) // 略微加宽以容纳更长的小数
                                    .padding(8)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(8)
                                    .onChange(of: moneyPerLetterText) { newValue in
                                        autoSave(newValue, to: \.moneyPerLetter)
                                    }
                                
                                Text("金币")
                                    .foregroundColor(.themeSkyBlue)
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                    }
                    
                    // 2. Combo Reward
                    RewardCard(title: "连击奖励 (小额音效)", icon: "flame.fill", color: .themeAmberYellow) {
                        HStack(spacing: 20) {
                            // Threshold
                            VStack(alignment: .leading, spacing: 8) {
                                Text("触发条件")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Stepper(value: $settings.comboBonusThreshold, in: 5...50, step: 5) {
                                    HStack(spacing: 4) {
                                        Text("每")
                                            .foregroundColor(.white.opacity(0.8))
                                        Text("\(settings.comboBonusThreshold)")
                                            .foregroundColor(.themeAmberYellow)
                                            .bold()
                                        Text("连击")
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .onChange(of: settings.comboBonusThreshold) { _ in settings.save() }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider().frame(height: 40).background(Color.white.opacity(0.2))
                            
                            // Amount
                            VStack(alignment: .trailing, spacing: 8) {
                                Text("额外奖励")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                HStack(spacing: 4) {
                                    TextField("0.10", text: $comboBonusMoneyText)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 70)
                                        .padding(6)
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(6)
                                        .onChange(of: comboBonusMoneyText) { newValue in
                                            autoSave(newValue, to: \.comboBonusMoney)
                                        }
                                    
                                    Text("金币")
                                        .foregroundColor(.themeAmberYellow)
                                        .font(.system(size: 14))
                                }
                            }
                        }
                    }
                    
                    // 3. Milestone Reward
                    RewardCard(title: "阶段里程碑 (大额音效)", icon: "flag.fill", color: .themeSuccessGreen) {
                        HStack(spacing: 20) {
                            // Threshold
                            VStack(alignment: .leading, spacing: 8) {
                                Text("触发条件")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Stepper(value: $settings.milestoneLetterCount, in: 10...500, step: 10) {
                                    HStack(spacing: 4) {
                                        Text("每完成")
                                            .foregroundColor(.white.opacity(0.8))
                                        Text("\(settings.milestoneLetterCount)")
                                            .foregroundColor(.themeSuccessGreen)
                                            .bold()
                                        Text("字母")
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .onChange(of: settings.milestoneLetterCount) { _ in settings.save() }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider().frame(height: 40).background(Color.white.opacity(0.2))
                            
                            // Amount
                            VStack(alignment: .trailing, spacing: 8) {
                                Text("额外奖励")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                HStack(spacing: 4) {
                                    TextField("1.00", text: $milestoneBonusMoneyText)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 70)
                                        .padding(6)
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(6)
                                        .onChange(of: milestoneBonusMoneyText) { newValue in
                                            autoSave(newValue, to: \.milestoneBonusMoney)
                                        }
                                    
                                    Text("金币")
                                        .foregroundColor(.themeSuccessGreen)
                                        .font(.system(size: 14))
                                }
                            }
                        }
                    }
                    
                    // 4. Random Reward
                    RewardCard(title: "幸运随机掉落 (大额音效)", icon: "gift.fill", color: .pink) {
                        VStack(spacing: 16) {
                            HStack {
                                Text("触发概率")
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("\(Int(settings.randomRewardChance * 100))%")
                                    .foregroundColor(.pink)
                                    .bold()
                            }
                            
                            Slider(value: $settings.randomRewardChance, in: 0.0...0.5, step: 0.01) { editing in
                                if !editing { settings.save() }
                            }
                                .accentColor(.pink)
                            
                            HStack {
                                Text("奖励金额范围")
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                HStack(spacing: 8) {
                                    TextField("0.5", text: $randomRewardMinText)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 50)
                                        .padding(4)
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(4)
                                        .onChange(of: randomRewardMinText) { newValue in
                                            autoSave(newValue, to: \.randomRewardMin)
                                        }
                                    
                                    Text("-")
                                        .foregroundColor(.white.opacity(0.5))
                                    
                                    TextField("1.0", text: $randomRewardMaxText)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 50)
                                        .padding(4)
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(4)
                                        .onChange(of: randomRewardMaxText) { newValue in
                                            autoSave(newValue, to: \.randomRewardMax)
                                        }
                                    
                                    Text("金币")
                                        .foregroundColor(.white.opacity(0.5))
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    
                    // 5. Random Treasure (Coin Rain)
                    RewardCard(title: "随机宝藏 (金币雨特效)", icon: "bitcoinsign.circle.fill", color: .yellow) {
                        VStack(spacing: 16) {
                            HStack {
                                Text("触发概率")
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("\(Int(settings.randomTreasureChance * 100))%")
                                    .foregroundColor(.yellow)
                                    .bold()
                            }
                            
                            Slider(value: $settings.randomTreasureChance, in: 0.0...0.5, step: 0.01) { editing in
                                if !editing { settings.save() }
                            }
                                .accentColor(.yellow)
                            
                            HStack {
                                Text("奖励金额范围")
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                HStack(spacing: 8) {
                                    TextField("0.01", text: $randomTreasureMinText)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 60)
                                        .padding(4)
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(4)
                                        .onChange(of: randomTreasureMinText) { newValue in
                                            autoSave(newValue, to: \.randomTreasureMin)
                                        }
                                    
                                    Text("-")
                                        .foregroundColor(.white.opacity(0.5))
                                    
                                    TextField("0.03", text: $randomTreasureMaxText)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 60)
                                        .padding(4)
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(4)
                                        .onChange(of: randomTreasureMaxText) { newValue in
                                            autoSave(newValue, to: \.randomTreasureMax)
                                        }
                                    
                                    Text("金币")
                                        .foregroundColor(.white.opacity(0.5))
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    
                    // 6. Random Meteor
                    RewardCard(title: "随机流星 (全屏特效)", icon: "sparkles", color: .purple) {
                        VStack(spacing: 16) {
                            HStack {
                                Text("触发概率")
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("\(Int(settings.randomMeteorChance * 100))%")
                                    .foregroundColor(.purple)
                                    .bold()
                            }
                            
                            Slider(value: $settings.randomMeteorChance, in: 0.0...0.5, step: 0.01) { editing in
                                if !editing { settings.save() }
                            }
                                .accentColor(.purple)
                            
                            HStack {
                                Text("奖励金额范围")
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                HStack(spacing: 8) {
                                    TextField("0.01", text: $randomMeteorMinText)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 60)
                                        .padding(4)
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(4)
                                        .onChange(of: randomMeteorMinText) { newValue in
                                            autoSave(newValue, to: \.randomMeteorMin)
                                        }
                                    
                                    Text("-")
                                        .foregroundColor(.white.opacity(0.5))
                                    
                                    TextField("0.02", text: $randomMeteorMaxText)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 60)
                                        .padding(4)
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(4)
                                        .onChange(of: randomMeteorMaxText) { newValue in
                                            autoSave(newValue, to: \.randomMeteorMax)
                                        }
                                    
                                    Text("金币")
                                        .foregroundColor(.white.opacity(0.5))
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    
                    // 5. Penalty Settings
                    RewardCard(title: "错误惩罚", icon: "exclamationmark.triangle.fill", color: .red) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("输入错误扣除")
                                    .foregroundColor(.white.opacity(0.7))
                                Text("通常设为0以鼓励尝试")
                                    .foregroundColor(.white.opacity(0.5))
                                    .font(.caption)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 10) {
                                Text("-")
                                    .foregroundColor(.red)
                                    .font(.title3.bold())
                                
                                TextField("0.00", text: $penaltyPerErrorText)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .padding(8)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(8)
                                    .onChange(of: penaltyPerErrorText) { newValue in
                                        autoSave(newValue, to: \.penaltyPerError)
                                    }
                                
                                Text("金币")
                                    .foregroundColor(.red)
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                    }
                    
                    Spacer().frame(height: 20)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Voice Settings
    private var voiceSettingsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("语音配置")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Reusing the existing TTSSettingsView
            TTSSettingsView()
        }
    }
    
    // MARK: - Delay Settings
    private var delaySettingsView: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("延迟配置")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            ScrollView {
                VStack(spacing: 25) {
                    // Reading Delay Settings
                    VStack(spacing: 20) {
                        Text("朗读前延迟 (秒)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("输入完成后，等待多久开始朗读单词。")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        DelaySlider(title: "朗读前延迟", value: $settings.delayBeforeSpeak, range: 0.0...2.0)
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(16)
                    
                    // Jump Delay Settings
                    VStack(spacing: 20) {
                        Text("跳转延迟设置 (秒)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("朗读完后，等待多久跳转到下一个。")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Standard Delay
                        DelaySlider(title: "普通模式", value: $settings.delayStandard, range: 0.0...2.0)
                        
                        // Article Delay
                        DelaySlider(title: "短文模式", value: $settings.delayArticle, range: 0.0...2.0)
                        
                        // Xiehouyu Delay
                        DelaySlider(title: "歇后语", value: $settings.delayXiehouyu, range: 0.0...3.0)
                        
                        // Hard Delay
                        DelaySlider(title: "成语/挑战", value: $settings.delayHard, range: 0.0...2.0)
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(16)
                }
            }
        }
    }

    // MARK: - Narrator Settings
    private var narratorSettingsView: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("旁白配置")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            ScrollView {
                VStack(spacing: 25) {
                    // 1. Enable Toggle & Persona
                    VStack(spacing: 20) {
                        Toggle(isOn: $narratorManager.isEnabled) {
                            Text("启用旁白")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .themeSkyBlue))
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        if narratorManager.isEnabled {
                            HStack {
                                Text("旁白角色")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Spacer()
                                
                                // Preview Button
                                Button(action: {
                                    narratorManager.previewCurrentVoice()
                                }) {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.themeSkyBlue.opacity(0.8))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("试听声音")
                                
                                Picker("", selection: $narratorManager.currentType) {
                                    ForEach(NarratorType.allCases, id: \.self) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(width: 150)
                                .onChange(of: narratorManager.currentType) { _ in
                                    narratorManager.previewCurrentVoice()
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(16)
                    
                    if narratorManager.isEnabled {
                        // 2. Frequency (Interval)
                        VStack(spacing: 20) {
                            Text("旁白频率")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack {
                                Text("冷却时间")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 80, alignment: .leading)
                                
                                Slider(value: $narratorManager.minInterval, in: 2.0...20.0, step: 1.0)
                                    .accentColor(.themeSkyBlue)
                                
                                Text("\(Int(narratorManager.minInterval))秒")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.themeAmberYellow)
                                    .frame(width: 50)
                            }
                            
                            Text("间隔时间越短，旁白说话越频繁。")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(20)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(16)
                        
                        // 3. Voice Settings (Speed & Volume)
                        VStack(spacing: 20) {
                            Text("语音参数")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Speed
                            HStack {
                                Text("语速")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 60, alignment: .leading)
                                
                                Slider(value: Binding(
                                    get: { Double(narratorManager.speed) },
                                    set: { narratorManager.speed = Int($0) }
                                ), in: 0...100, step: 1)
                                .accentColor(.themeSkyBlue)
                                
                                Text("\(narratorManager.speed)")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.themeAmberYellow)
                                    .frame(width: 40)
                            }
                            
                            // Volume
                            HStack {
                                Text("音量")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 60, alignment: .leading)
                                
                                Slider(value: Binding(
                                    get: { Double(narratorManager.volume) },
                                    set: { narratorManager.volume = Int($0) }
                                ), in: 0...100, step: 1)
                                .accentColor(.themeSuccessGreen)
                                
                                Text("\(narratorManager.volume)")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.themeAmberYellow)
                                    .frame(width: 40)
                            }
                            
                            // Pitch
                            HStack {
                                Text("高音")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 60, alignment: .leading)
                                
                                Slider(value: Binding(
                                    get: { Double(narratorManager.pitch) },
                                    set: { narratorManager.pitch = Int($0) }
                                ), in: 0...100, step: 1)
                                .accentColor(.themeAmberYellow)
                                
                                Text("\(narratorManager.pitch)")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.themeAmberYellow)
                                    .frame(width: 40)
                            }
                        }
                        .padding(20)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(16)
                    }
                }
            }
        }
    }
    // MARK: - Game Settings
    private var gameSettingsView: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("游戏配置")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            ScrollView {
                VStack(spacing: 25) {
                    
                    // 1. Health
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                            Text("生命值")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        HStack(spacing: 20) {
                            Text("初始生命值")
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 100, alignment: .leading)
                            
                            Stepper(value: $settings.maxHealth, in: 0...10, step: 1) {
                                HStack {
                                    if settings.maxHealth == 0 {
                                        Text("无敌模式")
                                            .foregroundColor(.themeSuccessGreen)
                                            .bold()
                                    } else {
                                        ForEach(0..<settings.maxHealth, id: \.self) { _ in
                                            Image(systemName: "heart.fill")
                                                .foregroundColor(.red)
                                                .font(.system(size: 14))
                                        }
                                    }
                                }
                            }
                            .onChange(of: settings.maxHealth) { _ in
                                settings.save()
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        HStack(spacing: 20) {
                            Text("错误扣血")
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 100, alignment: .leading)
                            
                            Stepper(value: $settings.healthPerError, in: 0...5, step: 1) {
                                HStack {
                                    if settings.healthPerError == 0 {
                                        Text("无惩罚")
                                            .foregroundColor(.themeSuccessGreen)
                                            .bold()
                                    } else {
                                        ForEach(0..<settings.healthPerError, id: \.self) { _ in
                                            Image(systemName: "heart.slash.fill")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 14))
                                        }
                                    }
                                }
                            }
                            .onChange(of: settings.healthPerError) { _ in
                                settings.save()
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        HStack(spacing: 20) {
                            Text("购买生命花费")
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 100, alignment: .leading)
                            
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundColor(.themeAmberYellow)
                                
                                Stepper(value: $settings.costPerHealth, in: 1...100, step: 1) {
                                    Text("\(Int(settings.costPerHealth)) 金币")
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(.themeAmberYellow)
                                }
                                .onChange(of: settings.costPerHealth) { _ in
                                    settings.save()
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(16)
                    
                    // 2. Time Limit
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.themeSkyBlue)
                            Text("时间限制")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        HStack(spacing: 20) {
                            Text("游戏时长")
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 100, alignment: .leading)
                            
                            Slider(value: $settings.gameTimeLimit, in: 0...5400, step: 60) { editing in
                                if !editing { settings.save() }
                            }
                            .accentColor(.themeSkyBlue)
                            
                            Text(settings.gameTimeLimit == 0 ? "不限时" : "\(Int(settings.gameTimeLimit / 60))分钟")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.themeAmberYellow)
                                .frame(width: 80)
                        }
                        
                        Text("设置为0表示不限制游戏时间。")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(16)
                }
                .padding(.bottom, 40)
            }
        }
        .padding(.top, 40)
        .padding(.horizontal, 40)
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct DelaySlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 120, alignment: .leading)
            
            Slider(value: $value, in: range, step: 0.1) { editing in
                if !editing { GameSettings.shared.save() }
            }
                .accentColor(.themeSkyBlue)
            
            Text(String(format: "%.1f秒", value))
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.themeAmberYellow)
                .frame(width: 60)
        }
    }
}

struct RewardCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(Color.black.opacity(0.2))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}


//
//  GameView.swift
//  xuedazi
//
//  Created by up on 2026/2/12.
//

import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    @FocusState var isFocused: Bool
    @AppStorage("autoDefinitionSpeakEnabled") private var autoDefinitionSpeakEnabled = true
    @State private var autoSpeakToken: UUID = UUID()
    
    
    @ViewBuilder
    var activeEffects: some View {
        if viewModel.showDamageFlash {
            DamageEffectView()
                .zIndex(60)
        }
        
        if viewModel.showLuckyDropEffect {
            LuckyDropView()
                .zIndex(67)
        }
        
        if viewModel.showTreasureEffect {
            TreasureRainView()
                .zIndex(69)
        }
        
        if viewModel.showMeteorEffect {
            MeteorShowerView()
                .zIndex(68)
        }
        
        ComboEvaluationView(comboCount: viewModel.comboCount)
            .zIndex(65)
        
        if viewModel.showTTSDebugger {
            TTSDebuggerView(viewModel: viewModel)
                .zIndex(300)
                .transition(.opacity)
        }
        
        if viewModel.showMilestoneEffect {
            FullScreenConfettiView()
                .allowsHitTesting(false)
                .zIndex(70)
        }
        
        if viewModel.gameState == .gameOver {
            GameOverView(viewModel: viewModel)
                .transition(.opacity)
                .zIndex(200)
        }
    }

    var body: some View {
        ZStack {
            // Fire Effect (Behind everything)
            if viewModel.showFireEffect {
                FireEffectView()
                    .allowsHitTesting(false)
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            }
            
            VStack(spacing: 20) {
                // Spacer for top bar
                Spacer().frame(height: 80)
            
                // Game Area
                if !viewModel.words.isEmpty {
                    VStack(spacing: 15) {
                        VStack(spacing: 10) {
                            AlignedInputView(
                                character: viewModel.currentWord.character,
                                displayPinyin: viewModel.currentWord.displayPinyin,
                                typedCount: viewModel.currentInput.count,
                                isWrong: viewModel.isWrong,
                                teachingMode: viewModel.teachingMode,
                                pinyinFontSize: 42,
                                hanziFontSize: 84,
                                showHanzi: viewModel.teachingMode != .hidden
                            )
                            .equatable()
                            .onTapGesture(count: 2) {
                                withAnimation {
                                    viewModel.showTTSDebugger = true
                                }
                            }
                            .overlay(
                                Group {
                                    if viewModel.showSuccess {
                                        SuccessSparkleView()
                                            .allowsHitTesting(false)
                                    }
                                }
                            )
                            
                            // 多种模式下显示解释（成语、英语单词、编程词汇、日常英语、唐诗、滕王阁序）
                            if [.hard, .englishPrimary, .programmingVocab, .dailyEnglish, .tangPoetry, .tengwangGeXu].contains(viewModel.selectedDifficulty) && !viewModel.currentWord.definition.isEmpty {
                                Text(viewModel.currentWord.definition)
                                    .font(FontLoader.shared.chineseFont(size: 32)) // 使用与汉字一致的字体，字号加大
                                    .foregroundColor(.white.opacity(0.5)) // 灰色显示
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 10)
                                    .transition(.opacity)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Maximize height
                    .padding(.horizontal, 40)
                    .padding(.vertical, 0) // Reduce vertical padding
                    .modifier(ShakeEffect(clicks: viewModel.shakeTrigger))
                    .animation(.linear(duration: 0.4), value: viewModel.shakeTrigger)
                    .scaleEffect(viewModel.showSuccess ? 1.05 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.showSuccess)
                } else if viewModel.gameState == .playing && viewModel.words.isEmpty && viewModel.selectedDifficulty != nil {
                    ProgressView()
                }
                
                // Reduce spacer height to allow text area to expand
                Spacer(minLength: 0)
                
                // Bottom Bar with Back Button (Left) and Keyboard (Center)
                ZStack(alignment: .bottomLeading) {
                    // Back Button (Bottom Left)
                    Button {
                        withAnimation(.spring()) { viewModel.exitToHome() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("返回")
                        }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(12)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.home, modifiers: .command)
                    .padding(.leading, 30)
                    .padding(.bottom, 30)
                    .zIndex(10) // Ensure button is above keyboard if they overlap
                    
                    // Keyboard (Center Bottom)
                    if viewModel.showVirtualKeyboard {
                        HStack {
                            Spacer()
                            KeyboardView(
                                lastPressedKey: viewModel.lastPressedKey,
                                lastWrongKey: viewModel.lastWrongKey,
                                hintKey: viewModel.hintKey,
                                pressTrigger: viewModel.pressTrigger,
                                currentFingerType: viewModel.currentFingerType,
                                accentColor: .themeSkyBlue
                            )
                                .equatable()
                                .padding(.bottom, 60)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            Spacer()
                        }
                    }
                    
                    if shouldShowDefinitionToggle {
                        Button {
                            autoDefinitionSpeakEnabled.toggle()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: autoDefinitionSpeakEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                    .font(.system(size: 14, weight: .bold))
                                
                                Text(autoDefinitionSpeakEnabled ? "暂停朗读" : "自动朗读")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.35))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 30)
                        .padding(.bottom, 30)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .zIndex(12)
                    }
                }
                .frame(maxWidth: .infinity) // Ensure ZStack takes full width
                .padding(.top, 0) // Remove extra padding to allow text area to expand
                
                TextField("", text: $viewModel.internalInput)
                    .focused($isFocused)
                    .opacity(0)
                    .frame(height: 0)
                    .onChange(of: viewModel.internalInput) { _, _ in
                        viewModel.checkInput()
                    }
                    .onKeyPress(.leftArrow) {
                        viewModel.previousTask()
                        return .handled
                    }
                    .onKeyPress(.rightArrow) {
                        viewModel.nextTask()
                        return .handled
                    }
            }
            .blur(radius: viewModel.gameState == .gameOver ? 10 : 0) // Blur when game over
            
            activeEffects
        }
        .onChange(of: viewModel.currentIndex) { _, _ in
            handleAutoDefinitionSpeak()
        }
        .onChange(of: autoDefinitionSpeakEnabled) { _, newValue in
            if newValue {
                handleAutoDefinitionSpeak()
            } else {
                autoSpeakToken = UUID()
                SoundManager.shared.stopSpeaking()
            }
        }
        .onAppear { isFocused = true }
        .onTapGesture { isFocused = true }
        .overlay(alignment: .top) {
            GameTopBar(viewModel: viewModel)
                .padding(.top, 20)
                .padding(.horizontal, 30)
        }
    }
    
    private var shouldShowDefinitionToggle: Bool {
        guard let diff = viewModel.selectedDifficulty else { return false }
        return [.easy, .medium, .hard, .xiehouyu, .article, .tangPoetry, .tengwangGeXu].contains(diff)
    }
    
    private func handleAutoDefinitionSpeak() {
        guard autoDefinitionSpeakEnabled else { return }
        guard shouldShowDefinitionToggle else { return }
        guard viewModel.gameState == .playing else { return }
        guard !viewModel.words.isEmpty else { return }
        let token = UUID()
        autoSpeakToken = token
        SoundManager.shared.stopSpeaking()
        let text = autoSpeakText
        guard !text.isEmpty else { return }
        let delay = GameSettings.shared.delayBeforeSpeak
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard autoSpeakToken == token else { return }
            SoundManager.shared.speak(text: text) {
                guard autoSpeakToken == token else { return }
                let jumpDelay = autoAdvanceDelay
                DispatchQueue.main.asyncAfter(deadline: .now() + jumpDelay) {
                    guard autoSpeakToken == token else { return }
                    let nextIndex = (viewModel.currentIndex + 1) % viewModel.words.count
                    viewModel.jumpToProgress(nextIndex, speak: false)
                }
            }
        }
    }
    
    private var autoSpeakText: String {
        return viewModel.currentWord.character
    }
    
    private var autoAdvanceDelay: Double {
        guard let diff = viewModel.selectedDifficulty else { return GameSettings.shared.delayStandard }
        if diff == .article { return GameSettings.shared.delayArticle }
        if diff == .hard { return GameSettings.shared.delayHard }
        if diff == .xiehouyu { return GameSettings.shared.delayXiehouyu }
        return GameSettings.shared.delayStandard
    }
}

struct GameTopBar: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var settings = GameSettings.shared
    @State private var draggingIndex: Int? = nil
    
    var body: some View {
        ZStack(alignment: .top) {
            // CENTER: Health Bar (Layer 1 - Bottom)
            if settings.maxHealth > 0 {
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        ForEach(0..<settings.maxHealth, id: \.self) { index in
                            Image(systemName: index < viewModel.currentHealth ? "heart.fill" : "heart")
                                .foregroundColor(.red)
                                .font(.system(size: 16))
                                .scaleEffect(index < viewModel.currentHealth ? 1.0 : 0.8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.currentHealth)
                                .shadow(color: .red.opacity(0.3), radius: 1)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                        .fill(Color.black.opacity(0.15))
                        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                    )
                    
                    // Buy Health Button
                    if viewModel.currentHealth < settings.maxHealth {
                        Button {
                            withAnimation(.spring()) {
                                viewModel.buyHealth()
                            }
                        } label: {
                            HStack(spacing: 2) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.themeSuccessGreen)
                                
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.themeAmberYellow)
                                
                                Text("\(Int(settings.costPerHealth))")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.themeAmberYellow)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                        .help("购买生命值 (花费 \(Int(settings.costPerHealth)) 金币)")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center) // Absolute Center
                .padding(.top, 4) // Slight adjustment
            }
            
            // SIDES: Left and Right Panels (Layer 2 - Top)
            HStack(alignment: .top) {
                // LEFT: Progress Bars (Word Index, Combo, Milestone)
                VStack(spacing: 8) {
                    // Word Index
                    if viewModel.words.isEmpty && (viewModel.selectedDifficulty == .letterGame || viewModel.selectedDifficulty == .homeRow) {
                        HStack(spacing: 12) {
                            Image(systemName: "keyboard.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.themeSkyBlue)
                                .frame(width: 24, height: 24)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                let totalRepeats = max(viewModel.letterGameRepeatsTotal, 1)
                                let remaining = max(viewModel.letterGameRepeatsLeft, 0)
                                let completed = max(0, totalRepeats - remaining)
                                let progress = CGFloat(completed) / CGFloat(totalRepeats)
                                
                                HStack(alignment: .lastTextBaseline, spacing: 8) {
                                    Text(viewModel.letterGameTarget.isEmpty ? "练习" : viewModel.letterGameTarget.uppercased())
                                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                                        .foregroundColor(.themeSkyBlue)
                                    
                                    Text("剩余 \(remaining)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Spacer()
                                }
                                
                                GeometryReader { proxy in
                                    let width = proxy.size.width
                                    
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.black.opacity(0.3))
                                            .frame(height: 8)
                                        
                                        Capsule()
                                            .fill(LinearGradient(colors: [.themeSkyBlue, .themeSkyBlue.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                                            .frame(width: max(0, progress * width), height: 8)
                                    }
                                }
                                .frame(height: 30)
                            }
                        }
                        .padding(12)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(12)
                    } else {
                        HStack(spacing: 12) {
                            // Icon
                            Image(systemName: "book.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.themeSkyBlue)
                                .frame(width: 24, height: 24)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                // Labels
                                HStack(alignment: .lastTextBaseline, spacing: 8) {
                                    Text("\( (draggingIndex ?? viewModel.currentIndex) + 1) / \(viewModel.words.count)")
                                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                                        .foregroundColor(.themeSkyBlue)
                                    
                                    Spacer()
                                }
                                
                                // Bar
                                GeometryReader { proxy in
                                    let width = proxy.size.width
                                    let currentIndex = draggingIndex ?? viewModel.currentIndex
                                    let progress = viewModel.words.isEmpty ? 0 : CGFloat(currentIndex + 1) / CGFloat(viewModel.words.count)
                                    
                                    ZStack(alignment: .leading) {
                                        // Transparent touch area
                                        Color.clear
                                            .frame(height: 30)
                                            .contentShape(Rectangle())
                                        
                                        // Track
                                        Capsule()
                                            .fill(Color.black.opacity(0.3))
                                            .frame(height: 8)
                                        
                                        // Fill
                                        Capsule()
                                            .fill(LinearGradient(colors: [.themeSkyBlue, .themeSkyBlue.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                                            .frame(width: max(0, progress * width), height: 8)
                                            .animation(draggingIndex != nil ? nil : .spring(response: 0.4, dampingFraction: 0.7), value: progress)
                                        
                                        // Rabbit
                                        Text("🐰")
                                            .font(.system(size: 20))
                                            .offset(x: max(0, min(progress * width - 10, width - 20)))
                                            .shadow(radius: 2)
                                            .animation(draggingIndex != nil ? nil : .spring(response: 0.5, dampingFraction: 0.7), value: progress)
                                    }
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                guard !viewModel.words.isEmpty else { return }
                                                let percentage = max(0, min(value.location.x / width, 1.0))
                                                let newIndex = Int(percentage * CGFloat(viewModel.words.count - 1))
                                                
                                                // 优化：拖拽过程中只更新本地状态，避免频繁触发重业务逻辑
                                                draggingIndex = newIndex
                                            }
                                            .onEnded { value in
                                                guard !viewModel.words.isEmpty else { return }
                                                let percentage = max(0, min(value.location.x / width, 1.0))
                                                let newIndex = Int(percentage * CGFloat(viewModel.words.count - 1))
                                                
                                                // 拖拽结束，提交变更并朗读
                                                draggingIndex = nil
                                                if newIndex != viewModel.currentIndex {
                                                    viewModel.jumpToProgress(newIndex, speak: true)
                                                }
                                            }
                                    )
                                }
                                .frame(height: 30) // Increased height for better touch target
                            }
                        }
                        .padding(12)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(12)
                    }
                    
                    // Combo Progress
                    GameProgressBar(
                        value: viewModel.comboProgress,
                        color: .themeAmberYellow,
                        icon: "flame.fill",
                        label: viewModel.comboCount > 0 ? "\(viewModel.comboCount)" : "",
                        subLabel: "连击 +\(String(format: "%.2f", settings.comboBonusMoney))金币"
                    )
                    
                    // Milestone Progress
                    GameProgressBar(
                        value: viewModel.milestoneProgress,
                        color: .themeSuccessGreen,
                        icon: "flag.fill",
                        label: "",
                        subLabel: "阶段 +\(String(format: "%.2f", settings.milestoneBonusMoney))金币"
                    )
                    
                    // Time Progress (if limited)
                    if settings.gameTimeLimit > 0 {
                        GameProgressBar(
                            value: viewModel.timeRemaining / settings.gameTimeLimit,
                            color: .themeSkyBlue,
                            icon: "clock.fill",
                            label: timeString(from: viewModel.timeRemaining),
                            subLabel: "剩余时间"
                        )
                    }
                }
                .frame(minWidth: 200, maxWidth: 320, alignment: .leading)
                
                Spacer(minLength: 120) // Ensure gap for Health Bar
                
                // RIGHT: Stats (Score, Money)
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 12) {
                        ScoreDisplay(score: viewModel.score)
                        
                        MoneyDisplay(amount: viewModel.earnedMoney, change: viewModel.moneyChange)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    
                    // Rewards container (Bubbles)
                    LazyVStack(alignment: .trailing, spacing: 8) {
                        ForEach(viewModel.floatingRewards) { reward in
                            RewardBubbleView(reward: reward)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }
                    .frame(width: 260, alignment: .trailing) // Increased width for better fit
                    .offset(y: 20)
                    .zIndex(100)
                }
                .frame(minWidth: 200, maxWidth: 320, alignment: .trailing)
            }
        }
    }
    
    private func timeString(from seconds: Double) -> String {
        let intSeconds = Int(seconds)
        let m = intSeconds / 60
        let s = intSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct GameProgressBar: View {
    let value: Double
    let color: Color
    let icon: String
    let label: String
    let subLabel: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 6) {
                // Labels
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    if !label.isEmpty {
                        Text(label)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundColor(color)
                    }
                    
                    Text(subLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                }
                
                // Bar
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        // Track
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                            .frame(height: 8)
                        
                        // Fill
                        Capsule()
                            .fill(LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, min(CGFloat(value) * proxy.size.width, proxy.size.width)), height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: value)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }
}

struct GameOverView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("GAME OVER")
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .red.opacity(0.5), radius: 10, x: 0, y: 0)
                
                VStack(spacing: 15) {
                    ResultRow(icon: "star.fill", title: "得分", value: "\(viewModel.score)", color: .yellow)
                    ResultRow(icon: "dollarsign.circle.fill", title: "金币", value: String(format: "%.2f", viewModel.earnedMoney), color: .green)
                    ResultRow(icon: "bolt.fill", title: "最大连击", value: "\(viewModel.maxCombo)", color: .blue)
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "#1f2a22").opacity(0.9))
                        .shadow(radius: 20)
                )
                
                Button {
                    withAnimation {
                        viewModel.exitToHome()
                    }
                } label: {
                    Text("返回主菜单")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.blue))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.home, modifiers: .command)
            }
        }
    }
}

struct ResultRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
                .frame(width: 30)
            
            Text(title)
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)
        }
        .frame(width: 250)
    }
}

struct RewardBubbleView: View {
    let reward: FloatingReward
    // Removed offset state to prevent layout issues in VStack
    @State private var opacity: Double = 0.0
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(reward.color)
            
            Text(reward.text)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            ZStack {
                // Glass-like dark background
                Color.black.opacity(0.7)
                
                // Colored glow/border
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [reward.color.opacity(0.8), reward.color.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .cornerRadius(16)
            .shadow(color: reward.color.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(scale)
        .opacity(opacity)
        // Removed .offset(y: offset)
        .onAppear {
            // Entry animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                opacity = 1.0
                scale = 1.0
                // Removed offset animation
            }
            
            // Exit animation - sync with ScoreManager removal (2.0s)
            withAnimation(.easeOut(duration: 0.5).delay(1.5)) {
                opacity = 0.0
                scale = 0.9
                // Removed offset animation
            }
        }
    }
    
    private var iconName: String {
        switch reward.type {
        case .combo: return "flame.fill"
        case .lucky: return "gift.fill"
        case .milestone: return "flag.fill"
        case .treasure: return "bitcoinsign.circle.fill"
        case .meteor: return "star.fill"
        }
    }
}

//
//  LetterGameView.swift
//  xuedazi
//
//  Created by up on 2026/2/12.
//

import SwiftUI

struct LetterGameView: View {
    @ObservedObject var viewModel: GameViewModel
    @FocusState var isFocused: Bool
    
    @State private var dropProgress: CGFloat = 0
    @State private var dropDuration: Double = 3.0
    @State private var dropStartTime: Date = Date()
    @State private var keyPositions: [String: CGRect] = [:]
    @State private var gameAreaFrame: CGRect = .zero
    
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
        GeometryReader { globalGeo in
            ZStack {
                VStack(spacing: 20) {
                    Spacer().frame(height: 80)
                
                    GeometryReader { proxy in
                        let startY: CGFloat = 0
                        let endY: CGFloat = max(proxy.size.height - 140, 120)
                        
                        ZStack(alignment: .top) {
                            Text(viewModel.letterGameTarget.uppercased())
                                .font(FontLoader.shared.pinyinFont(size: 100, weight: .medium))
                                .foregroundColor(viewModel.letterGameHitFlash ? .themeSuccessGreen : .themeAmberYellow)
                                .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
                                .scaleEffect(viewModel.letterGameHitFlash ? 1.08 : 1.0)
                                .opacity(0.35 + 0.65 * Double(dropProgress))
                                .modifier(ShakeEffect(clicks: viewModel.shakeTrigger))
                                .offset(y: startY + (endY - startY) * dropProgress)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                    .frame(height: 360)
                    .background(GeometryReader { gp in
                        Color.clear.preference(key: GameAreaPreferenceKey.self, value: gp.frame(in: .named("LetterGameSpace")))
                    })
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    if viewModel.showVirtualKeyboard {
                        KeyboardView(
                            lastPressedKey: viewModel.lastPressedKey,
                            lastWrongKey: viewModel.lastWrongKey,
                            hintKey: viewModel.hintKey,
                            pressTrigger: viewModel.pressTrigger,
                            currentFingerType: viewModel.currentFingerType,
                            accentColor: .themeSkyBlue
                        )
                            .padding(.bottom, 60)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    TextField("", text: $viewModel.letterGameInput)
                        .focused($isFocused)
                        .opacity(0)
                        .frame(height: 0)
                        .onChange(of: viewModel.letterGameInput) { _, new in
                            if !new.isEmpty {
                                viewModel.handleLetterGameInput(new)
                            }
                        }
                }
                .onAppear { isFocused = true }
                .onTapGesture { isFocused = true }
                .onChange(of: viewModel.letterGameDropToken) { _, _ in
                    dropProgress = 0
                    
                    let minDuration = max(1.2, 3.5 - (Double(viewModel.score) * 0.05))
                    let maxDuration = max(1.5, 4.0 - (Double(viewModel.score) * 0.05))
                    dropDuration = Double.random(in: minDuration...maxDuration)
                    dropStartTime = Date()
                    
                    withAnimation(.linear(duration: dropDuration)) {
                        dropProgress = 1
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: viewModel.letterGameHitFlash)
                .coordinateSpace(name: "LetterGameSpace")
                .onPreferenceChange(KeyPositionPreferenceKey.self) {
                    self.keyPositions = $0
                }
                .onPreferenceChange(GameAreaPreferenceKey.self) {
                    self.gameAreaFrame = $0
                }
                .overlay(
                    ZStack {
                        if viewModel.selectedDifficulty == .homeRow {
                            let targetKey = viewModel.letterGameTarget.lowercased()
                            let keyFrame = keyPositions[targetKey] ?? .zero
                            let globalFrame = globalGeo.frame(in: .global)
                            let screenWidth = globalFrame.width
                            
                            let startPoint = (keyFrame.width > 0) ? 
                                CGPoint(x: keyFrame.midX, y: keyFrame.midY) : 
                                CGPoint(x: screenWidth / 2, y: globalFrame.height - 100)
                            
                            let flightTime: TimeInterval = 0.2
                            let elapsed = Date().timeIntervalSince(dropStartTime)
                            let predictedProgress = (elapsed + flightTime) / dropDuration
                            let clampedProgress = min(max(predictedProgress, 0), 1.0)
                            
                            let safeAreaTop = globalGeo.safeAreaInsets.top
                            let topBarHeight: CGFloat = 60
                            let startY = safeAreaTop + topBarHeight
                            let gameAreaHeight: CGFloat = 360
                            let endY = startY + gameAreaHeight - 140
                            
                            let targetY = startY + ((endY - startY) * CGFloat(clampedProgress))
                            
                            BulletEffectLayer(
                                triggerToken: viewModel.score,
                                targetPoint: CGPoint(
                                    x: globalFrame.midX,
                                    y: targetY
                                ),
                                startPoint: startPoint
                            )
                        }
                    }
                )
                .overlay(alignment: .top) {
                    GameTopBar(viewModel: viewModel)
                        .padding(.top, 20)
                        .padding(.horizontal, 30)
                }
                .overlay(alignment: .bottomLeading) {
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
                    .zIndex(10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                activeEffects
                    .frame(width: globalGeo.size.width, height: globalGeo.size.height)
                    .ignoresSafeArea()
                    .zIndex(100)
            }
        }
    }
}
struct BulletEffectLayer: View {
    let triggerToken: Int
    let targetPoint: CGPoint
    let startPoint: CGPoint
    
    @State private var isAnimating = false
    @State private var bulletPos: CGPoint = .zero
    @State private var showExplosion = false
    @State private var explosionPos: CGPoint = .zero
    
    var body: some View {
        ZStack {
            if isAnimating {
                // Bullet
                Circle()
                    .fill(Color.themeSuccessGreen)
                    .frame(width: 12, height: 12)
                    .shadow(color: .themeSuccessGreen, radius: 8)
                    .overlay(
                         Circle().stroke(Color.white, lineWidth: 2)
                    )
                    .position(bulletPos)
            }
            
            if showExplosion {
                // Explosion particles
                ExplosionView()
                    .position(explosionPos)
            }
        }
        .allowsHitTesting(false) // Don't block interactions
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill screen for overlay
        .ignoresSafeArea() // Ensure overlay covers everything
        .onChange(of: triggerToken) { _, _ in
            startAnimation()
        }
    }
    
    func startAnimation() {
        // Reset state
        bulletPos = startPoint
        isAnimating = true
        showExplosion = false
        
        // Capture current target position for explosion
        let currentTarget = targetPoint
        explosionPos = currentTarget
        
        let duration = 0.2
        
        withAnimation(.easeIn(duration: duration)) {
            bulletPos = currentTarget
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            isAnimating = false
            showExplosion = true
            
            // Explosion sound
            SoundManager.shared.playHit()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showExplosion = false
            }
        }
    }
}

struct ExplosionView: View {
    @State private var scale: CGFloat = 0.2
    @State private var opacity: Double = 1.0
    
    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                Circle()
                    .fill(Color.themeSuccessGreen)
                    .frame(width: 8, height: 8)
                    .offset(y: -20)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            Circle()
                .fill(Color.white)
                .frame(width: 15, height: 15)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                scale = 2.0
                opacity = 0.0
            }
        }
    }
}

struct KeyPositionPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

struct GameAreaPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

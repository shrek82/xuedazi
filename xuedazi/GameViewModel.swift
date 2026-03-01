//
//  GameViewModel.swift
//  xuedazi
//
//  Created by up on 2026/2/23.
//

import Foundation
import Combine
import SwiftUI

/// 负责连接视图和游戏引擎，转发状态并管理策略
class GameViewModel: ObservableObject {
    // MARK: - Core Components
    let gameEngine: GameEngine
    let scoreManager: ScoreManager
    let inputValidator: InputValidator
    
    private var strategy: GameModeStrategy?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties (Forwarded from GameEngine)
    @Published var gameState: GameState = .idle
    @Published var selectedDifficulty: Difficulty? = nil
    @Published var words: [WordItem] = []
    @Published var currentIndex: Int = 0
    @Published var currentInput: String = ""
    @Published var teachingMode: TeachingMode = .normal
    @Published var isWrong: Bool = false
    @Published var showSuccess: Bool = false
    @Published var hintKey: String? = nil
    
    // UI 输入状态（与 TextField 绑定）
    @Published var internalInput: String = ""
    
    @Published var lastPressedKey: String? = nil
    @Published var lastWrongKey: String? = nil
    @Published var shakeTrigger: Int = 0
    @Published var pressTrigger: Int = 0
    @Published var showDamageFlash: Bool = false
    
    @Published var letterGameInput: String = ""
    @Published var letterGameTarget: String = ""
    @Published var letterGameRepeatsLeft: Int = 0
    @Published var letterGameRepeatsTotal: Int = 0
    @Published var letterGameDropToken: Int = 0
    @Published var letterGameHitFlash: Bool = false
    
    @Published var currentHealth: Int = GameSettings.shared.maxHealth
    @Published var timeRemaining: TimeInterval = GameSettings.shared.gameTimeLimit
    @Published var isTimerRunning: Bool = false
    
    // MARK: - Published Properties (ScoreManager)
    @Published var score: Int = 0
    @Published var coins: Int = 0
    @Published var earnedMoney: Double = 0.0
    @Published var moneyChange: Double = 0.0
    @Published var comboCount: Int = 0
    @Published var maxCombo: Int = 0
    @Published var comboProgress: Double = 0.0
    @Published var showFloatingScore: Bool = false
    @Published var floatingScoreValue: Int = 0
    
    @Published var floatingRewards: [FloatingReward] = []
    
    @Published var showTreasureEffect: Bool = false
    @Published var showMeteorEffect: Bool = false
    @Published var showLuckyDropEffect: Bool = false
    @Published var showMilestoneEffect: Bool = false
    @Published var milestoneProgress: Double = 0.0
    
    // MARK: - View Specific State
    @Published var showFireEffect: Bool = false
    @Published var showTTSDebugger: Bool = false
    @Published var showVirtualKeyboard: Bool = true
    @Published var showCoinDrop: Bool = false
    
    // MARK: - Typing Speed Statistics (Forwarded from ScoreManager)
    @Published var typingSpeedWPM: Double = 0.0
    @Published var isPausedForTTS: Bool = false

    // MARK: - Computed Properties
    var currentWord: WordItem {
        gameEngine.currentWord
    }
    
    var currentFingerType: String? {
        inputValidator.getFingerType(for: hintKey)
    }
    
    init() {
        self.gameEngine = GameEngine()
        self.scoreManager = self.gameEngine.scoreManager
        self.inputValidator = self.gameEngine.inputValidator
        
        setupBindings()
        setupEventBus()
    }
    
    private func setupBindings() {
        // Forward GameEngine properties
        gameEngine.$gameState.removeDuplicates().assign(to: &$gameState)
        gameEngine.$selectedDifficulty.removeDuplicates().assign(to: &$selectedDifficulty)
        gameEngine.$words.removeDuplicates().assign(to: &$words)
        gameEngine.$currentIndex.removeDuplicates().assign(to: &$currentIndex)
        gameEngine.$currentInput.removeDuplicates().assign(to: &$currentInput)
        
        // 同步 gameEngine.currentInput 到 internalInput，确保逻辑重置（如切题）时 UI 也重置
        gameEngine.$currentInput
            .removeDuplicates()
            .assign(to: &$internalInput)
            
        gameEngine.$teachingMode.removeDuplicates().assign(to: &$teachingMode)
        gameEngine.$isWrong.removeDuplicates().assign(to: &$isWrong)
        gameEngine.$showSuccess.removeDuplicates().assign(to: &$showSuccess)
        gameEngine.$hintKey.removeDuplicates().assign(to: &$hintKey)
        
        gameEngine.$lastPressedKey.removeDuplicates().assign(to: &$lastPressedKey)
        gameEngine.$lastWrongKey.removeDuplicates().assign(to: &$lastWrongKey)
        gameEngine.$shakeTrigger.removeDuplicates().assign(to: &$shakeTrigger)
        gameEngine.$pressTrigger.removeDuplicates().assign(to: &$pressTrigger)
        gameEngine.$showDamageFlash.removeDuplicates().assign(to: &$showDamageFlash)
        
        gameEngine.$letterGameInput.removeDuplicates().assign(to: &$letterGameInput)
        gameEngine.$letterGameTarget.removeDuplicates().assign(to: &$letterGameTarget)
        gameEngine.$letterGameRepeatsLeft.removeDuplicates().assign(to: &$letterGameRepeatsLeft)
        gameEngine.$letterGameRepeatsTotal.removeDuplicates().assign(to: &$letterGameRepeatsTotal)
        gameEngine.$letterGameDropToken.removeDuplicates().assign(to: &$letterGameDropToken)
        gameEngine.$letterGameHitFlash.removeDuplicates().assign(to: &$letterGameHitFlash)
        
        gameEngine.$currentHealth.removeDuplicates().assign(to: &$currentHealth)
        gameEngine.$timeRemaining.removeDuplicates().assign(to: &$timeRemaining)
        gameEngine.$isTimerRunning.removeDuplicates().assign(to: &$isTimerRunning)
        
        // Forward ScoreManager properties
        scoreManager.$score.removeDuplicates().assign(to: &$score)
        scoreManager.$coins.removeDuplicates().assign(to: &$coins)
        scoreManager.$earnedMoney.removeDuplicates().assign(to: &$earnedMoney)
        
        // Remove duplicate filtering for moneyChange to ensure UI updates even for same value changes
        scoreManager.$moneyChange.assign(to: &$moneyChange)
        
        scoreManager.$comboCount.removeDuplicates().assign(to: &$comboCount)
        scoreManager.$maxCombo.removeDuplicates().assign(to: &$maxCombo)
        scoreManager.$comboProgress.removeDuplicates().assign(to: &$comboProgress)
        scoreManager.$showFloatingScore.removeDuplicates().assign(to: &$showFloatingScore)
        scoreManager.$floatingScoreValue.removeDuplicates().assign(to: &$floatingScoreValue)
        scoreManager.$floatingRewards.removeDuplicates().assign(to: &$floatingRewards)
        
        scoreManager.$showTreasureEffect.removeDuplicates().assign(to: &$showTreasureEffect)
        scoreManager.$showMeteorEffect.removeDuplicates().assign(to: &$showMeteorEffect)
        scoreManager.$showLuckyDropEffect.removeDuplicates().assign(to: &$showLuckyDropEffect)
        scoreManager.$showMilestoneEffect.removeDuplicates().assign(to: &$showMilestoneEffect)
        scoreManager.$milestoneProgress.removeDuplicates().assign(to: &$milestoneProgress)
        
        scoreManager.$comboCount
            .map { $0 >= GameSettings.shared.fireEffectThreshold }
            .assign(to: &$showFireEffect)
        
        // Forward typing speed statistics
        scoreManager.$typingSpeedWPM.removeDuplicates().assign(to: &$typingSpeedWPM)
        scoreManager.$isPausedForTTS.removeDuplicates().assign(to: &$isPausedForTTS)
        
        // Handle Game Over
        gameEngine.onGameOver = { [weak self] in
            self?.handleGameOver()
        }
    }
    
    private func setupEventBus() {
        EventBus.shared.events
            .sink { [weak self] event in
                self?.handleEvent(event)
            }
            .store(in: &cancellables)
    }
    
    private func handleEvent(_ event: GameEvent) {
        switch event {
        case .difficultySelected(let difficulty):
            startGame(with: difficulty)
        case .resetGameProgress:
            gameEngine.resetCurrentIndex()
            scoreManager.resetScore() // Ensure score manager is reset too
            startGame()
        case .toggleSettings:
            // Handled by UI directly usually, but can toggle state here if needed
            break
        }
    }
    
    private func handleGameOver() {
        // Handle any ViewModel specific logic for game over
        // e.g. Analytics, or ensure UI state
        print("Game Over triggered in ViewModel")
    }
    
    // MARK: - User Actions
    
    func startGame(with difficulty: Difficulty) {
        gameEngine.selectedDifficulty = difficulty
        
        // Create Strategy
        if difficulty == .letterGame || difficulty == .homeRow {
            strategy = PracticeModeStrategy(gameEngine: gameEngine, scoreManager: scoreManager)
        } else {
            strategy = StandardModeStrategy(gameEngine: gameEngine, scoreManager: scoreManager, inputValidator: inputValidator)
        }
        
        startGame()
    }
    
    func startGame() {
        scoreManager.resetScore()
        strategy?.start()
    }
    
    func stopGame() {
        strategy?.stop()
        gameEngine.stopGame()
    }
    
    func exitToHome() {
        stopGame()
        gameEngine.selectedDifficulty = nil
        gameEngine.words = []
    }
    
    func handleInput(_ input: String) {
        strategy?.handleInput(input)
    }
    
    func handleLetterGameInput(_ input: String) {
        handleInput(input)
    }
    
    func checkInput() {
        // 使用 internalInput 作为输入源
        handleInput(internalInput)
        
        // 关键修复：如果在 handleInput 后，internalInput 与 gameEngine.currentInput 不一致，
        // 说明输入被逻辑层拒绝（如错误字符被回退）。
        // 此时必须强制将 internalInput 重置为 gameEngine.currentInput，
        // 从而消除 UI 输入框中的错误字符，防止其导致 UI 渲染错误。
        if internalInput != gameEngine.currentInput {
            internalInput = gameEngine.currentInput
        }
    }

    func previousTask() {
        guard !words.isEmpty else { return }
        let prevIndex = (currentIndex - 1 + words.count) % words.count
        strategy?.jumpToItem(at: prevIndex, speak: true)
    }
    
    func nextTask() {
        strategy?.nextItem()
    }
    
    func jumpToProgress(_ index: Int, speak: Bool = true) {
        strategy?.jumpToItem(at: index, speak: speak)
    }
    
    func resetGame() {
        guard let diff = selectedDifficulty else { return }
        startGame(with: diff)
    }
    
    // MARK: - Economy
    
    func buyHealth() {
        let cost = GameSettings.shared.healthCost
        if scoreManager.coins >= cost {
            scoreManager.deductCoins(cost)
            gameEngine.currentHealth = min(gameEngine.currentHealth + 1, GameSettings.shared.maxHealth)
            SoundManager.shared.playGetSmallMoney()
        } else {
            SoundManager.shared.playWrongLetter()
        }
    }
}

//
//  GameEngine.swift
//  xuedazi
//
//  Created by up on 2026/2/23.
//

import Foundation
import Combine
import SwiftUI

/// 负责核心游戏循环、状态管理和计时器逻辑
class GameEngine: ObservableObject {
    // MARK: - Published Properties
    
    @Published var timeRemaining: TimeInterval = GameSettings.shared.gameTimeLimit
    @Published var isTimerRunning: Bool = false
    @Published var gameState: GameState = .idle
    @Published var currentHealth: Int = GameSettings.shared.maxHealth
    
    // MARK: - Game State
    @Published var selectedDifficulty: Difficulty? = nil
    @Published var words: [WordItem] = []
    @Published var currentIndex: Int = 0
    @Published var currentInput: String = ""
    @Published var teachingMode: TeachingMode = .normal
    @Published var isWrong: Bool = false
    @Published var showSuccess: Bool = false
    @Published var hintKey: String? = nil
    
    // MARK: - Input Feedback State
    @Published var lastPressedKey: String? = nil
    @Published var lastWrongKey: String? = nil
    @Published var shakeTrigger: Int = 0
    @Published var pressTrigger: Int = 0
    @Published var showDamageFlash: Bool = false
    
    // MARK: - Letter Game State
    @Published var letterGameInput: String = ""
    @Published var letterGameTarget: String = ""
    @Published var letterGameRepeatsLeft: Int = 0
    @Published var letterGameRepeatsTotal: Int = 0
    @Published var letterGameDropToken: Int = 0
    @Published var letterGameHitFlash: Bool = false
    
    // MARK: - Private Properties
    
    // Timers are now managed by TimerManager
    
    // MARK: - Callbacks
    
    /// 游戏结束时的回调
    var onGameOver: (() -> Void)?
    
    // MARK: - Dependencies
    let scoreManager: ScoreManager
    let inputValidator: InputValidator
    
    // MARK: - Computed Properties
    var currentWord: WordItem {
        guard currentIndex >= 0 && currentIndex < words.count else {
            return WordItem(character: "", pinyin: "", displayPinyin: "", definition: "")
        }
        return words[currentIndex]
    }
    
    // MARK: - Initialization
    
    init(scoreManager: ScoreManager = ScoreManager(), inputValidator: InputValidator = InputValidator()) {
        self.scoreManager = scoreManager
        self.inputValidator = inputValidator
    }
    
    // MARK: - Game Loop Control
    
    func startNewGame() {
        gameState = .playing
        resetHealth()
        startTimer()
        resetInputState()
    }
    
    func resetCurrentIndex() {
        currentIndex = 0
    }
    
    func stopGame() {
        gameState = .idle
        stopTimer()
        SoundManager.shared.stopSpeaking()
        resetInputState()
        
        // Reset letter game state
        letterGameTarget = ""
        letterGameRepeatsLeft = 0
        letterGameRepeatsTotal = 0
        letterGameHitFlash = false
    }
    
    func pauseGame() {
        if gameState == .playing {
            gameState = .paused
            isTimerRunning = false
            TimerManager.shared.cancel(id: "gameTimer")
        }
    }
    
    func resumeGame() {
        if gameState == .paused {
            gameState = .playing
            isTimerRunning = true
            startTimer(resume: true)
        }
    }
    
    // MARK: - Timer Logic
    
    func startTimer(resume: Bool = false) {
        // Cancel existing timer first to be safe
        TimerManager.shared.cancel(id: "gameTimer")
        
        if !resume {
            timeRemaining = GameSettings.shared.gameTimeLimit
        }
        
        isTimerRunning = true
        
        guard timeRemaining > 0 else {
            isTimerRunning = false
            return
        }
        
        TimerManager.shared.schedule(
            id: "gameTimer",
            interval: 1.0,
            repeats: true
        ) { [weak self] in
            guard let self = self else { return }
            if self.gameState != .playing { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
                if self.timeRemaining <= 0 {
                    self.handleGameOver()
                }
            }
        }
    }
    
    func stopTimer() {
        isTimerRunning = false
        TimerManager.shared.cancel(id: "gameTimer")
    }
    
    // MARK: - Input State Management
    
    func resetInputState() {
        TimerManager.shared.cancel(id: "keyClear")
        TimerManager.shared.cancel(id: "wrongKeyClear")
        
        lastPressedKey = nil
        lastWrongKey = nil
        isWrong = false
        showSuccess = false
        currentInput = ""
        letterGameInput = ""
        hintKey = nil
    }
    
    func scheduleKeyClear() {
        TimerManager.shared.schedule(
            id: "keyClear",
            interval: 0.2,
            repeats: false
        ) { [weak self] in
            self?.lastPressedKey = nil
        }
    }
    
    func scheduleWrongKeyClear(completion: (() -> Void)? = nil) {
        TimerManager.shared.schedule(
            id: "wrongKeyClear",
            interval: 0.4,
            repeats: false
        ) { [weak self] in
            guard let self = self else { return }
            self.isWrong = false
            self.lastWrongKey = nil
            self.showDamageFlash = false
            completion?()
        }
    }
    
    func updateHintKey(targetChars: [Character]) {
        let index = currentInput.count
        hintKey = index < targetChars.count ? String(targetChars[index]) : nil
    }

    // MARK: - Health Logic
    
    func resetHealth() {
        currentHealth = GameSettings.shared.maxHealth
    }
    
    func reduceHealth(amount: Int) {
        if GameSettings.shared.maxHealth > 0 {
            currentHealth = max(0, currentHealth - amount)
            showDamageFlash = true
            
            if currentHealth == 0 {
                SoundManager.shared.playWrongLetter()
                // 延迟触发游戏结束，给用户一点反应时间
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.handleGameOver()
                }
            } else if currentHealth <= 2 {
                NarratorManager.shared.trigger(.lowHealth)
            }
        }
    }
    
    func increaseHealth(amount: Int) -> Bool {
        let maxHealth = GameSettings.shared.maxHealth
        if currentHealth >= maxHealth {
            return false
        }
        currentHealth = min(maxHealth, currentHealth + amount)
        return true
    }
    
    // MARK: - Private Methods
    
    func triggerGameOver() {
        handleGameOver()
    }
    
    private func handleGameOver() {
        gameState = .gameOver
        stopTimer()
        SoundManager.shared.stopSpeaking()
        NarratorManager.shared.trigger(.gameOver)
        onGameOver?()
    }
}

// MARK: - GameEngineProtocol Conformance
extension GameEngine: GameEngineProtocol {
    // Protocol requirements are satisfied by the class implementation
}

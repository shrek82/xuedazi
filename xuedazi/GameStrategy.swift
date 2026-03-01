//
//  GameStrategy.swift
//  xuedazi
//
//  Created by up on 2026/2/22.
//

import Foundation
import SwiftUI

protocol GameModeStrategy {
    func start()
    func stop()
    func handleInput(_ input: String)
    func nextItem()
    func jumpToItem(at index: Int, speak: Bool)
}

// Default implementation for optional methods
extension GameModeStrategy {
    func nextItem() {}
    func jumpToItem(at index: Int, speak: Bool = true) {}
}

class StandardModeStrategy: GameModeStrategy {
    unowned let gameEngine: GameEngineProtocol
    unowned let scoreManager: ScoreManager
    unowned let inputValidator: InputValidator
    
    // Mode-specific state
    var currentPinyinMap: [Int] = []
    var lastCompletedCharIndex: Int = -1
    // 存储每个汉字拼音结束的长度：[累计拼音长度: 汉字索引]
    // 例如 "ma dao": [2: 0, 5: 1] (ma结束于2，对应第0个字；dao结束于5，对应第1个字)
    var pinyinBreakpoints: [Int: Int] = [:]
    var hasStartedInput: Bool = false
    var hasSpokenInitialWord: Bool = false
    
    init(gameEngine: GameEngineProtocol, scoreManager: ScoreManager, inputValidator: InputValidator) {
        self.gameEngine = gameEngine
        self.scoreManager = scoreManager
        self.inputValidator = inputValidator
    }
    
    func start() {
        guard !WordRepository.shared.hasLoaded() else {
            self.setupGame()
            return
        }
        
        WordRepository.shared.loadWords()
        self.setupGame()
    }
    
    private func setupGame() {
        guard let difficulty = gameEngine.selectedDifficulty else { return }
        
        gameEngine.words = WordRepository.shared.getWords(for: difficulty)
        
        // Use GameEngine to start game
        gameEngine.startNewGame()
        
        gameEngine.isWrong = false
        gameEngine.showSuccess = false
        
        // Reset Progress (Handled by ScoreManager)
        
        // Load progress
        let savedIndex = PlayerProgress.shared.loadProgress(difficulty: difficulty)
        gameEngine.currentIndex = min(max(0, savedIndex), gameEngine.words.count - 1)
        
        gameEngine.currentInput = ""
        // Score/Money managed by ScoreManager
        
        lastCompletedCharIndex = -1
        hasStartedInput = false
        hasSpokenInitialWord = false
        
        // Init pinyin map
        if !gameEngine.words.isEmpty {
            let currentWord = gameEngine.words[gameEngine.currentIndex]
            rebuildPinyinBreakpoints(for: currentWord)
            
            // 预加载当前词和下一个词
            var preloadList: [String] = [currentWord.character]
            if gameEngine.words.count > 1 {
                let nextIndex = (gameEngine.currentIndex + 1) % gameEngine.words.count
                preloadList.append(gameEngine.words[nextIndex].character)
            }
            SoundManager.shared.preloadTexts(preloadList)
            
            // Update hint
            let targetPinyin = inputValidator.getTargetPinyin(from: currentWord)
            let targetChars = Array(targetPinyin)
            gameEngine.updateHintKey(targetChars: targetChars)
            
            // TTS
            if NarratorManager.shared.isEnabled {
                let initialIndex = gameEngine.currentIndex
                NarratorManager.shared.trigger(.gameStart) { [weak self] in
                    guard let self = self,
                          self.gameEngine.gameState == .playing,
                          self.gameEngine.currentIndex == initialIndex,
                          !self.hasSpokenInitialWord,
                          !self.hasStartedInput else { return }
                    
                    DispatchQueue.main.async {
                        self.speakWord()
                        self.hasSpokenInitialWord = true
                    }
                }
            } else {
                NarratorManager.shared.trigger(.gameStart)
                speakWord()
                hasSpokenInitialWord = true
            }
        }
    }
    
    func stop() {
        SoundManager.shared.stopSpeaking()
        
        // Save progress
        if let diff = gameEngine.selectedDifficulty {
            PlayerProgress.shared.saveProgress(difficulty: diff, index: gameEngine.currentIndex)
        }
    }
    
    func handleInput(_ input: String) {
        guard gameEngine.gameState == .playing else { return }
        
        if !hasStartedInput {
            hasStartedInput = true
            if NarratorManager.shared.isEnabled {
                NarratorManager.shared.stopSpeaking()
            }
            
            // 关键逻辑：如果旁白还在说话（或没说完），此时用户已经开始输入
            // 必须立即停止旁白，并朗读首句（如果还没读过）
            SoundManager.shared.stopSpeaking()
            
            if !hasSpokenInitialWord {
                speakWord()
                hasSpokenInitialWord = true
            }
        }
        
        // 防止在单词完成后的过渡期（延迟跳转期间）输入导致错误
        if gameEngine.showSuccess {
            return
        }
        
        // 清洗输入
        let allowedLetters = inputValidator.allowedLetters
        let cleaned = String(input.lowercased().filter { allowedLetters.contains($0) })
        if cleaned != input {
            gameEngine.currentInput = cleaned
            return
        }
        
        // 获取当前有效的输入前缀
        let currentValidInput = gameEngine.currentInput
        
        // 1. 处理删除操作 (backspace)
        if cleaned.count < currentValidInput.count {
            // 如果新输入比当前有效输入短，说明是删除，直接更新
            gameEngine.currentInput = cleaned
            
            // 更新指法提示
            if !gameEngine.words.isEmpty {
                let currentWord = gameEngine.words[gameEngine.currentIndex]
                let targetPinyin = inputValidator.getTargetPinyin(from: currentWord)
                gameEngine.updateHintKey(targetChars: Array(targetPinyin))
            }
            return
        }
        
        // 2. 处理新增输入 (可能是单个字符，也可能是多个字符如粘贴或快速输入)
        // 我们只关心相对于 currentValidInput 新增的部分
        if cleaned.count > currentValidInput.count {
            // 检查新输入是否以有效输入为前缀
            // 如果不是（例如光标移动后插入），则可能需要重置或特殊处理
            // 这里简化处理：如果不匹配前缀，视为非法状态，强制重置为有效输入
            if !cleaned.hasPrefix(currentValidInput) {
                gameEngine.currentInput = currentValidInput
                return
            }
            
            // 获取新增的字符部分
            let newPart = cleaned.dropFirst(currentValidInput.count)
            
            // 逐个字符验证
            // 这一点至关重要：防止一次输入多个字符时，跳过中间的错误字符
            var tempInput = currentValidInput
            
            for char in newPart {
                // 构造尝试性的新输入状态
                let nextInput = tempInput + String(char)
                
                // 验证这个字符
                if validateSingleChar(input: nextInput, char: char) {
                    // 如果正确，更新临时状态，继续验证下一个
                    tempInput = nextInput
                } else {
                    // 如果错误，validateSingleChar 内部已经处理了错误反馈（扣分、音效等）
                    // 并且我们应该立即停止处理后续字符
                    // 最终状态应停留在错误发生前
                    // 强制更新 currentInput 为错误前的状态，以同步 UI
                    gameEngine.currentInput = tempInput
                    return
                }
            }
            
            // 如果所有新字符都验证通过，更新最终状态
            gameEngine.currentInput = tempInput
        }
    }
    
    // 返回 true 表示验证通过，false 表示错误
    private func validateSingleChar(input: String, char: Character) -> Bool {
        guard !gameEngine.words.isEmpty else { return false }
        let currentWord = gameEngine.words[gameEngine.currentIndex]
        
        let targetPinyin = inputValidator.getTargetPinyin(from: currentWord)
        let targetChars = Array(targetPinyin)
        let inputChars = Array(input)
        
        // 记录按键（用于 UI 键盘动画）
        gameEngine.lastPressedKey = String(char)
        gameEngine.scheduleKeyClear()
        gameEngine.pressTrigger += 1
        SoundManager.shared.playKeyPress()
        
        // 检查长度是否溢出
        if inputChars.count > targetChars.count {
            handleWrongInput(char: char, index: inputChars.count - 1)
            return false
        }
        
        // 检查当前字符是否正确
        let index = inputChars.count - 1
        if inputChars[index] == targetChars[index] {
            // 正确
            handleCorrectInput(char: char, index: index)
            checkCharCompletion(currentLength: inputChars.count)
            
            // 先更新状态
            gameEngine.currentInput = input
            
            // 检查是否完成整个词
            if inputChars.count == targetChars.count {
                handleWordCompletion()
                triggerWordCompletionSequence()
            } else {
                // 更新提示：输入正确后，更新下一个待输入字母的提示
                // 注意：必须在 currentInput 更新之后调用，以确保索引正确
                gameEngine.updateHintKey(targetChars: targetChars)
            }
            return true
        } else {
            // 错误
            handleWrongInput(char: char, index: index)
            return false
        }
    }
    
    private func handleCorrectInput(char: Character, index: Int) {
        SoundManager.shared.playCorrectLetter()
        SoundManager.shared.recordInput()  // 记录输入时间，用于智能 TTS 语速调整
        
        // 增加金币 (确保只有配置大于0时才增加)
        let money = GameSettings.shared.moneyPerLetter
        if money > 0 {
            scoreManager.addMoney(money)
        }
        
        scoreManager.incrementCombo()
        scoreManager.incrementCorrectLetters()
        
        // 触发幸运掉落
        checkLuckyDrop(char: char)
    }
    
    private func handleWrongInput(char: Character, index: Int) {
        gameEngine.isWrong = true
        // 关键修复：输入错误时，currentInput 不应该更新为错误的输入，
        // 但为了让 UI 显示红色错误状态，可能需要某种方式通知 View。
        // 原逻辑中，validateInput 里已经做了 `gameEngine.currentInput = String(input.dropLast())` 回退。
        // 这导致 typedCount 没有增加，UI 重新渲染时，这个字符被认为是“未输入”状态，而不是“错误”状态。
        
        // 方案：isWrong 状态应该能覆盖“当前等待输入的字符”的颜色。
        // AlignedInputView 的 getPinyinCharColor 逻辑中：
        // `if relativeTyped == range.start ... return isWrong ? Red : Yellow`
        // 当 currentInput 回退后，relativeTyped 指向的就是当前字符。
        // 只要 isWrong 为 true，它就应该变红。
        
        gameEngine.lastWrongKey = String(char)
        gameEngine.shakeTrigger += 1
        
        scoreManager.resetCombo()
        
        // 扣除金币
        scoreManager.applyPenalty(GameSettings.shared.penaltyPerError)
        
        if GameSettings.shared.maxHealth > 0 {
            gameEngine.reduceHealth(amount: GameSettings.shared.healthPerError)
        }
        
        SoundManager.shared.playWrongLetter()
        NarratorManager.shared.trigger(.error)
        
        if GameSettings.shared.maxHealth > 0 && gameEngine.currentHealth <= 2 && gameEngine.currentHealth > 0 {
            NarratorManager.shared.trigger(.lowHealth)
        }
        
        let safeIndex = gameEngine.currentInput.index(gameEngine.currentInput.startIndex, offsetBy: index, limitedBy: gameEngine.currentInput.endIndex) ?? gameEngine.currentInput.endIndex
        // let prefix = gameEngine.currentInput[..<safeIndex]
        let currentWord = gameEngine.words[gameEngine.currentIndex]
        let targetPinyin = inputValidator.getTargetPinyin(from: currentWord)
        let targetChars = Array(targetPinyin)
        
        gameEngine.scheduleWrongKeyClear { [weak self] in
            // Update hint after error clear
             self?.gameEngine.updateHintKey(targetChars: targetChars)
        }
    }
    
    private func checkCharCompletion(currentLength: Int) {
        if let charIndex = pinyinBreakpoints[currentLength] {
            // 完成了第 charIndex 个汉字
            if charIndex > lastCompletedCharIndex {
                lastCompletedCharIndex = charIndex
                
                let currentWord = gameEngine.words[gameEngine.currentIndex]
                
                // 优化单字模式：如果是单字，不在这里朗读
                // 留给 speakAndJump 统一处理，以确保能通过 completion 回调控制跳转时机
                if currentWord.character.count == 1 {
                    return
                }
                
                if charIndex == 0 {
                    SoundManager.shared.stopSpeaking()
                }
                
                let wordChars = Array(currentWord.character)
                if charIndex < wordChars.count {
                    let charToSpeak = String(wordChars[charIndex])
                    speakCharacter(charToSpeak)
                }
            }
        }
    }
    
    private func checkLuckyDrop(char: Character) {
        // 幸运掉落逻辑 (5% 概率)
        // 从 CoreMemory 获取规则：Lucky Drop Trigger Logic
        // "Random rewards (Lucky Drop) are triggered per correct letter input (high frequency)"
        
        scoreManager.checkLuckyDrop()
    }
    
    private func handleWordCompletion() {
        SoundManager.shared.playSuccess()
        let comboBonus = min(scoreManager.comboCount / 5 * 2, 20)
        scoreManager.addScore(10 + comboBonus)
        gameEngine.showSuccess = true
    }
    
    private func triggerWordCompletionSequence() {
        guard gameEngine.selectedDifficulty != nil else { return }
        let delay = GameSettings.shared.delayBeforeSpeak
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.speakAndJump()
            }
        } else {
            speakAndJump()
        }
    }
    
    private func speakAndJump() {
        guard !gameEngine.words.isEmpty else { return }
        let currentWord = gameEngine.words[gameEngine.currentIndex]
        let isSingleCharWord = currentWord.character.count == 1
        
        // 单字模式：刚才已经朗读过该字（作为单字），无需再次朗读
        // 修正逻辑：单字模式下，checkCharCompletion 已经跳过了朗读
        // 所以这里应该朗读一次，确保“全部拼音输入后，还能听到一次完整的朗读”
        // 但是，题目要求“单字模式...最多只完整的读2次”（开始一次，输入完一次）
        
        speakWord { [weak self] in
            guard let self = self else { return }
            var delay = GameSettings.shared.delayStandard
            if let diff = self.gameEngine.selectedDifficulty {
                if diff == .article { delay = GameSettings.shared.delayArticle }
                else if diff == .hard { delay = GameSettings.shared.delayHard }
                else if diff == .xiehouyu { delay = GameSettings.shared.delayXiehouyu }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.nextItem()
            }
        }
    }
    
    func nextItem() {
        guard !gameEngine.words.isEmpty else { return }
        
        jumpToItem(at: gameEngine.currentIndex + 1)
    }
    
    func jumpToItem(at index: Int, speak: Bool = true) {
        guard !gameEngine.words.isEmpty else { return }
        
        // 方案2优化：在跳跃时，立即停止之前的语音，防止堆积
        SoundManager.shared.stopSpeaking()
        
        // Save progress for current item before moving
        if let diff = gameEngine.selectedDifficulty {
            PlayerProgress.shared.saveProgress(difficulty: diff, index: gameEngine.currentIndex)
        }
        
        gameEngine.showSuccess = false
        gameEngine.isWrong = false
        lastCompletedCharIndex = -1
        
        // Update index
        let newIndex = index % gameEngine.words.count
        gameEngine.currentIndex = newIndex
        gameEngine.currentInput = ""
        
        // Update state
        let currentWord = gameEngine.words[gameEngine.currentIndex]
        rebuildPinyinBreakpoints(for: currentWord)
        
        let targetPinyin = inputValidator.getTargetPinyin(from: currentWord)
        let targetChars = Array(targetPinyin)
        gameEngine.updateHintKey(targetChars: targetChars)
        
        // Preload next
        var preloadList: [String] = [currentWord.character]
        if gameEngine.words.count > 1 {
            let nextIndex = (gameEngine.currentIndex + 1) % gameEngine.words.count
            preloadList.append(gameEngine.words[nextIndex].character)
        }
        SoundManager.shared.preloadTexts(preloadList)
        
        // 方案1优化：只有在 speak 为 true 时才朗读
        if speak {
            speakWord()
        }
    }
    
    private func speakWord(completion: (() -> Void)? = nil) {
        guard !gameEngine.words.isEmpty else { return }
        let text = "\(gameEngine.words[gameEngine.currentIndex].character)"
        SoundManager.shared.speak(text: text, completion: completion)
    }
    
    private func speakCharacter(_ character: String, completion: (() -> Void)? = nil) {
        // 智能语速：如果用户输入很快（积压的TTS任务多），稍微加快语速
        // 这里简化处理：单字朗读通常需要清晰，所以不建议过度加速
        // 但为了防止积压，可以先停止之前的（如果是上一个字的读音）
        
        // SoundManager.shared.stopSpeaking() // 过于激进，可能会打断当前的
        
        let rate = SoundManager.shared.getSuggestedRateMultiplier()
        SoundManager.shared.speak(text: character, rateMultiplier: rate, completion: completion)
    }

    private func rebuildPinyinBreakpoints(for word: WordItem) {
        currentPinyinMap = word.buildPinyinIndexMap()
        pinyinBreakpoints.removeAll()
        if !currentPinyinMap.isEmpty {
            for i in 0..<(currentPinyinMap.count - 1) {
                if currentPinyinMap[i] != currentPinyinMap[i + 1] {
                    pinyinBreakpoints[i + 1] = currentPinyinMap[i]
                }
            }
            pinyinBreakpoints[currentPinyinMap.count] = currentPinyinMap.last!
        }
    }
    
    private func isPunctuation(_ char: String) -> Bool {
        let punctuationChars: [String] = [
            "，", "。", "、", "？", "！", "：", "；",
            "\u{201C}", "\u{201D}", "\u{2018}", "\u{2019}",
            "（", "）", "【", "】", "《", "》", "…", "—",
            ",", ".", "?", "!", ":", ";",
            "\"", "'", "(", ")", "[", "]", "<", ">"
        ]
        return punctuationChars.contains(char)
    }
}

class PracticeModeStrategy: GameModeStrategy {
    unowned let gameEngine: GameEngineProtocol
    unowned let scoreManager: ScoreManager
    
    private let letterGameSequence: [String] = Array("bpmfdtnlgkhjqxzhchshrzcsyw").map { String($0) }
    private let homeRowSequence: [String] = Array("asdfghjkl").map { String($0) }
    private var currentPracticeSequence: [String] = []
    private var letterGameIndex: Int = 0
    
    init(gameEngine: GameEngineProtocol, scoreManager: ScoreManager) {
        self.gameEngine = gameEngine
        self.scoreManager = scoreManager
    }
    
    func start() {
        guard let difficulty = gameEngine.selectedDifficulty else { return }
        
        gameEngine.words = []
        gameEngine.teachingMode = .normal
        
        gameEngine.startNewGame()
        
        gameEngine.resetInputState()
        gameEngine.currentIndex = 0
        gameEngine.currentInput = ""
        scoreManager.resetCombo()
        gameEngine.letterGameInput = ""
        letterGameIndex = 0
        
        currentPracticeSequence = (difficulty == .homeRow) ? homeRowSequence : letterGameSequence
        
        gameEngine.letterGameTarget = currentPracticeSequence.first ?? ""
        gameEngine.letterGameRepeatsLeft = Int.random(in: 1...5)
        gameEngine.letterGameRepeatsTotal = gameEngine.letterGameRepeatsLeft
        gameEngine.hintKey = gameEngine.letterGameTarget.isEmpty ? nil : gameEngine.letterGameTarget
        gameEngine.letterGameDropToken += 1
        
        // 播报当前目标字母
        speakTarget()
    }
    
    func stop() {
        SoundManager.shared.stopSpeaking()
    }
    
    func handleInput(_ input: String) {
        guard gameEngine.gameState == .playing else { return }
        
        // 防止在字母完成后的过渡期（延迟跳转期间）输入导致错误
        if gameEngine.letterGameHitFlash {
            return
        }
        
        SoundManager.shared.playKeyPress()
        
        let allowedLetters = Set("abcdefghijklmnopqrstuvwxyz")
        let cleaned = String(input.lowercased().filter { allowedLetters.contains($0) })
        if cleaned != input {
            gameEngine.letterGameInput = cleaned
            return
        }
        guard let last = cleaned.last else { return }
        
        gameEngine.lastPressedKey = String(last)
        gameEngine.scheduleKeyClear()
        
        let targetChar = gameEngine.letterGameTarget.lowercased()
        if String(last) == targetChar {
            handleCorrectInput()
        } else {
            handleWrongInput(char: last)
        }
        
        gameEngine.letterGameInput = ""
    }
    
    private func handleCorrectInput() {
        SoundManager.shared.playCorrectLetter()
        scoreManager.addScore(1)
        
        // 增加金币 (确保只有配置大于0时才增加)
        let money = GameSettings.shared.moneyPerLetter
        if money > 0 {
            scoreManager.addMoney(money)
        }
        
        scoreManager.incrementCombo()
        scoreManager.incrementCorrectLetters()
        scoreManager.checkLuckyDrop()
        gameEngine.letterGameHitFlash = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            self.gameEngine.letterGameHitFlash = false
            self.gameEngine.letterGameRepeatsLeft -= 1
            
            if self.gameEngine.letterGameRepeatsLeft <= 0 {
                self.letterGameIndex = (self.letterGameIndex + 1) % self.currentPracticeSequence.count
                self.gameEngine.letterGameTarget = self.currentPracticeSequence[self.letterGameIndex]
                self.gameEngine.letterGameRepeatsLeft = Int.random(in: 1...5)
                self.gameEngine.letterGameRepeatsTotal = self.gameEngine.letterGameRepeatsLeft
            }
            
            self.gameEngine.hintKey = self.gameEngine.letterGameTarget.isEmpty ? nil : self.gameEngine.letterGameTarget
            self.gameEngine.letterGameDropToken += 1
            
            // 播报新的目标字母
            self.speakTarget()
        }
    }
    
    private func speakTarget() {
        let text = gameEngine.letterGameTarget
        guard !text.isEmpty else { return }
        SoundManager.shared.speak(text: text)
    }
    
    private func handleWrongInput(char: Character) {
        gameEngine.isWrong = true
        gameEngine.lastWrongKey = String(char)
        gameEngine.shakeTrigger += 1
        
        scoreManager.resetCombo()
        
        // 扣除金币
        scoreManager.applyPenalty(GameSettings.shared.penaltyPerError)
        
        if GameSettings.shared.maxHealth > 0 {
            gameEngine.reduceHealth(amount: GameSettings.shared.healthPerError)
        }
        
        SoundManager.shared.playWrongLetter()
        NarratorManager.shared.trigger(.error)
        
        if GameSettings.shared.maxHealth > 0 && gameEngine.currentHealth <= 2 && gameEngine.currentHealth > 0 {
            NarratorManager.shared.trigger(.lowHealth)
        }
        gameEngine.scheduleWrongKeyClear { [weak self] in
            // Practice modes manage hintKey directly
            guard let self = self else { return }
            self.gameEngine.hintKey = self.gameEngine.letterGameTarget.isEmpty ? nil : self.gameEngine.letterGameTarget
        }
    }
}

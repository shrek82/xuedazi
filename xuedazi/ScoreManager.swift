//
//  ScoreManager.swift
//  xuedazi
//
//  Created by up on 2026/2/22.
//

import Foundation
import SwiftUI
import Combine

struct FloatingReward: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let color: Color
    let type: RewardType
    
    enum RewardType: Equatable {
        case combo
        case lucky
        case milestone
        case treasure
        case meteor
    }
}

class ScoreManager: ObservableObject {
    // 全局分数和金钱
    @Published var score: Int = PlayerProgress.shared.totalScore {
        didSet {
            PlayerProgress.shared.totalScore = score
        }
    }
    
    @Published var earnedMoney: Double = PlayerProgress.shared.totalMoney {
        didSet {
            PlayerProgress.shared.totalMoney = earnedMoney
            coins = Int(earnedMoney)
        }
    }
    
    // 金币整数代理
    @Published var coins: Int = Int(PlayerProgress.shared.totalMoney)
    
    @Published var moneyChange: Double = 0.0  // 金额变化（用于动画）
    
    // 连击系统
    @Published var comboCount: Int = PlayerProgress.shared.currentCombo {
        didSet {
            PlayerProgress.shared.currentCombo = comboCount
            if comboCount > PlayerProgress.shared.maxCombo {
                PlayerProgress.shared.maxCombo = comboCount
                maxCombo = comboCount
            }
        }
    }
    
    @Published var maxCombo: Int = PlayerProgress.shared.maxCombo
    @Published var comboProgress: Double = 0.0
    
    // 阶段奖励
    @Published var milestoneProgress: Double = 0.0
    @Published var showMilestoneEffect: Bool = false
    
    // 随机特效
    @Published var showTreasureEffect: Bool = false
    @Published var showMeteorEffect: Bool = false
    @Published var showLuckyDropEffect: Bool = false
    
    // 浮动奖励
    @Published var floatingRewards: [FloatingReward] = []
    
    // 兼容 GameViewModel
    
    // MARK: - Typing Speed Statistics
    /// 当前轮游戏的输入速度统计（字/分钟）
    @Published var typingSpeedWPM: Double = 0.0
    
    /// 当前轮累计正确输入的字母数（用于速度统计）
    private var sessionCorrectLetters: Int = 0
    
    /// 当前轮游戏开始时间
    private var sessionStartTime: Date?
    
    /// 是否在 TTS 朗读或跳转等待中（用于 UI 显示）
    @Published var isPausedForTTS: Bool = false
    @Published var showFloatingScore: Bool = false
    @Published var floatingScoreValue: Int = 0
    
    // 火焰特效
    var showFireEffect: Bool {
        return comboCount >= GameSettings.shared.fireEffectThreshold
    }
    
    // 称号计算
    var currentRank: String {
        if score < 100 { return "拼音小萌新" }
        if score < 300 { return "拼音小能手" }
        if score < 600 { return "拼音大达人" }
        if score < 1000 { return "拼音大宗师" }
        return "拼音传说"
    }
    
    init() {
        // Initial calculation of progress
        updateProgress()
    }
    
    func reset() {
        score = 0
        earnedMoney = 0.0
        moneyChange = 0.0
        comboCount = 0
        // maxCombo kept as historical record
        updateProgress()
    }
    
    func resetScore() {
        reset()
        resetTypingSpeedStats()
    }
    
    // MARK: - Typing Speed Management
    
    /// 开始新一轮游戏，重置速度统计
    func startNewSession() {
        sessionStartTime = Date()
        sessionCorrectLetters = 0
        typingSpeedWPM = 0.0
        isPausedForTTS = false
    }
    
    /// 重置速度统计
    func resetTypingSpeedStats() {
        sessionStartTime = nil
        sessionCorrectLetters = 0
        typingSpeedWPM = 0.0
        isPausedForTTS = false
    }
    
    /// 记录正确输入一个字母（用于速度统计）
    func recordCorrectLetter() {
        sessionCorrectLetters += 1
        updateTypingSpeed()
    }
    
    /// 更新输入速度（字/分钟）
    /// 计算公式：速度 = 正确输入字母数 / 从游戏开始到现在的总时间
    /// 注意：为了简化逻辑，不排除 TTS 暂停时间，因为 TTS 时间相对较短
    func updateTypingSpeed() {
        guard let startTime = sessionStartTime else {
            typingSpeedWPM = 0.0
            return
        }
        
        // 计算从游戏开始到现在的总时间
        let totalTime = Date().timeIntervalSince(startTime)
        
        // 限制最小有效时间为 0.5 秒，避免初始速度过大
        guard totalTime >= 0.5 else {
            typingSpeedWPM = 0.0
            return
        }
        
        // 计算速度：字母数 / 时间 (分钟)
        let timeInMinutes = totalTime / 60.0
        if timeInMinutes > 0 {
            typingSpeedWPM = Double(sessionCorrectLetters) / timeInMinutes
        } else {
            typingSpeedWPM = 0.0
        }
    }
    
    func deductCoins(_ amount: Int) {
        earnedMoney = max(0, earnedMoney - Double(amount))
    }
    
    func addScore(_ amount: Int) {
        score += amount
    }
    
    func addMoney(_ amount: Double) {
        if amount > 0 {
            earnedMoney += amount
            moneyChange = amount
            
            // 确保金币代理属性更新
            coins = Int(earnedMoney)
        }
    }
    
    func applyPenalty(_ amount: Double) {
        if amount > 0 {
            earnedMoney = max(0, earnedMoney - amount)
            moneyChange = -amount
            coins = Int(earnedMoney)
        }
    }
    
    func incrementCombo() {
        comboCount += 1
        checkRewards()
    }
    
    func resetCombo() {
        comboCount = 0
        updateProgress() // Reset progress visualization
    }
    
    func incrementCorrectLetters() {
        PlayerProgress.shared.totalCorrectLetters += 1
        checkMilestoneRewards()
    }
    
    private func updateProgress() {
        // Update Combo Progress
        let comboThreshold = GameSettings.shared.comboBonusThreshold
        if comboThreshold > 0 {
            comboProgress = Double(comboCount % comboThreshold) / Double(comboThreshold)
        } else {
            comboProgress = 0.0
        }
        
        // Update Milestone Progress
        let milestone = GameSettings.shared.milestoneLetterCount
        let completedCount = PlayerProgress.shared.totalCorrectLetters
        if milestone > 0 {
            milestoneProgress = Double(completedCount % milestone) / Double(milestone)
        } else {
            milestoneProgress = 0.0
        }
    }
    
    private func checkRewards() {
        updateProgress()
        
        let comboThreshold = GameSettings.shared.comboBonusThreshold
        
        // 1. 连击奖励
        if comboCount > 0 && comboCount % comboThreshold == 0 {
            // Full progress for a moment before reset (handled by next update)
            comboProgress = 1.0
            
            let bonus = GameSettings.shared.comboBonusMoney
            addMoney(bonus)
            
            addFloatingReward(text: "连击 x\(comboCount) +\(String(format: "%.3f", bonus))金币", color: .themeAmberYellow, type: .combo)
            SoundManager.shared.playGetSmallMoney()
            
            // 触发旁白
            NarratorManager.shared.trigger(.combo(comboCount))
        }
    }
    
    private func checkMilestoneRewards() {
        updateProgress()
        
        let milestone = GameSettings.shared.milestoneLetterCount
        let completedCount = PlayerProgress.shared.totalCorrectLetters
        
        // 确保随机特效互斥，每次最多触发一个
        // 优先级顺序：随机宝藏 > 随机流星 > 幸运掉落
        // 阶段奖励 (Milestone) 是固定规则，不参与互斥，可以和随机特效同时发生
        
        var randomEffectTriggered = false
        
        // 2. 随机宝藏 (Treasure) - 最高优先级
        if !randomEffectTriggered {
            randomEffectTriggered = checkRandomTreasure()
        }
        
        // 3. 随机流星 (Meteor)
        if !randomEffectTriggered {
            randomEffectTriggered = checkRandomMeteor()
        }
        
        // 4. 随机奖励 (Lucky Drop)
        if !randomEffectTriggered {
            randomEffectTriggered = checkLuckyDrop()
        }
        
        // 5. 阶段奖励 (Session Milestone) - 独立逻辑
        if completedCount > 0 && completedCount % milestone == 0 {
            let bonus = GameSettings.shared.milestoneBonusMoney
            addMoney(bonus)
            
            addFloatingReward(text: "阶段达成! +\(String(format: "%.3f", bonus))金币", color: .themeSuccessGreen, type: .milestone)
            SoundManager.shared.playGetBigMoney()
            
            // 触发旁白
            NarratorManager.shared.trigger(.milestone)
            
            // 触发里程碑特效
            showMilestoneEffect = true
            // 延长全屏彩带雨持续时间到 6 秒
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
                self?.showMilestoneEffect = false
            }
        }
    }
    
    /// 触发幸运掉落检查 (通常在单词完成时调用)
    /// - Returns: 是否触发了特效
    @discardableResult
    func checkLuckyDrop() -> Bool {
        if Double.random(in: 0...1) < GameSettings.shared.randomRewardChance {
            let min = GameSettings.shared.randomRewardMin
            let max = GameSettings.shared.randomRewardMax
            let bonus = Double.random(in: min...max)
            
            addMoney(bonus)
            addFloatingReward(text: "幸运奖励! +\(String(format: "%.3f", bonus))金币", color: .pink, type: .lucky)
            SoundManager.shared.playGetBigMoney()
            
            withAnimation {
                showLuckyDropEffect = true
            }
            
            // 4.0秒后自动移除 (配合特效最大持续时间)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
                withAnimation {
                    self?.showLuckyDropEffect = false
                }
            }
            
            return true
        }
        return false
    }
    
    /// 触发随机宝藏检查
    /// - Returns: 是否触发了特效
    @discardableResult
    func checkRandomTreasure() -> Bool {
        if Double.random(in: 0...1) < GameSettings.shared.randomTreasureChance {
            let min = GameSettings.shared.randomTreasureMin
            let max = GameSettings.shared.randomTreasureMax
            let bonus = Double.random(in: min...max)
            
            addMoney(bonus)
            addFloatingReward(text: "宝藏降临! +\(String(format: "%.3f", bonus))金币", color: .yellow, type: .treasure)
            SoundManager.shared.playTreasureSound()
            
            withAnimation {
                showTreasureEffect = true
            }
            
            // 持续时间根据音频长度大概是4秒左右，这里设置稍微长一点
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
                withAnimation {
                    self?.showTreasureEffect = false
                }
            }
            return true
        }
        return false
    }
    
    /// 触发随机流星检查
    /// - Returns: 是否触发了特效
    @discardableResult
    func checkRandomMeteor() -> Bool {
        if Double.random(in: 0...1) < GameSettings.shared.randomMeteorChance {
            let min = GameSettings.shared.randomMeteorMin
            let max = GameSettings.shared.randomMeteorMax
            let bonus = Double.random(in: min...max)
            
            addMoney(bonus)
            addFloatingReward(text: "流星划过! +\(String(format: "%.3f", bonus))金币", color: .cyan, type: .meteor)
            SoundManager.shared.playMeteorSound()
            
            withAnimation {
                showMeteorEffect = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                withAnimation {
                    self?.showMeteorEffect = false
                }
            }
            return true
        }
        return false
    }
    
    func addFloatingReward(text: String, color: Color, type: FloatingReward.RewardType) {
        let reward = FloatingReward(text: text, color: color, type: type)
        
        withAnimation(.spring()) {
            floatingRewards.append(reward)
        }
        
        // Use Task for better lifecycle management
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Ensure removal triggers animation if needed
            withAnimation {
                self?.floatingRewards.removeAll(where: { $0.id == reward.id })
            }
        }
    }
}

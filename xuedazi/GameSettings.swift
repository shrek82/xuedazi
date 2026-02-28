//
//  GameSettings.swift
//  xuedazi
//
//  Created by up on 2026/2/23.
//

import Foundation
import Combine

/// 全局游戏配置 (不包含用户进度)
class GameSettings: ObservableObject {
    static let shared = GameSettings()
    
    // MARK: - Economy Settings
    @Published var moneyPerLetter: Double = 0.05  // 每成功输入一个字母赚取的金额（金币）
    @Published var penaltyPerError: Double = 0.0  // 每输错一个字母扣除的金额（金币）
    
    // MARK: - Health Settings
    @Published var maxHealth: Int = 5             // 最大生命值
    @Published var healthPerError: Int = 1        // 错误扣除生命值
    @Published var costPerHealth: Double = 5.0    // 购买生命值所需金币
    
    var healthCost: Int { Int(costPerHealth) }
    
    // MARK: - Time Settings
    @Published var gameTimeLimit: TimeInterval = 0 // 游戏时间限制 (0表示不限时)
    
    // MARK: - Reward Settings
    @Published var comboBonusThreshold: Int = 10     // 连击奖励阈值 (每10连击)
    @Published var comboBonusMoney: Double = 0.1     // 连击奖励金额
    @Published var randomRewardChance: Double = 0.05 // 随机奖励概率 (5%)
    @Published var randomRewardMin: Double = 0.5     // 随机奖励最小金额
    @Published var randomRewardMax: Double = 1.0     // 随机奖励最大金额
    
    // MARK: - Treasure Settings
    @Published var randomTreasureChance: Double = 0.01 // 随机宝藏概率 (1%)
    @Published var randomTreasureMin: Double = 0.01
    @Published var randomTreasureMax: Double = 0.03
    
    // MARK: - Meteor Settings
    @Published var randomMeteorChance: Double = 0.01   // 随机流星概率 (1%)
    @Published var randomMeteorMin: Double = 0.01
    @Published var randomMeteorMax: Double = 0.02
    
    // MARK: - Milestone Settings
    @Published var milestoneLetterCount: Int = 50    // 阶段奖励字母数阈值
    @Published var milestoneBonusMoney: Double = 1.0 // 阶段奖励金额
    @Published var fireEffectThreshold: Int = 30     // 火焰特效触发连击数
    
    // MARK: - Delay Settings (Seconds)
    @Published var delayStandard: Double = 0.2    // 普通模式读完后的等待时间
    @Published var delayArticle: Double = 0.2     // 短文模式读完后的跳转等待时间
    @Published var delayXiehouyu: Double = 0.2    // 歇后语读完后的等待时间
    @Published var delayHard: Double = 0.2        // 成语模式读完后的等待时间
    
    // MARK: - TTS Settings
    @Published var delayBeforeSpeak: Double = 0.0         // 输入完成后多久开始朗读
    @Published var singleCharSpeedMultiplier: Double = 2.0 // 单字朗读速度倍率 (默认 2.0x)
    
    private init() {
        load()
    }
    
    func load() {
        if let val = UserDefaults.standard.value(forKey: "moneyPerLetter") as? Double { moneyPerLetter = val }
        if let val = UserDefaults.standard.value(forKey: "penaltyPerError") as? Double { penaltyPerError = val }
        
        if let val = UserDefaults.standard.value(forKey: "maxHealth") as? Int { maxHealth = val }
        if let val = UserDefaults.standard.value(forKey: "healthPerError") as? Int { 
            healthPerError = val
        }
        if let val = UserDefaults.standard.value(forKey: "costPerHealth") as? Double { costPerHealth = val }
        if let val = UserDefaults.standard.value(forKey: "gameTimeLimit") as? Double { gameTimeLimit = val }
        
        if let val = UserDefaults.standard.value(forKey: "comboBonusThreshold") as? Int { comboBonusThreshold = val }
        if let val = UserDefaults.standard.value(forKey: "comboBonusMoney") as? Double { comboBonusMoney = val }
        if let val = UserDefaults.standard.value(forKey: "randomRewardChance") as? Double { randomRewardChance = val }
        if let val = UserDefaults.standard.value(forKey: "randomRewardMin") as? Double { randomRewardMin = val }
        if let val = UserDefaults.standard.value(forKey: "randomRewardMax") as? Double { randomRewardMax = val }
        
        if let val = UserDefaults.standard.value(forKey: "randomTreasureChance") as? Double { randomTreasureChance = val }
        if let val = UserDefaults.standard.value(forKey: "randomTreasureMin") as? Double { randomTreasureMin = val }
        if let val = UserDefaults.standard.value(forKey: "randomTreasureMax") as? Double { randomTreasureMax = val }
        
        if let val = UserDefaults.standard.value(forKey: "randomMeteorChance") as? Double { randomMeteorChance = val }
        if let val = UserDefaults.standard.value(forKey: "randomMeteorMin") as? Double { randomMeteorMin = val }
        if let val = UserDefaults.standard.value(forKey: "randomMeteorMax") as? Double { randomMeteorMax = val }
        
        if let val = UserDefaults.standard.value(forKey: "milestoneLetterCount") as? Int { milestoneLetterCount = val }
        if let val = UserDefaults.standard.value(forKey: "milestoneBonusMoney") as? Double { milestoneBonusMoney = val }
        if let val = UserDefaults.standard.value(forKey: "fireEffectThreshold") as? Int { fireEffectThreshold = val }
        
        if let val = UserDefaults.standard.value(forKey: "delayStandard") as? Double { delayStandard = val }
        if let val = UserDefaults.standard.value(forKey: "delayArticle") as? Double { delayArticle = val }
        if let val = UserDefaults.standard.value(forKey: "delayXiehouyu") as? Double { delayXiehouyu = val }
        if let val = UserDefaults.standard.value(forKey: "delayHard") as? Double { delayHard = val }
        
        if let val = UserDefaults.standard.value(forKey: "delayBeforeSpeak") as? Double { delayBeforeSpeak = val }
        if let val = UserDefaults.standard.value(forKey: "singleCharSpeedMultiplier") as? Double { singleCharSpeedMultiplier = val }
    }
    
    func save() {
        UserDefaults.standard.set(moneyPerLetter, forKey: "moneyPerLetter")
        UserDefaults.standard.set(penaltyPerError, forKey: "penaltyPerError")
        
        UserDefaults.standard.set(maxHealth, forKey: "maxHealth")
        UserDefaults.standard.set(healthPerError, forKey: "healthPerError")
        UserDefaults.standard.set(costPerHealth, forKey: "costPerHealth")
        UserDefaults.standard.set(gameTimeLimit, forKey: "gameTimeLimit")
        
        UserDefaults.standard.set(comboBonusThreshold, forKey: "comboBonusThreshold")
        UserDefaults.standard.set(comboBonusMoney, forKey: "comboBonusMoney")
        UserDefaults.standard.set(randomRewardChance, forKey: "randomRewardChance")
        UserDefaults.standard.set(randomRewardMin, forKey: "randomRewardMin")
        UserDefaults.standard.set(randomRewardMax, forKey: "randomRewardMax")
        
        UserDefaults.standard.set(randomTreasureChance, forKey: "randomTreasureChance")
        UserDefaults.standard.set(randomTreasureMin, forKey: "randomTreasureMin")
        UserDefaults.standard.set(randomTreasureMax, forKey: "randomTreasureMax")
        
        UserDefaults.standard.set(randomMeteorChance, forKey: "randomMeteorChance")
        UserDefaults.standard.set(randomMeteorMin, forKey: "randomMeteorMin")
        UserDefaults.standard.set(randomMeteorMax, forKey: "randomMeteorMax")
        
        UserDefaults.standard.set(milestoneLetterCount, forKey: "milestoneLetterCount")
        UserDefaults.standard.set(milestoneBonusMoney, forKey: "milestoneBonusMoney")
        UserDefaults.standard.set(fireEffectThreshold, forKey: "fireEffectThreshold")
        
        UserDefaults.standard.set(delayStandard, forKey: "delayStandard")
        UserDefaults.standard.set(delayArticle, forKey: "delayArticle")
        UserDefaults.standard.set(delayXiehouyu, forKey: "delayXiehouyu")
        UserDefaults.standard.set(delayHard, forKey: "delayHard")
        
        UserDefaults.standard.set(delayBeforeSpeak, forKey: "delayBeforeSpeak")
        UserDefaults.standard.set(singleCharSpeedMultiplier, forKey: "singleCharSpeedMultiplier")
    }
}

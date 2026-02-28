//
//  GameEngineProtocol.swift
//  xuedazi
//
//  Created by up on 2026/2/23.
//

import Foundation
import SwiftUI

/// 游戏引擎协议 - Strategy 的依赖抽象
protocol GameEngineProtocol: AnyObject {
    // 状态
    var gameState: GameState { get }
    var selectedDifficulty: Difficulty? { get }
    var currentHealth: Int { get set }
    var currentIndex: Int { get set }
    var currentInput: String { get set }
    
    // 奖励系统
    var scoreManager: ScoreManager { get }
    
    // 词库
    var words: [WordItem] { get set }
    var currentWord: WordItem { get }
    
    // 输入验证
    var inputValidator: InputValidator { get }
    
    // 特定模式状态 (为了兼容现有逻辑，可能需要暴露更多或重构)
    // Practice Mode Specifics
    var letterGameInput: String { get set }
    var letterGameTarget: String { get set }
    var letterGameRepeatsLeft: Int { get set }
    var letterGameRepeatsTotal: Int { get set }
    var letterGameDropToken: Int { get set }
    var letterGameHitFlash: Bool { get set }
    
    // Input Feedback
    var lastPressedKey: String? { get set }
    var lastWrongKey: String? { get set }
    var shakeTrigger: Int { get set }
    var pressTrigger: Int { get set }
    var isWrong: Bool { get set }
    var showSuccess: Bool { get set }
    var hintKey: String? { get set }
    var teachingMode: TeachingMode { get set }
    
    // 游戏控制
    func startNewGame()
    func stopGame()
    func reduceHealth(amount: Int)
    
    // 状态更新
    func updateHintKey(targetChars: [Character])
    func resetInputState()
    func scheduleKeyClear()
    func scheduleWrongKeyClear(completion: (() -> Void)?)
}

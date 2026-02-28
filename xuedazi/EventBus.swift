//
//  EventBus.swift
//  xuedazi
//
//  Created by up on 2026/2/22.
//

import Foundation
import Combine

/// 游戏事件定义
enum GameEvent {
    /// 重置游戏进度
    case resetGameProgress
    
    /// 切换设置面板显示/隐藏
    case toggleSettings
    
    /// 选择难度并开始游戏
    case difficultySelected(Difficulty)
    
    // 后续可扩展更多事件，如：
    // case gameStarted(Difficulty)
    // case levelCompleted
    // case achievementUnlocked(String)
}

/// 类型安全的事件总线
class EventBus {
    static let shared = EventBus()
    
    private let _events = PassthroughSubject<GameEvent, Never>()
    
    /// 事件发布者
    var events: AnyPublisher<GameEvent, Never> {
        _events.eraseToAnyPublisher()
    }
    
    /// 发送事件
    func post(_ event: GameEvent) {
        _events.send(event)
    }
}

//
//  TimerManager.swift
//  xuedazi
//
//  Created by up on 2026/2/23.
//

import Foundation

/// 统一计时器管理器 - 解决 Timer 分散管理和内存泄漏问题
class TimerManager {
    static let shared = TimerManager()
    
    private var timers: [String: Timer] = [:]
    private var isPaused = false
    private let lock = NSLock()
    
    private init() {}
    
    // MARK: - 调度
    
    /// 调度一个计时器
    /// - Parameters:
    ///   - id: 唯一标识符
    ///   - interval: 时间间隔
    ///   - repeats: 是否重复
    ///   - action: 执行闭包
    func schedule(
        id: String,
        interval: TimeInterval,
        repeats: Bool = false,
        action: @escaping () -> Void
    ) {
        cancel(id: id) // 先取消同名旧计时器
        
        lock.lock()
        defer { lock.unlock() }
        
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats) { _ in
            action()
        }
        
        // 确保 Timer 在 Common 模式下运行，避免滑动 ScrollView 时停止
        RunLoop.current.add(timer, forMode: .common)
        
        timers[id] = timer
    }
    
    /// 取消特定计时器
    func cancel(id: String) {
        lock.lock()
        defer { lock.unlock() }
        
        if let timer = timers[id] {
            timer.invalidate()
            timers.removeValue(forKey: id)
        }
    }
    
    /// 取消所有计时器
    func cancelAll() {
        lock.lock()
        defer { lock.unlock() }
        
        for timer in timers.values {
            timer.invalidate()
        }
        timers.removeAll()
    }
    
    /// 检查计时器是否存在
    func exists(id: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return timers[id] != nil
    }
    
    // MARK: - 暂停/恢复 (高级功能)
    // 注意：系统 Timer 不支持暂停，这里需要自行实现时间差逻辑或重新调度
    // 简单起见，目前只提供 invalidate 能力
    // 如果需要真正的 pause/resume，通常需要记录开始时间和剩余时间，重新 schedule
}

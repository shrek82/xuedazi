import Foundation
import AVFoundation
import SwiftUI

class SoundManager: NSObject {
    static let shared = SoundManager()
    
    // TTS Services
    private lazy var systemTTSService = SystemTTSService()
    private var xunFeiTTSService = XunFeiTTSManager.shared
    
    // Audio Pools
    private var correctPlayers: [AVAudioPlayer] = []
    private var currentCorrectIndex = 0
    
    private var wrongPlayers: [AVAudioPlayer] = []
    private var currentWrongIndex = 0
    
    private var successPlayer: AVAudioPlayer?
    // 替换单个播放器为对象池，支持快速连续播放
    private var coinPlayers: [AVAudioPlayer] = []
    private var currentCoinIndex = 0
    
    private var getBigMoneyPlayer: AVAudioPlayer?
    private var hitPlayer: AVAudioPlayer?
    private var treasurePlayer: AVAudioPlayer?
    
    // 输入速度追踪
    private var lastInputTime: Date?
    private var currentInputSpeedMultiplier: Float = 1.0
    
    // TTS Queue
    private struct TTSJob {
        let text: String
        let rateMultiplier: Float
        let completion: (() -> Void)?
    }
    private var ttsQueue: [TTSJob] = []
    private var isProcessingTTS = false
    
    private override init() {
        super.init()
        setupPlayers()
    }
    
    private func setupPlayers() {
        // 基本音效
        // 正确音效池
        if let url = Bundle.main.url(forResource: "sound", withExtension: "mp3") {
            for _ in 0..<5 {
                if let player = try? AVAudioPlayer(contentsOf: url) {
                    player.prepareToPlay()
                    correctPlayers.append(player)
                }
            }
        }
        
        // 错误音效池
        if let url = Bundle.main.url(forResource: "warning", withExtension: "wav") {
            for _ in 0..<5 {
                if let player = try? AVAudioPlayer(contentsOf: url) {
                    player.prepareToPlay()
                    wrongPlayers.append(player)
                }
            }
        }
        
        if let url = Bundle.main.url(forResource: "success", withExtension: "wav") {
            successPlayer = try? AVAudioPlayer(contentsOf: url)
            successPlayer?.prepareToPlay()
        }
        
        // 金币音效
        // 创建金币音效池 (5个实例)
        if let url = Bundle.main.url(forResource: "get_a_money", withExtension: "wav") {
            for _ in 0..<5 {
                if let player = try? AVAudioPlayer(contentsOf: url) {
                    player.prepareToPlay()
                    coinPlayers.append(player)
                }
            }
        }
        
        getBigMoneyPlayer = loadSound(name: "get_more_money", ext: "wav")
        
        // 爆炸音效
        hitPlayer = loadSound(name: "hit", ext: "mp3")
        
        // 宝藏音效
        treasurePlayer = loadSound(name: "jinbi_hualala", ext: "mp3")
    }
    
    private func loadSound(name: String, ext: String) -> AVAudioPlayer? {
    // 尝试从 Bundle 加载
    if let url = Bundle.main.url(forResource: name, withExtension: ext) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            print("无法从 Bundle 加载音效：\(name).\(ext)")
        }
    } else {
        print("未找到音效文件：\(name).\(ext)")
    }
    return nil
}
    
    private func createPlayer(for path: String) -> AVAudioPlayer? {
        // Deprecated: Use loadSound(name:ext:) instead
        return nil
    }
    
    func playCorrectLetter() {
        guard !correctPlayers.isEmpty else { return }
        let player = correctPlayers[currentCorrectIndex]
        if player.isPlaying {
            player.stop()
            player.currentTime = 0
        }
        player.play()
        currentCorrectIndex = (currentCorrectIndex + 1) % correctPlayers.count
    }
    
    func playWrongLetter() {
        guard !wrongPlayers.isEmpty else { return }
        let player = wrongPlayers[currentWrongIndex]
        if player.isPlaying {
            player.stop()
            player.currentTime = 0
        }
        player.play()
        currentWrongIndex = (currentWrongIndex + 1) % wrongPlayers.count
    }
    
    func playSuccess() {
        successPlayer?.stop()
        successPlayer?.currentTime = 0
        successPlayer?.volume = 0.4 // 降低音量，避免盖过语音朗读
        successPlayer?.play()
    }
    
    func playGetSmallMoney() {
        guard !coinPlayers.isEmpty else { return }
        
        let player = coinPlayers[currentCoinIndex]
        if player.isPlaying {
            player.stop()
            player.currentTime = 0
        }
        player.play()
        
        currentCoinIndex = (currentCoinIndex + 1) % coinPlayers.count
    }
    
    func playGetBigMoney() {
        getBigMoneyPlayer?.stop()
        getBigMoneyPlayer?.currentTime = 0
        getBigMoneyPlayer?.play()
    }
    
    func playHit() {
        hitPlayer?.stop()
        hitPlayer?.currentTime = 0
        hitPlayer?.play()
    }
    
    func playTreasureSound() {
        treasurePlayer?.stop()
        treasurePlayer?.currentTime = 2.0 // 从第2秒开始播放
        treasurePlayer?.play()
    }
    
    func playMeteorSound() {
        // 随机流星使用普通金币音效
        playGetSmallMoney()
    }
    
    func playKeyPress() {
        // Default has no sound
    }
    
    func recordInput() {
        let now = Date()
        if let last = lastInputTime {
            let interval = now.timeIntervalSince(last)
            // 如果间隔小于 0.25 秒，视为快速输入 (1.5x)
            // 如果间隔小于 0.45 秒，视为中速输入 (1.2x)
            // 否则为正常速度 (1.0x)
            if interval < 0.25 {
                currentInputSpeedMultiplier = 1.5
            } else if interval < 0.45 {
                currentInputSpeedMultiplier = 1.2
            } else {
                currentInputSpeedMultiplier = 1.0
            }
        }
        lastInputTime = now
    }
    
    func getSuggestedRateMultiplier() -> Float {
        return currentInputSpeedMultiplier
    }
    
    // MARK: - TTS 朗读
    func speak(text: String, rateMultiplier: Float = 1.0, completion: (() -> Void)? = nil) {
        // Ensure Main Thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.speak(text: text, rateMultiplier: rateMultiplier, completion: completion)
            }
            return
        }
        
        let ttsEnabled = UserDefaults.standard.value(forKey: "ttsEnabled") as? Bool ?? true
        
        print("🔊 [SOUND-MANAGER] 收到 TTS 请求：\"\(text)\" (倍率: \(rateMultiplier))")
        
        guard ttsEnabled else {
            print("⚠️ [SOUND-MANAGER] TTS 未启用，跳过")
            completion?()
            return
        }
        
        // Optimize Queue: 如果是单字朗读请求，检查队列是否积压
        // 修改：即使积压也不要清除，以确保每个字都能被朗读（符合“不稳定”反馈修复）
        // if text.count == 1 { ... }
        
        // 1. Add to queue
        let job = TTSJob(text: text, rateMultiplier: rateMultiplier, completion: completion)
        ttsQueue.append(job)
        
        // 2. Try to process
        processNextTTSJob()
    }
    
    /// 清除待播放的单字任务（用于输入完成后直接朗读整句）
    /// 注意：由于用户反馈“不稳定”，此方法在多字模式下已不再调用，保留方法定义以防未来需要
    func clearPendingSingleCharTTS() {
        // 移除队列中所有单字任务
        let originalCount = ttsQueue.count
        ttsQueue.removeAll { $0.text.count == 1 }
        let removedCount = originalCount - ttsQueue.count
        if removedCount > 0 {
            print("⏩ [SOUND-MANAGER] 已跳过 \(removedCount) 个待播放的单字任务")
        }
    }
    
    private func processNextTTSJob() {
        // If already speaking, wait for completion delegate/callback
        guard !isProcessingTTS else { return }
        
        // Get next job
        guard !ttsQueue.isEmpty else { return }
        let job = ttsQueue.removeFirst()
        
        isProcessingTTS = true
        
        let useSystemTTS = UserDefaults.standard.value(forKey: "useSystemTTS") as? Bool ?? true
        print("▶️ [SOUND-MANAGER] 处理队列任务：\"\(job.text)\" (队列剩余: \(ttsQueue.count))")
        
        // Wrap completion to handle queue chain
        let wrappedCompletion: () -> Void = { [weak self] in
            print("✅ [SOUND-MANAGER] 任务完成：\"\(job.text)\"")
            job.completion?()
            
            // 直接处理下一个任务，不再使用 main.async 延迟，提高连贯性
            // 确保在主线程上重置状态和处理下一个任务
            if Thread.isMainThread {
                self?.isProcessingTTS = false
                self?.processNextTTSJob()
            } else {
                DispatchQueue.main.async {
                    self?.isProcessingTTS = false
                    self?.processNextTTSJob()
                }
            }
        }
        
        if useSystemTTS {
            print("🤖 [SOUND-MANAGER] 使用系统 TTS")
            systemTTSService.speak(text: job.text, rateMultiplier: job.rateMultiplier) { _ in
                wrappedCompletion()
            }
        } else {
            print("🌐 [SOUND-MANAGER] 使用讯飞 TTS")
            xunFeiTTSService.speak(text: job.text, rateMultiplier: job.rateMultiplier) { [weak self] success in
                if success {
                    wrappedCompletion()
                } else {
                    print("⚠️ [SOUND-MANAGER] 讯飞 TTS 失败，降级到系统 TTS")
                    self?.systemTTSService.speak(text: job.text, rateMultiplier: job.rateMultiplier) { _ in
                        wrappedCompletion()
                    }
                }
            }
        }
    }
    
    // MARK: - 停止朗读
    func stopSpeaking() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.stopSpeaking()
            }
            return
        }
        
        print("🛑 [SOUND-MANAGER] 停止所有朗读并清空队列")
        ttsQueue.removeAll()
        isProcessingTTS = false
        
        systemTTSService.stop()
        xunFeiTTSService.stop()
    }
    
    // MARK: - 预加载
    func preloadTexts(_ texts: [String]) {
        let useSystemTTS = UserDefaults.standard.value(forKey: "useSystemTTS") as? Bool ?? true
        guard !useSystemTTS else { return }  // 系统 TTS 无需预加载
        
        // 检查是否允许自动调用在线 API
        let autoOnline = UserDefaults.standard.object(forKey: "autoOnlineTTS") as? Bool ?? true
        guard autoOnline else {
            print("⚠️ [SOUND-MANAGER] 自动在线语音已禁用，跳过预加载")
            return
        }
        
        xunFeiTTSService.preload(texts: texts)
    }
}

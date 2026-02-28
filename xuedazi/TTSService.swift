//
//  TTSService.swift
//  xuedazi
//
//  Created by up on 2026/2/22.
//

import Foundation
import AVFoundation

/// TTS 服务协议
protocol TTSService: AnyObject {
    /// 朗读文本
    /// - Parameters:
    ///   - text: 要朗读的文本
    ///   - rateMultiplier: 语速倍率 (1.0 为标准)
    ///   - completion: 完成回调（Bool 表示是否成功）
    func speak(text: String, rateMultiplier: Float, completion: @escaping (Bool) -> Void)
    
    /// 停止朗读
    func stop()
    
    /// 预加载文本（可选）
    func preload(texts: [String])
}

// 默认实现
extension TTSService {
    func preload(texts: [String]) {}
    
    // 兼容旧接口
    func speak(text: String, completion: @escaping (Bool) -> Void) {
        speak(text: text, rateMultiplier: 1.0, completion: completion)
    }
}

/// 系统 TTS 服务实现
class SystemTTSService: NSObject, TTSService, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var currentCompletion: ((Bool) -> Void)?
    private var currentUtterance: AVSpeechUtterance?
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(text: String, rateMultiplier: Float = 1.0, completion: @escaping (Bool) -> Void) {
        // 如果正在朗读，先停止（或根据需求排队，但这里假设由上层 SoundManager 管理队列）
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        currentCompletion = completion
        
        let utterance = AVSpeechUtterance(string: text)
        currentUtterance = utterance
        
        // 配置语音
        if let voice = AVSpeechSynthesisVoice.speechVoices()
            .first(where: { $0.language == "zh-CN" && $0.quality == .enhanced }) {
            utterance.voice = voice
        }
        
        // 调整参数，更适合儿童
        // 针对单字朗读，适当加快语速（1.5x，从 0.45 提至 0.60）
        // 结合 rateMultiplier 进行动态调整
        var baseRate: Float = 0.45
        
        if text.count == 1 {
            // 根据 singleCharSpeedMultiplier 调整 baseRate
            // 默认 2.0x 对应 0.60 (系统TTS的速率是非线性的，0.5是标准)
            // 简单映射: 0.3 + 0.15 * multiplier (1.0->0.45, 2.0->0.60, 3.0->0.75)
            let multiplier = Float(GameSettings.shared.singleCharSpeedMultiplier)
            baseRate = 0.3 + 0.15 * multiplier
            
            utterance.postUtteranceDelay = 0.0
            utterance.preUtteranceDelay = 0.0
        } else {
            baseRate = 0.45  // 较慢的语速
            utterance.postUtteranceDelay = 0.05 // 正常词语之间稍微保留一点间隔
        }
        
        // 应用倍率，并限制在合理范围 (AVSpeechUtterance.rate range is 0.0-1.0)
        // 0.5 is default/normal. 0.75 is very fast. 0.9 is often unintelligible.
        // 注意：baseRate 已经包含 singleCharSpeedMultiplier (如果是单字)，
        // 但 rateMultiplier 是输入速度倍率 (快打快读)，两者叠加。
        // 例如：单字倍速配置 2.0x (baseRate=0.60) * 输入极快 1.5x = 0.9 -> 限制到 0.8
        let finalRate = min(max(baseRate * rateMultiplier, 0.1), 0.8)
        utterance.rate = finalRate
        
        utterance.pitchMultiplier = 1.2  // 稍高的音调
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        currentCompletion = nil
        currentUtterance = nil
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if utterance == currentUtterance {
            let completion = currentCompletion
            currentCompletion = nil
            currentUtterance = nil
            completion?(true)
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        if utterance == currentUtterance {
            let completion = currentCompletion
            currentCompletion = nil
            currentUtterance = nil
            completion?(false)
        }
    }
}

/// 讯飞 TTS 服务实现
class XunFeiTTSService: TTSService {
    
    func speak(text: String, rateMultiplier: Float = 1.0, completion: @escaping (Bool) -> Void) {
        XunFeiTTSManager.shared.speak(text: text, rateMultiplier: rateMultiplier, completion: completion)
    }
    
    func stop() {
        XunFeiTTSManager.shared.stop()
    }
    
    func preload(texts: [String]) {
        XunFeiTTSManager.shared.preloadTexts(texts)
    }
}

//
//  PlayerProgress.swift
//  xuedazi
//
//  Created by up on 2026/2/23.
//

import Foundation
import Combine

/// 玩家进度管理 (持久化数据)
class PlayerProgress: ObservableObject {
    static let shared = PlayerProgress()
    
    // MARK: - Global Stats
    @Published var totalScore: Int = 0 {
        didSet {
            if totalScore != oldValue { scheduleSave() }
        }
    }
    
    @Published var totalMoney: Double = 0.0 {
        didSet {
            if totalMoney != oldValue { scheduleSave() }
        }
    }
    
    @Published var totalCorrectLetters: Int = 0 {
        didSet {
            if totalCorrectLetters != oldValue { scheduleSave() }
        }
    }
    
    // MARK: - Combo Stats
    @Published var currentCombo: Int = 0 {
        didSet {
            if currentCombo != oldValue { scheduleSave() }
        }
    }
    
    @Published var maxCombo: Int = 0 {
        didSet {
            if maxCombo != oldValue { scheduleSave() }
        }
    }
    
    // MARK: - Persistence Internals
    private let progressKeyPrefix = "progress_"
    private let fileURL: URL
    private let lock = NSLock()
    private var saveDebounceTimer: Timer?
    
    // Legacy keys for migration
    private let legacyKeys = [
        "totalScore", "totalMoney", "totalCorrectLetters",
        "currentCombo", "maxCombo"
    ]
    
    private init() {
        // Setup file path
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documentsPath.appendingPathComponent("player_progress.json")
        
        load()
    }
    
    func load() {
        lock.lock()
        defer { lock.unlock() }
        
        // 1. Try to load from JSON file (New format)
        if let data = try? Data(contentsOf: fileURL) {
            let decoder = JSONDecoder()
            if let playerData = try? decoder.decode(PlayerData.self, from: data) {
                totalScore = playerData.totalScore
                totalMoney = playerData.totalMoney
                totalCorrectLetters = playerData.totalCorrectLetters
                currentCombo = playerData.currentCombo
                maxCombo = playerData.maxCombo
                
                // Load level progress
                for (key, value) in playerData.levelProgress {
                    UserDefaults.standard.set(value, forKey: key)
                }
                print("Loaded progress from JSON file")
                return
            }
        }
        
        // 2. Fallback to UserDefaults (Legacy format migration)
        print("Migrating progress from UserDefaults...")
        if let val = UserDefaults.standard.value(forKey: "totalScore") as? Int { totalScore = val }
        if let val = UserDefaults.standard.value(forKey: "totalMoney") as? Double { totalMoney = val }
        if let val = UserDefaults.standard.value(forKey: "totalCorrectLetters") as? Int { totalCorrectLetters = val }
        
        if let val = UserDefaults.standard.value(forKey: "currentCombo") as? Int { currentCombo = val }
        if let val = UserDefaults.standard.value(forKey: "maxCombo") as? Int { maxCombo = val }
        
        // Immediately save to new format (Internal call to avoid deadlock)
        saveToDiskInternal()
    }
    
    private func scheduleSave() {
        // Debounce save operation (2 seconds)
        saveDebounceTimer?.invalidate()
        saveDebounceTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.saveToDisk()
        }
    }
    
    func forceSave() {
        saveDebounceTimer?.invalidate()
        saveToDisk()
    }
    
    private func saveToDisk() {
        lock.lock()
        defer { lock.unlock() }
        saveToDiskInternal()
    }
    
    private func saveToDiskInternal() {
        // Gather level progress
        var levelProgress: [String: Int] = [:]
        for difficulty in Difficulty.allCases {
            let key = "\(progressKeyPrefix)\(difficulty.rawValue)"
            let progress = UserDefaults.standard.integer(forKey: key)
            if progress > 0 {
                levelProgress[key] = progress
            }
        }
        
        let data = PlayerData(
            totalScore: totalScore,
            totalMoney: totalMoney,
            currentCombo: currentCombo,
            maxCombo: maxCombo,
            totalCorrectLetters: totalCorrectLetters,
            levelProgress: levelProgress
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let encoded = try encoder.encode(data)
            try encoded.write(to: fileURL, options: .atomic)
            // print("Progress saved to disk")
        } catch {
            print("Failed to save progress: \(error)")
        }
    }
    
    // Deprecated public save method (kept for compatibility but redirects to scheduleSave)
    func save() {
        scheduleSave()
    }
    
    func resetGlobalProgress() {
        totalScore = 0
        totalMoney = 0.0
        totalCorrectLetters = 0
        currentCombo = 0
        maxCombo = 0
        
        // Reset level progress
        for difficulty in Difficulty.allCases {
            UserDefaults.standard.removeObject(forKey: "\(progressKeyPrefix)\(difficulty.rawValue)")
        }
        
        forceSave()
        EventBus.shared.post(.resetGameProgress)
    }
    
    // 进度管理方法 (Pass-through to UserDefaults for now, but included in JSON snapshot)
    func saveProgress(difficulty: Difficulty, index: Int) {
        UserDefaults.standard.set(index, forKey: "\(progressKeyPrefix)\(difficulty.rawValue)")
        scheduleSave()
    }
    
    func loadProgress(difficulty: Difficulty) -> Int {
        return UserDefaults.standard.integer(forKey: "\(progressKeyPrefix)\(difficulty.rawValue)")
    }
    
    // MARK: - Data Structure
    private struct PlayerData: Codable {
        var totalScore: Int
        var totalMoney: Double
        var currentCombo: Int
        var maxCombo: Int
        var totalCorrectLetters: Int
        var levelProgress: [String: Int]
    }
}

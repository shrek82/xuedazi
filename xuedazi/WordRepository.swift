//
//  WordRepository.swift
//  xuedazi
//
//  Created by up on 2026/2/22.
//

import Foundation

class WordRepository {
    static let shared = WordRepository()
    
    private(set) var allWords: [Difficulty: [WordItem]] = [:]
    
    init() {
        loadWords()
    }
    
    func loadWords() {
        guard let fileURL = Bundle.main.url(forResource: "words", withExtension: "json") else {
            print("Could not find words.json")
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let rawWords = try decoder.decode([String: [WordItem]].self, from: data)
            
            var newWords: [Difficulty: [WordItem]] = [:]
            
            if let easy = rawWords["easy"] { newWords[.easy] = easy }
            if let medium = rawWords["medium"] { newWords[.medium] = medium }
            if let hard = rawWords["hard"] { newWords[.hard] = hard }
            if let xiehouyu = rawWords["xiehouyu"] { newWords[.xiehouyu] = xiehouyu }
            if let article = rawWords["articles"] { newWords[.article] = article }
            if let englishPrimary = rawWords["englishPrimary"] { newWords[.englishPrimary] = englishPrimary }
            if let programmingVocab = rawWords["programmingVocab"] { newWords[.programmingVocab] = programmingVocab }
            if let initials = rawWords["initialsTeaching"] { newWords[.initialsTeaching] = initials }
            if let finals = rawWords["finalsTeaching"] { newWords[.finalsTeaching] = finals }
            if let dailyEnglish = rawWords["dailyEnglish"] { newWords[.dailyEnglish] = dailyEnglish }
            
            self.allWords = newWords
            print("Successfully loaded words from json via WordRepository")
            
        } catch {
            print("Error loading words.json: \(error)")
        }
    }
    
    func getWords(for difficulty: Difficulty) -> [WordItem] {
        // Lazy load special content
        if difficulty == .tangPoetry && allWords[.tangPoetry] == nil {
            loadTangPoetry()
        } else if difficulty == .tengwangGeXu && allWords[.tengwangGeXu] == nil {
            loadTengwangGeXu()
        }
        
        return allWords[difficulty] ?? []
    }

    private func loadTangPoetry() {
        // Try loading from bundle first
        if let fileURL = Bundle.main.url(forResource: "tang_poetry", withExtension: "json"),
           let data = try? Data(contentsOf: fileURL),
           let decoder = try? JSONDecoder(),
           let rawWords = try? decoder.decode([String: [WordItem]].self, from: data),
           let poetry = rawWords["tangPoetry"] {
            self.allWords[.tangPoetry] = poetry
            print("Successfully loaded tang_poetry.json from bundle")
            return
        }
        
        // Fallback to hardcoded data if file is missing (e.g. not added to Xcode project)
        print("Using fallback data for tang_poetry")
        if let data = tangPoetryJSON.data(using: .utf8),
           let rawWords = try? JSONDecoder().decode([String: [WordItem]].self, from: data),
           let poetry = rawWords["tangPoetry"] {
            self.allWords[.tangPoetry] = poetry
        }
    }
    
    private func loadTengwangGeXu() {
        // Try loading from bundle first
        if let fileURL = Bundle.main.url(forResource: "tengwang_ge_xu", withExtension: "json"),
           let data = try? Data(contentsOf: fileURL),
           let decoder = try? JSONDecoder(),
           let rawWords = try? decoder.decode([String: [WordItem]].self, from: data),
           let article = rawWords["tengwangGeXu"] {
            self.allWords[.tengwangGeXu] = article
            print("Successfully loaded tengwang_ge_xu.json from bundle")
            return
        }
        
        // Fallback to hardcoded data
        print("Using fallback data for tengwang_ge_xu")
        if let data = tengwangGeXuJSON.data(using: .utf8),
           let rawWords = try? JSONDecoder().decode([String: [WordItem]].self, from: data),
           let article = rawWords["tengwangGeXu"] {
            self.allWords[.tengwangGeXu] = article
        }
    }
    
    func hasLoaded() -> Bool {
        return !allWords.isEmpty
    }

    // MARK: - Fallback Data
    // Fallback data for when external JSON files are not in the bundle
    // Updated to be minimal error prompts to ensure external files are used
    private let tengwangGeXuJSON = #"""
    {
        "tengwangGeXu": [
            {
                "character": "配置错误",
                "pinyin": "peizhicuowu",
                "displayPinyin": "pèi zhì cuò wù",
                "definition": "请检查tengwang_ge_xu.json是否添加到Xcode项目"
            }
        ]
    }
    """#

    private let tangPoetryJSON = #"""
    {
      "tangPoetry": [
        {
          "character": "配置错误",
          "pinyin": "peizhicuowu",
          "displayPinyin": "pèi zhì cuò wù",
          "definition": "请检查tang_poetry.json是否添加到Xcode项目"
        }
      ]
    }
    """#


}

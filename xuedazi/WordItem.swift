//
//  WordItem.swift
//  xuedazi
//
//  Created by up on 2026/2/22.
//

import Foundation

struct WordItem: Identifiable, Codable, Equatable {
    var id = UUID()
    let character: String
    let pinyin: String      // 用于匹配输入的纯字母拼音
    let displayPinyin: String // 带声调的显示拼音
    var emoji: String = ""
    var definition: String = ""
    
    // Default values for fields not in JSON
    var kind: ContentKind = .word
    var articleText: String? = nil
    
    enum CodingKeys: String, CodingKey {
        case character, pinyin, displayPinyin, emoji, definition
    }
    
    init(character: String, pinyin: String, displayPinyin: String, emoji: String = "", definition: String = "") {
        self.character = character
        self.pinyin = pinyin
        self.displayPinyin = displayPinyin
        self.emoji = emoji
        self.definition = definition
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.character = try container.decode(String.self, forKey: .character)
        self.pinyin = try container.decode(String.self, forKey: .pinyin)
        self.displayPinyin = try container.decode(String.self, forKey: .displayPinyin)
        self.emoji = try container.decodeIfPresent(String.self, forKey: .emoji) ?? ""
        self.definition = try container.decodeIfPresent(String.self, forKey: .definition) ?? ""
    }
    
    // 获取拼音索引映射：返回每个输入位置对应的字符索引
    // 例如："你好" -> pinyin: "nihao" -> [0,0,1,1,1] (n,i对应第0个字，h,a,o对应第1个字)
    func buildPinyinIndexMap() -> [Int] {
        var map: [Int] = []
        let pinyinLines = displayPinyin.split(separator: "\n", omittingEmptySubsequences: false)
        
        // 遍历字符，跳过标点符号
        let chars = Array(character)
        var charIndex = 0
        var pinyinWordIndex = 0
        
        for pLine in pinyinLines {
            let pinyins = pLine.split(separator: " ", omittingEmptySubsequences: true)
            
            for pinyinSub in pinyins {
                let pinyinStr = String(pinyinSub)
                let inputPinyin = pinyinStr.toInputPinyin()
                
                // 跳过标点符号，找到对应的汉字
                while charIndex < chars.count && isPunctuation(String(chars[charIndex])) {
                    charIndex += 1
                }
                
                // 为这个拼音的每个字母添加映射到当前字符索引
                for _ in 0..<inputPinyin.count {
                    map.append(charIndex)
                }
                
                charIndex += 1
                pinyinWordIndex += 1
            }
        }
        
        return map
    }
    
    private func isPunctuation(_ char: String) -> Bool {
        // 使用 Unicode 转义避免引号冲突
        let punctuationChars: [String] = [
            "，", "。", "、", "？", "！", "：", "；",
            "\u{201C}", "\u{201D}", "\u{2018}", "\u{2019}", // ""''
            "（", "）", "【", "】", "《", "》", "…", "—",
            ",", ".", "?", "!", ":", ";",
            "\"", "'", "(", ")", "[", "]", "<", ">"
        ]
        return punctuationChars.contains(char)
    }
}

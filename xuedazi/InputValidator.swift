//
//  InputValidator.swift
//  xuedazi
//
//  Created by up on 2026/2/23.
//

import Foundation

/// 负责输入验证、清洗和指法提示
class InputValidator {
    
    // MARK: - Properties
    
    // 仅允许 ASCII 小写字母输入（含 v）
    let allowedLetters: Set<Character> = Set("abcdefghijklmnopqrstuvwxyz")
    
    // 指法映射表
    private let fingerMap: [String: String] = [
        "q": "左-小指", "a": "左-小指", "z": "左-小指",
        "p": "右-小指",
        "w": "左-无名指", "s": "左-无名指", "x": "左-无名指",
        "o": "右-无名指", "l": "右-无名指",
        "e": "左-中指", "d": "左-中指", "c": "左-中指",
        "i": "右-中指", "k": "右-中指",
        "r": "左-食指", "f": "左-食指", "v": "左-食指", "t": "左-食指", "g": "左-食指", "b": "左-食指",
        "y": "右-食指", "h": "右-食指", "n": "右-食指", "u": "右-食指", "j": "右-食指", "m": "右-食指"
    ]
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Input Processing
    
    /// 清洗输入（过滤非法字符）
    func cleanInput(_ input: String) -> String {
        return String(input.lowercased().filter { allowedLetters.contains($0) })
    }
    
    /// 检查是否包含控制字符（如方向键）
    func containsControlCharacters(_ input: String) -> Bool {
        return input.contains(where: { $0.asciiValue == 28 || $0.asciiValue == 29 })
    }
    
    /// 获取按键对应的手指提示
    func getFingerType(for key: String?) -> String? {
        guard let key = key else { return nil }
        return fingerMap[key.lowercased()]
    }
    
    // MARK: - Pinyin Logic
    
    /// 获取单词的目标输入拼音序列
    /// 例如："你好" -> "nihao"
    func getTargetPinyin(from word: WordItem) -> String {
        let pinyinLines = word.displayPinyin.split(separator: "\n", omittingEmptySubsequences: false)
        var result = ""
        
        for pLine in pinyinLines {
            let pinyins = pLine.split(separator: " ", omittingEmptySubsequences: true)
            for pinyinSub in pinyins {
                let pinyinStr = String(pinyinSub)
                result += pinyinStr.toInputPinyin()
            }
        }
        
        return result.lowercased()
    }
}

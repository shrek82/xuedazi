//
//  Difficulty.swift
//  xuedazi
//
//  Created by up on 2026/2/22.
//

import Foundation

enum Difficulty: String, CaseIterable, Codable {
    case homeRow = "基准键"
    case letterGame = "字母游戏"
    case initialsTeaching = "声母教学"
    case finalsTeaching = "韵母教学"
    case easy = "单字"
    case medium = "词语"
    case hard = "成语"
    case xiehouyu = "歇后语"
    case article = "短文"
    case tangPoetry = "小学唐诗"
    case tengwangGeXu = "滕王阁序"
    case englishPrimary = "小学英语词汇"
    case dailyEnglish = "日常英语"
    case programmingVocab = "编程通用词汇"
    
    var icon: String {
        switch self {
        case .easy: return "🐣"
        case .medium: return "🐯"
        case .hard: return "🐲"
        case .xiehouyu: return "🧩"
        case .article: return "📖"
        case .englishPrimary: return "🔤"
        case .programmingVocab: return "💻"
        case .initialsTeaching: return "🔡"
        case .finalsTeaching: return "🔠"
        case .letterGame: return "🎯"
        case .dailyEnglish: return "🗣️"
        case .tangPoetry: return "🏮"
        case .tengwangGeXu: return "🏯"
        case .homeRow: return "⌨️"
        }
    }
    
    var ageGroup: String {
        switch self {
        case .easy: return "小班"
        case .medium: return "中班"
        case .hard: return "大班"
        case .xiehouyu: return "小学"
        case .article: return "小学"
        case .englishPrimary: return "小学"
        case .programmingVocab: return "兴趣"
        case .initialsTeaching: return "教学"
        case .finalsTeaching: return "教学"
        case .letterGame: return "训练"
        case .dailyEnglish: return "通用"
        case .tangPoetry: return "经典"
        case .tengwangGeXu: return "千古"
        case .homeRow: return "基础"
        }
    }
    
    var description: String {
        switch self {
        case .easy: return "主要是简单的单个汉字"
        case .medium: return "日常生活中的常见词汇"
        case .hard: return "有趣的四字成语"
        case .xiehouyu: return "有趣的生活歇后语"
        case .article: return "优美的经典短文练习"
        case .englishPrimary: return "小学常用英语词汇"
        case .programmingVocab: return "编程常见英文词汇"
        case .initialsTeaching: return "按声母拆分与标注练习"
        case .finalsTeaching: return "按韵母拆分与标注练习"
        case .letterGame: return "字母微循环下落练习"
        case .dailyEnglish: return "生活常用英语口语250句"
        case .tangPoetry: return "精选小学必背古诗词"
        case .tengwangGeXu: return "落霞与孤鹜齐飞，秋水共长天一色"
        case .homeRow: return "基准键位(ASDF...)练习"
        }
    }
    
    var themeColor: (r: Double, g: Double, b: Double) {
        switch self {
        case .easy: return (0.3, 0.8, 0.4)    // 绿色
        case .medium: return (0.2, 0.6, 1.0)  // 蓝色
        case .hard: return (0.6, 0.4, 0.9)    // 紫色
        case .xiehouyu: return (0.2, 0.75, 0.6) // 青绿色
        case .article: return (0.0, 0.6, 0.5) // 青色
        case .englishPrimary: return (0.25, 0.7, 0.95)
        case .programmingVocab: return (0.3, 0.8, 0.75)
        case .initialsTeaching: return (1.0, 0.75, 0.0) // 琥珀黄
        case .finalsTeaching: return (0.0, 0.7, 1.0)    // 天蓝色
        case .letterGame: return (1.0, 0.55, 0.2) // 橙色
        case .dailyEnglish: return (0.4, 0.5, 0.9) // 靛蓝色
        case .tangPoetry: return (0.8, 0.3, 0.3) // 红色 (中国红)
        case .tengwangGeXu: return (0.6, 0.3, 0.2) // 赭石色
        case .homeRow: return (1.0, 0.4, 0.4)     // 红色
        }
    }


    var cardColors: (bg: String, shadow: String) {
        switch self {
        case .easy: return ("#1f2a22", "#0b1a12") // 单字模式：深绿系背景 / 阴影
        case .medium: return ("#1a2a3f", "#0b141f") // 词语模式：深蓝系背景 / 阴影
        case .hard: return ("#2d1f3f", "#150b1f") // 成语模式：深紫系背景 / 阴影
        case .xiehouyu: return ("#1a3f3a", "#0b1f1a") // 歇后语：青绿系背景 / 阴影
        case .article:
            return ("#0d2624", "#041412") // 短文：青色系背景 / 阴影
        case .englishPrimary:
            return ("#1e2a33", "#0e161c") // 英语：蓝灰系背景 / 阴影
        case .programmingVocab:
            return ("#1f2a29", "#0e1615") // 编程：深青系背景 / 阴影
        case .initialsTeaching:
            return ("#332612", "#1a1205") // 声母：深黄系背景 / 阴影
        case .finalsTeaching:
            return ("#122433", "#05121a") // 韵母：深蓝系背景 / 阴影
        case .letterGame:
            return ("#332014", "#1a100a") // 字母游戏：深橙系背景 / 阴影
        case .dailyEnglish:
            return ("#202433", "#10121a") // 日常英语：深靛蓝系背景 / 阴影
        case .tangPoetry:
            return ("#331414", "#1a0a0a") // 唐诗：深红系背景 / 阴影
        case .tengwangGeXu:
            return ("#331f14", "#1a0f0a") // 滕王阁序：深赭石系背景 / 阴影
        case .homeRow:
            return ("#331a1a", "#1a0d0d") // 基准键：深红系背景 / 阴影
        }
    }
}

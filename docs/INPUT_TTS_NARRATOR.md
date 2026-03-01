# 输入逻辑、朗诵机制与旁白系统

> **文档版本**: 1.0  
> **创建日期**: 2026-03-01  
> **项目**: 拼音大冒险 (xuedazi)

---

## 目录

1. [输入逻辑](#1-输入逻辑)
2. [朗诵机制 (TTS)](#2-朗诵机制-tts)
3. [旁白系统](#3-旁白系统)
4. [数据流图](#4-数据流图)

---

## 1. 输入逻辑

### 1.1 概述

输入逻辑负责接收用户键盘输入、验证拼音正确性、并提供实时的视觉反馈。系统采用多层架构，从视图到策略模式再到验证器，逐层处理用户输入。

### 1.2 核心文件

| 文件 | 职责 |
|------|------|
| `GameViewModel.swift` | 输入入口、状态转发、策略调度 |
| `InputValidator.swift` | 输入清洗、验证、指法映射 |
| `GameStrategy.swift` | 输入处理策略（标准模式/练习模式） |
| `AlignedInputView.swift` | 拼音-汉字对齐显示、字符级高亮 |
| `KeyboardView.swift` | 虚拟键盘渲染、指法引导高亮 |
| `KeyView.swift` | 单个按键视图 |

### 1.3 输入流程

```
┌─────────────────────────────────────────────────────────────────────┐
│                         用户输入流程                                 │
└─────────────────────────────────────────────────────────────────────┘

用户按键 → TextField.onChange → viewModel.checkInput()
                                              ↓
                                    viewModel.handleInput(input)
                                              ↓
                              strategy.handleInput(input) [GameStrategy]
                                              ↓
                              ┌────────────────────────────────────────┐
                              │         输入处理核心逻辑               │
                              ├────────────────────────────────────────┤
                              │ 1. 清洗输入 (InputValidator.cleanInput) │
                              │ 2. 逐字符校验                           │
                              │ 3. 正确/错误处理                        │
                              │ 4. 更新状态 (currentInput, isWrong)     │
                              │ 5. 触发音效/分数/连击                   │
                              │ 6. 字符/单词完成检测                    │
                              └────────────────────────────────────────┘
                                              ↓
                              AlignedInputView 渲染更新
                                    ↓
                              KeyboardView 高亮更新
```

### 1.4 输入验证 (InputValidator)

```swift
class InputValidator {
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
        "r": "左-食指", "f": "左-食指", "v": "左-食指", 
        "t": "左-食指", "g": "左-食指", "b": "左-食指",
        "y": "右-食指", "h": "右-食指", "n": "右-食指", 
        "u": "右-食指", "j": "右-食指", "m": "右-食指"
    ]
    
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
```

### 1.5 指法提示

系统为每个按键提供手指引导：

| 手指 | 左手按键 | 右手按键 |
|------|----------|----------|
| 小指 | q, a, z | p |
| 无名指 | w, s, x | o, l |
| 中指 | e, d, c | i, k |
| 食指 | r, f, v, t, g, b | y, h, n, u, j, m |

### 1.6 拼音索引映射

`AlignedInputView` 通过 `getInputRangeForDisplayChar()` 建立输入位置到汉字的映射：

```swift
// "你好" → pinyin: "nihao" → indexMap: [0,0,1,1,1]
//  n  i  h  a  o
//  └──┘  └─────┘
//   第 0 字   第 1 字

private func getInputRangeForDisplayChar(word: WordUnit, charIndex: Int) -> (start: Int, end: Int) {
    let chars = Array(word.displayPinyin)
    var current = 0
    
    for idx in 0..<chars.count {
        let mapped = String(chars[idx]).toInputPinyin()
        let length = mapped.count
        if idx == charIndex {
            return (current, current + length)
        }
        current += length
    }
    
    return (current, current)
}
```

### 1.7 字符级高亮

`AlignedInputView` 根据输入进度为拼音字符着色：

```swift
private func getPinyinCharColor(word: WordUnit, charIndex: Int) -> Color {
    let wordStart = word.startIndex
    let wordEnd = word.endIndex
    
    // 1. 已完成的词 → 绿色
    if typedCount >= wordEnd {
        return Color(red: 0.1, green: 0.9, blue: 0.5)
    }
    
    // 2. 还未开始打的词 → 黄色（等待）
    if typedCount < wordStart {
        return Color(red: 1.0, green: 0.75, blue: 0.2)
    }
    
    // 3. 正在打的词
    let charGlobalIndex = wordStart + getInputRangeForDisplayChar(word: word, charIndex: charIndex).start
    
    if typedCount > charGlobalIndex {
        // 已打过的字母 → 绿色
        return Color(red: 0.1, green: 0.9, blue: 0.5)
    } else if typedCount == charGlobalIndex {
        // 正是当前要打的 → 根据是否错误显示红/黄
        return isWrong ? Color(red: 1.0, green: 0.3, blue: 0.3) : Color(red: 1.0, green: 0.75, blue: 0.2)
    } else {
        // 还没打到的字母 → 黄色
        return Color(red: 1.0, green: 0.75, blue: 0.2)
    }
}
```

### 1.8 策略模式

输入处理使用策略模式，支持两种游戏模式：

```swift
protocol GameModeStrategy {
    func start()
    func stop()
    func handleInput(_ input: String)
    func nextItem()
    func jumpToItem(at index: Int)
}

// 标准模式 - 拼音输入
class StandardModeStrategy: GameModeStrategy {
    // 职责：拼音输入校验、字符完成检测、TTS 朗读调度
}

// 练习模式 - 字母游戏
class PracticeModeStrategy: GameModeStrategy {
    // 职责：下落字母击中检测、重复次数控制
}
```

---

## 2. 朗诵机制 (TTS)

### 2.1 概述

系统提供双 TTS 引擎支持：系统 TTS（离线可用）和讯飞 TTS（在线，自然音质）。所有 TTS 操作通过 `SoundManager` 统一管理。

### 2.2 核心文件

| 文件 | 职责 |
|------|------|
| `TTSService.swift` | TTS 协议定义与双引擎实现 |
| `SoundManager.swift` | 音频管理、TTS 队列、预加载 |
| `XunFeiTTSManager.swift` | 讯飞 WebSocket TTS 客户端 |
| `TTSCacheManager.swift` | TTS 音频缓存管理 |

### 2.3 TTS 架构

```swift
/// TTS 服务协议
protocol TTSService {
    func speak(text: String, rateMultiplier: Float, completion: @escaping (Bool) -> Void)
    func stop()
    func preload(texts: [String])
}

// 系统 TTS - 使用 AVSpeechSynthesizer
class SystemTTSService: TTSService, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(text: String, rateMultiplier: Float, completion: @escaping (Bool) -> Void) {
        // 使用中文语音，动态调整语速
        let utterance = AVSpeechUtterance(string: text)
        
        // 单字：使用 singleCharSpeedMultiplier 加速
        // 词语：标准语速
        var baseRate: Float = 0.45
        if text.count == 1 {
            let multiplier = Float(GameSettings.shared.singleCharSpeedMultiplier)
            baseRate = 0.3 + 0.15 * multiplier
        }
        
        // 叠加输入速度倍率，并限制范围
        let finalRate = min(max(baseRate * rateMultiplier, 0.1), 0.8)
        utterance.rate = finalRate
        utterance.pitchMultiplier = 1.2
        
        synthesizer.speak(utterance)
    }
}

// 讯飞 TTS - WebSocket 在线
class XunFeiTTSService: TTSService {
    func speak(text: String, rateMultiplier: Float, completion: @escaping (Bool) -> Void) {
        XunFeiTTSManager.shared.speak(text: text, rateMultiplier: rateMultiplier, completion: completion)
    }
}
```

### 2.4 TTS 队列管理

`SoundManager` 实现 FIFO 队列，支持排队、抢占、跳过：

```swift
class SoundManager: NSObject {
    private struct TTSJob {
        let text: String
        let rateMultiplier: Float
        let completion: (() -> Void)?
    }
    
    private var ttsQueue: [TTSJob] = []
    private var isProcessingTTS = false
    
    /// 朗读文本
    func speak(text: String, rateMultiplier: Float = 1.0, completion: (() -> Void)? = nil) {
        // 1. 加入队列
        let job = TTSJob(text: text, rateMultiplier: rateMultiplier, completion: completion)
        ttsQueue.append(job)
        
        // 2. 如果空闲，立即处理
        processNextTTSJob()
    }
    
    private func processNextTTSJob() {
        guard !isProcessingTTS, !ttsQueue.isEmpty else { return }
        
        isProcessingTTS = true
        let job = ttsQueue.removeFirst()
        
        // 3. 根据设置选择 TTS 引擎
        let useSystemTTS = UserDefaults.standard.value(forKey: "useSystemTTS") as? Bool ?? true
        
        if useSystemTTS {
            systemTTSService.speak(text: job.text, rateMultiplier: job.rateMultiplier) { _ in
                job.completion?()
                self.isProcessingTTS = false
                self.processNextTTSJob()
            }
        } else {
            xunFeiTTSService.speak(text: job.text, rateMultiplier: job.rateMultiplier) { success in
                if success {
                    job.completion?()
                } else {
                    // 降级到系统 TTS
                    self.systemTTSService.speak(text: job.text, rateMultiplier: job.rateMultiplier) { _ in
                        job.completion?()
                    }
                }
                self.isProcessingTTS = false
                self.processNextTTSJob()
            }
        }
    }
    
    /// 停止所有朗读并清空队列
    func stopSpeaking() {
        ttsQueue.removeAll()
        isProcessingTTS = false
        systemTTSService.stop()
        xunFeiTTSService.stop()
    }
}
```

### 2.5 动态语速调整

系统根据用户输入速度动态调整 TTS 语速：

```swift
class SoundManager {
    private var lastInputTime: Date?
    private var currentInputSpeedMultiplier: Float = 1.0
    
    /// 记录输入时间，用于计算输入速度
    func recordInput() {
        let now = Date()
        if let last = lastInputTime {
            let interval = now.timeIntervalSince(last)
            if interval < 0.25 {
                currentInputSpeedMultiplier = 1.5  // 极快输入
            } else if interval < 0.45 {
                currentInputSpeedMultiplier = 1.2  // 中速输入
            } else {
                currentInputSpeedMultiplier = 1.0  // 正常速度
            }
        }
        lastInputTime = now
    }
    
    /// 获取建议的 TTS 语速倍率
    func getSuggestedRateMultiplier() -> Float {
        return currentInputSpeedMultiplier
    }
}
```

### 2.6 TTS 预加载

讯飞 TTS 支持预加载文本，减少等待延迟：

```swift
func preloadTexts(_ texts: [String]) {
    let useSystemTTS = UserDefaults.standard.value(forKey: "useSystemTTS") as? Bool ?? true
    guard !useSystemTTS else { return }  // 系统 TTS 无需预加载
    
    xunFeiTTSService.preload(texts: texts)
}
```

### 2.7 TTS 触发场景

| 场景 | 触发方式 | 描述 |
|------|----------|------|
| 题目朗读 | `speakWord()` | 当前单词完整朗读 |
| 单字朗读 | `speakCharacter()` | 每完成一个汉字时触发 |
| 旁白配音 | `NarratorManager.trigger()` | 事件驱动的角色配音 |

---

## 3. 旁白系统

### 3.1 概述

旁白系统为游戏提供人格化解说，通过不同角色（ persona）的语音和台词增强游戏趣味性。系统支持 10 种角色，每种角色有独特的音色和台词风格。

### 3.2 核心文件

| 文件 | 职责 |
|------|------|
| `NarratorManager.swift` | 旁白系统核心、事件处理、台词管理 |
| `XunFeiTTSManager.swift` | 提供多种语音选项 |

### 3.3 角色类型

```swift
enum NarratorType: String, CaseIterable, Codable {
    case spongeBob = "海绵宝宝"      // 活泼鼓励
    case tsundereCat = "傲娇猫"       // 口是心非
    case toxicRabbit = "毒舌兔"       // 吐槽打击
    case kindGrandpa = "老爷爷"       // 慈祥温和
    case robot = "机器人"            // 机械冷静
    case charmingSister = "妩媚姐姐"  // 温柔撩人
    case coolGod = "高冷男神"         // 简洁高傲
    case funnyAunt = "滑稽大妈"       // 接地气
    case klee = "少女可莉"           // 童真活泼
    case animeGirl = "动漫少女"       // 热血中二
}
```

### 3.4 角色音色

每种角色使用讯飞 TTS 的不同语音：

| 角色 | 音色 |
|------|------|
| 海绵宝宝 | 欢乐面包 |
| 傲娇猫 | 动漫少女 |
| 毒舌兔 | 活泼少年 |
| 老爷爷 | 灵博松 |
| 机器人 | 胖男孩 |
| 媚妹姐姐 | 媚媚女 |
| 高冷男神 | 高冷男神 |
| 滑稽大妈 | 滑稽大妈 |
| 少女可莉 | 嘟嘟包 |
| 动漫少女 | 动漫少女 |

### 3.5 事件类型

```swift
enum NarratorEvent {
    case gameStart       // 游戏开始
    case combo(Int)      // 连击事件（包含连击数）
    case milestone       // 阶段目标达成
    case error           // 输入错误
    case lowHealth       // 生命值过低
    case gameOver        // 游戏结束
    case victory         // 胜利通关
}
```

### 3.6 台词结构

每种角色的台词按事件类型组织：

```swift
struct NarratorPersona {
    let voice: XunFeiTTSManager.VoiceType
    let phrases: [String: [String]]  // key: 事件类型, value: 台词数组
}

// 台词 key 命名规范
// start          - 游戏开始
// combo_5        - 5 连击
// combo_10       - 10 连击
// ...            - 以此类推到 combo_100
// milestone      - 阶段目标达成
// error          - 输入错误
// lowHealth      - 生命值过低
// gameOver       - 游戏结束
// victory        - 胜利
// random_funny   - 随机趣味台词
// random_encourage - 随机鼓励台词
// random_tips    - 随机小贴士
```

### 3.7 角色台词示例

**海绵宝宝 (SpongeBob)** - 活泼鼓励风格：

```swift
let startPhrases = [
    "准备好了吗？拼音大冒险开始啦！",
    "嘿嘿，我是你的海绵宝宝解说员！",
    "让我们看看你的手指有多灵活！",
    "比基尼海滩的拼音挑战开始咯！"
]

let combo10Phrases = [
    "十连击！你简直是天才！",
    "太强了，我都看呆了！",
    "这就是传说中的无影手吗？"
]

let errorPhrases = [
    "哎呀，手滑了吗？",
    "不要慌，深呼吸！",
    "这个拼音有点调皮哦！"
]
```

**傲娇猫 (TsundereCat)** - 口是心非风格：

```swift
let combo10Phrases = [
    "切，这有什么了不起...",
    "手感不错嘛...",
    "稍微有点看头了。"
]

let errorPhrases = [
    "笨蛋！这都能错？",
    "你是猪吗？",
    "看着点啊，笨手笨脚的！"
]
```

### 3.8 旁白触发流程

```swift
class NarratorManager {
    private var lastSpeakTime: Date = Date.distantPast
    @Published var minInterval: TimeInterval = 4.0  // 冷却时间
    
    /// 触发旁白
    func trigger(_ event: NarratorEvent, completion: (() -> Void)? = nil) {
        guard isEnabled else {
            completion?()
            return
        }
        
        // 检查冷却时间（连击事件）
        let now = Date()
        if case .combo = event {
            if now.timeIntervalSince(lastSpeakTime) < minInterval {
                completion?()
                return
            }
        }
        
        // 获取当前角色的台词
        guard let persona = personas[currentType] else {
            completion?()
            return
        }
        
        // 查找对应事件的台词
        var key = ""
        switch event {
        case .gameStart: key = "start"
        case .combo(let count): key = "combo_\(count)"
        case .milestone: key = "milestone"
        case .error: key = "error"
        case .lowHealth: key = "lowHealth"
        case .gameOver: key = "gameOver"
        case .victory: key = "victory"
        }
        
        // 随机选择台词并播放
        if let phrases = persona.phrases[key], !phrases.isEmpty {
            let phrase = phrases.randomElement() ?? ""
            lastSpeakTime = now
            
            tts.speak(text: phrase) { _ in
                completion?()
            }
        }
    }
}
```

### 3.9 冷却机制

旁白系统实现了智能冷却机制：

1. **连击事件冷却**：连击事件触发后，需要等待 `minInterval`（默认 4 秒）才能触发下一次
2. **重要事件无冷却**：游戏开始、结束、胜利、里程碑等重要事件不受冷却限制
3. **低血量优先**：低血量警告具有最高优先级，可在任何时候触发

### 3.10 旁白触发点

| 游戏事件 | 触发条件 | 冷却 |
|----------|----------|------|
| 游戏开始 | 用户点击开始 | 无 |
| 连击 5 | comboCount >= 5 | 有 |
| 连击 10 | comboCount >= 10 | 有 |
| ... | ... | ... |
| 连击 100 | comboCount >= 100 | 有 |
| 阶段目标 | 当前题完成 | 无 |
| 输入错误 | 输入与目标不匹配 | 无 |
| 生命值低 | health <= 2 | 无 |
| 游戏结束 | 时间到或生命为 0 | 无 |
| 胜利通关 | 完成所有题目 | 无 |

---

## 4. 数据流图

### 4.1 输入 → TTS 完整数据流

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           输入处理与 TTS 完整数据流                            │
└─────────────────────────────────────────────────────────────────────────────┘

                               ┌──────────────────────┐
                               │      用户按键        │
                               └──────────┬───────────┘
                                          ↓
                               ┌──────────────────────┐
                               │   TextField 输入     │
                               │  (internalInput)     │
                               └──────────┬───────────┘
                                          ↓
                               ┌──────────────────────┐
                               │  GameViewModel       │
                               │  .checkInput()        │
                               └──────────┬───────────┘
                                          ↓
                               ┌──────────────────────┐
                               │  InputValidator      │
                               │  .cleanInput()       │
                               │  (过滤非法字符)       │
                               └──────────┬───────────┘
                                          ↓
                               ┌──────────────────────┐
                               │  GameModeStrategy    │
                               │  .handleInput()       │
                               └──────────┬───────────┘
                                          ↓
                              ┌──────────────────────┐
                              │    输入校验结果        │
                    ┌─────────┴─────────┴─────────┐
                    ↓                              ↓
            ┌──────────────┐              ┌──────────────┐
            │   输入正确    │              │   输入错误    │
            ├──────────────┤              ├──────────────┤
            │ currentInput │              │ isWrong=true │
            │  +分数        │              │ 扣血/扣钱    │
            │  +连击        │              │ 重置连击     │
            │  +金币        │              │ 播放错误音效  │
            └──────┬───────┘              └──────┬───────┘
                   │                              │
                   ↓                              ↓
            ┌──────────────────────┐      ┌──────────────────────┐
            │  字符完成检测          │      │  scheduleWrongKey    │
            │  (是否完成当前汉字)   │      │  Clear 延迟重置      │
            └──────────┬───────────┘      └──────────────────────┘
                       ↓
              ┌────────────────┐
              │ 字符完成        │
              │ speakCharacter │
              │ (TTS 单字)     │
              └───────┬────────┘
                      ↓
              ┌────────────────┐
              │ 单词完成检测    │
              │ (是否完成整词) │
              └───────┬────────┘
                      ↓
              ┌────────────────┐
              │ 单词完成        │
              │ speakWord()    │
              │ (TTS 整词)     │
              └───────┬────────┘
                      ↓
              ┌────────────────┐
              │  delay         │
              │ (延迟跳转)     │
              └───────┬────────┘
                      ↓
              ┌────────────────┐
              │  nextItem()    │
              │  (下一题)      │
              └────────────────┘
```

### 4.2 旁白触发数据流

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              旁白触发数据流                                  │
└─────────────────────────────────────────────────────────────────────────────┘

                                    游戏事件
                                      ↑
    ┌─────────────────────────────────┼─────────────────────────────────┐
    │                                 │                                 │
    │                                 │                                 │
    │     ScoreManager                │     GameEngine                  │
    │     (连击/奖励)                 │     (状态变更)                   │
    │                                 │                                 │
    │  incrementCombo()               │  reduceHealth()                 │
    │  └─> checkRewards()             │  └─> trigger(.lowHealth)        │
    │       └─> Narrator              │                                 │
    │                                 │  handleGameOver()               │
    │  addFloatingReward()           │  └─> trigger(.gameOver)         │
    └─────────────────────────────────┼─────────────────────────────────┘
                                      ↓
                            NarratorManager
                                 .trigger(event)
                                      │
                    ┌─────────────────┼─────────────────┐
                    ↓                 ↓                 ↓
            ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
            │ 冷却检查      │  │ 获取台词     │  │ TTS 播放    │
            │              │  │              │  │              │
            │ minInterval  │  │ randomEle-   │  │ XunFei TTS   │
            │ 检查         │  │ ment()      │  │ 播放        │
            └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
                   │                 │                 │
                   ↓                 ↓                 ↓
            ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
            │ 跳过/继续     │  │ 随机选择     │  │ 回调完成    │
            │              │  │ 台词         │  │              │
            │ return /     │  │ phrase       │  │ completion? │
            │ continue     │  │              │  │ ()          │
            └──────────────┘  └──────────────┘  └──────────────┘
```

---

## 附录

### A. 相关文件路径

```
xuedazi/
├── InputValidator.swift          # 输入验证器
├── GameViewModel.swift           # 视图模型（输入入口）
├── GameStrategy.swift            # 游戏策略
├── AlignedInputView.swift        # 拼音对齐视图
├── KeyboardView.swift            # 虚拟键盘
├── KeyView.swift                 # 按键视图
├── SoundManager.swift            # 音频管理（TTS 队列）
├── TTSService.swift              # TTS 协议
├── XunFeiTTSManager.swift        # 讯飞 TTS
├── NarratorManager.swift         # 旁白系统
└── TTSCacheManager.swift         # TTS 缓存
```

### B. UserDefaults 配置项

| Key | 类型 | 描述 | 默认值 |
|-----|------|------|--------|
| `ttsEnabled` | Bool | TTS 全局开关 | true |
| `useSystemTTS` | Bool | 使用系统 TTS vs 讯飞 TTS | true |
| `singleCharSpeedMultiplier` | Double | 单字 TTS 语速倍率 | 2.0 |
| `narratorEnabled` | Bool | 旁白全局开关 | true |
| `narratorType` | String | 当前旁白角色 | "海绵宝宝" |
| `narratorSpeed` | Int | 旁白语速 | 60 |
| `narratorVolume` | Int | 旁白音量 | 70 |
| `narratorInterval` | Double | 旁白冷却时间 | 4.0 |

---

*文档版本：1.0*  
*最后更新：2026 年 3 月 1 日*
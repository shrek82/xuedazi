# 旁白系统指南

## 1. 旁白事件类型

| 事件类型 | 触发时机 | 调用位置 | 说明 |
|----------|----------|----------|------|
| `.gameStart` | 游戏开始时 | `GameStrategy.swift` | 游戏开始，播放开场旁白 |
| `.combo(Int)` | 连击达到阈值时 | `ScoreManager.swift` | 连击数达到 5/10/15...100 时触发 |
| `.milestone` | 阶段目标达成时 | `ScoreManager.swift` | 完成一定字母数后触发 |
| `.error` | 输入错误时 | `GameStrategy.swift` | 玩家按错键时触发 |
| `.lowHealth` | 生命值低时 | `GameEngine.swift`, `GameStrategy.swift` | 生命值≤2 时触发警告 |
| `.gameOver` | 游戏结束时 | `GameEngine.swift` | 生命值为 0 游戏结束时 |
| `.victory` | 游戏胜利时 | 待实现 | 完成游戏目标时触发 |
| `.speedMilestone(Int)` | 速度达到阈值时 | `ScoreManager.swift` | 速度达到 30/60/80/100/120/150 字/分时触发 |

---

## 2. 旁白角色

| 角色 | 类型 | 声音 | 特点 |
|------|------|------|------|
| 海绵宝宝 | `.spongeBob` | `.huanlemianbao` | 主要旁白角色，有趣、活泼、逗比 |
| 傲娇猫 | `.tsundereCat` | `.dongmanshaonv` | 傲娇风格，口是心非 |
| 毒舌兔 | `.toxicRabbit` | `.huoposhaonian` | 毒舌吐槽风格 |
| 老爷爷 | `.kindGrandpa` | `.lingbosong` | 慈祥鼓励风格 |
| 机器人 | `.robot` | `.pangbainan` | 机械冷静风格 |
| 妩媚姐姐 | `.charmingSister` | `.wumeinv` | 妩媚温柔风格 |
| 高冷男神 | `.coolGod` | `.gaolengnanshen` | 高冷简洁风格 |
| 滑稽大妈 | `.funnyAunt` | `.huajidama` | 滑稽接地气风格 |
| 少女可莉 | `.klee` | `.dudulibao` | 活泼可爱风格 |
| 动漫少女 | `.animeGirl` | `.dongmanshaonv` | 动漫中二风格 |

---

## 3. 触发条件详解

### 3.1 游戏开始 (`.gameStart`)

**触发位置**: `GameStrategy.swift` - `StandardModeStrategy.setupGame()`

```swift
NarratorManager.shared.trigger(.gameStart) { [weak self] in
    // 游戏开始旁白完成后的回调
}
```

**触发条件**:
- 游戏初始化完成
- 当前单词加载完成
- 旁白系统启用时

---

### 3.2 连击旁白 (`.combo`)

**触发位置**: `ScoreManager.swift` - `checkRewards()`

```swift
if comboCount > 0 && comboCount % comboThreshold == 0 {
    NarratorManager.shared.trigger(.combo(comboCount))
}
```

**触发条件**:
- 连击数达到阈值（默认 5 的倍数）
- 有冷却时间限制（默认 4 秒）
- 支持的连击数：5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100

**连击台词数量**:
- 每个连击阈值约有 12-16 条随机台词

---

### 3.3 阶段里程碑 (`.milestone`)

**触发位置**: `ScoreManager.swift` - `checkMilestoneRewards()`

```swift
if completedCount > 0 && completedCount % milestone == 0 {
    NarratorManager.shared.trigger(.milestone)
}
```

**触发条件**:
- 正确输入字母数达到阶段目标（默认每 50 个字母）
- 与随机奖励（宝藏/流星/幸运掉落）独立触发

---

### 3.4 错误旁白 (`.error`)

**触发位置**: `GameStrategy.swift` - `handleWrongInput()`

```swift
SoundManager.shared.playWrongLetter()
NarratorManager.shared.trigger(.error)
```

**触发条件**:
- 玩家按错键时
- 每次错误都会触发
- 无冷却时间限制

---

### 3.5 低血量警告 (`.lowHealth`)

**触发位置**: `GameStrategy.swift` 和 `GameEngine.swift`

```swift
if GameSettings.shared.maxHealth > 0 && gameEngine.currentHealth <= 2 && gameEngine.currentHealth > 0 {
    NarratorManager.shared.trigger(.lowHealth)
}
```

**触发条件**:
- 启用生命值系统
- 当前生命值 ≤ 2
- 每次进入低血量状态都会触发

---

### 3.6 游戏结束 (`.gameOver`)

**触发位置**: `GameEngine.swift` - `reduceHealth()`

```swift
if currentHealth <= 0 {
    gameState = .gameOver
    NarratorManager.shared.trigger(.gameOver)
}
```

**触发条件**:
- 生命值降至 0
- 游戏状态变为 `.gameOver`

---

### 3.7 速度里程碑 (`.speedMilestone`)

**触发位置**: `ScoreManager.swift` - `checkSpeedMilestone()`

```swift
private func checkSpeedMilestone(_ speed: Double) {
    for milestone in speedMilestones {
        if speed >= Double(milestone) && !triggeredSpeedMilestones.contains(milestone) {
            NarratorManager.shared.trigger(.speedMilestone(milestone))
            triggeredSpeedMilestones.insert(milestone)
            break
        }
    }
}
```

**触发条件**:
- 输入速度达到阈值（30/60/80/100/120/150 字/分）
- 每个阈值每轮游戏只触发一次
- 新游戏开始时重置记录

**速度台词数量**:
- 海绵宝宝：每个阈值 5-8 条
- 傲娇猫：60/80/100/120/150 各 3 条
- 毒舌兔：60/80/100/120/150 各 3 条
- 老爷爷：60/80/100/120/150 各 3 条

---

## 4. 旁白冷却机制

### 4.1 连击旁白冷却

```swift
let now = Date()
if case .combo = event {
    if now.timeIntervalSince(lastSpeakTime) < minInterval {
        completion?()
        return
    }
}
```

**冷却时间**: 默认 4 秒（可通过 `minInterval` 属性调整）

### 4.2 其他事件

- 游戏开始、错误、低血量、游戏结束、速度里程碑等事件**无冷却时间限制**
- 这些事件会立即触发旁白

---

## 5. 旁白系统配置

### 5.1 启用/禁用

```swift
// 禁用旁白
NarratorManager.shared.isEnabled = false

// 启用旁白
NarratorManager.shared.isEnabled = true
```

### 5.2 切换角色

```swift
// 切换为海绵宝宝
NarratorManager.shared.currentType = .spongeBob

// 切换为傲娇猫
NarratorManager.shared.currentType = .tsundereCat
```

### 5.3 调整语速、音量、音调

```swift
NarratorManager.shared.speed = 60    // 语速 (0-100)
NarratorManager.shared.volume = 70   // 音量 (0-100)
NarratorManager.shared.pitch = 50    // 音调 (0-100)
```

### 5.4 调整冷却时间

```swift
NarratorManager.shared.minInterval = 4.0  // 连击旁白冷却时间（秒）
```

---

## 6. 添加新旁白

### 6.1 添加新事件类型

```swift
enum NarratorEvent {
    // ... 现有事件
    case newEvent  // 新事件
}
```

### 6.2 为角色添加台词

```swift
// 在 setupPersonas() 中为角色添加新台词
var spongeBobPhrases: [String: [String]] = [:]
spongeBobPhrases["new_event"] = [
    "新旁白台词 1",
    "新旁白台词 2",
    "新旁白台词 3",
]
```

### 6.3 触发新旁白

```swift
NarratorManager.shared.trigger(.newEvent)
```

---

## 7. 调试技巧

### 7.1 查看旁白日志

旁白触发时会在控制台输出日志：
```
🗣️ [Narrator] 海绵宝宝：哇哦，30 字/分！像蜗牛散步一样可爱！
🗣️ [Speed] 速度达到 30 字/分，当前速度：35.2
```

### 7.2 试听当前角色声音

```swift
// 播放当前角色的开场旁白预览
NarratorManager.shared.previewCurrentVoice()
```

### 7.3 停止当前旁白

```swift
NarratorManager.shared.stopSpeaking()
```

---

## 8. 旁白台词统计

| 角色 | 开场 | 连击 | 里程碑 | 错误 | 低血量 | 游戏结束 | 胜利 | 速度 | 总计 |
|------|------|------|--------|------|--------|----------|------|------|------|
| 海绵宝宝 | 15 | ~180 | 16 | 20 | 17 | 20 | 20 | 46 | ~334 |
| 傲娇猫 | 3 | 9 | 2 | 4 | 3 | 3 | 3 | 15 | ~42 |
| 毒舌兔 | 3 | 9 | 2 | 4 | 3 | 3 | 3 | 15 | ~42 |
| 老爷爷 | 3 | 9 | 2 | 4 | 3 | 3 | 3 | 15 | ~42 |
| 机器人 | 3 | 8 | 3 | 4 | 3 | 3 | 3 | 0 | ~27 |
| 妩媚姐姐 | 3 | 7 | 2 | 4 | 3 | 3 | 2 | 0 | ~24 |
| 高冷男神 | 3 | 7 | 2 | 4 | 3 | 3 | 3 | 0 | ~25 |
| 滑稽大妈 | 3 | 7 | 2 | 4 | 3 | 3 | 3 | 0 | ~25 |
| 少女可莉 | 3 | 7 | 2 | 4 | 3 | 3 | 3 | 0 | ~25 |
| 动漫少女 | 3 | 7 | 2 | 4 | 3 | 3 | 3 | 0 | ~25 |

---

## 9. 相关文件

| 文件 | 职责 |
|------|------|
| `NarratorManager.swift` | 旁白管理器，处理旁白触发逻辑 |
| `ScoreManager.swift` | 触发连击、里程碑、速度旁白 |
| `GameStrategy.swift` | 触发游戏开始、错误旁白 |
| `GameEngine.swift` | 触发低血量、游戏结束旁白 |
| `docs/NARRATOR_GUIDE.md` | 旁白系统指南（本文档） |

---

*文档版本：1.0*  
*创建日期：2026 年 3 月 1 日*  
*作者：xuedazi 团队*
# 讯飞 TTS 集成指南

## 📋 功能特性

✅ **智能缓存机制**
- 内存缓存：当前会话快速访问
- 磁盘缓存：持久化存储，避免重复调用
- 自动清理：保留最近 100 个文件，防止占用过大

✅ **预加载支持**
- 游戏开始前批量合成
- 减少游戏过程中的延迟

✅ **双引擎支持**
- 系统 TTS（免费，离线）
- 讯飞 TTS（付费，更自然）

---

## 🔑 第一步：注册讯飞账号

1. 访问 https://www.xfyun.cn/
2. 注册账号并完成实名认证
3. 登录控制台

---

## 🎯 第二步：创建应用获取凭证

1. 进入控制台 → 语音合成
2. 点击"创建应用"
3. 填写应用信息：
   - 应用名称：拼音大冒险
   - 平台：iOS
   - 应用场景：教育
4. 创建成功后获取三个关键参数：
   ```
   AppID: xxxxxxxxxxxxxx
   APIKey: xxxxxxxxxxxxxx
   APISecret: xxxxxxxxxxxxxx
   ```

---

## 💻 第三步：配置代码

打开 `XunFeiTTSManager.swift`，找到第 14-16 行：

```swift
// 配置信息（需要替换为您的真实凭证）
private let appId = "YOUR_APP_ID"      // 👈 替换为你的 AppID
private let apiKey = "YOUR_API_KEY"    // 👈 替换为你的 APIKey
private let apiSecret = "YOUR_API_SECRET" // 👈 替换为你的 APISecret
```

替换为真实的凭证。

---

## 🚀 第四步：使用方式

### 方式 1：直接使用（推荐）

```swift
// 朗读文本（自动缓存）
SoundManager.shared.speak(text: "你好，世界")

// 朗读完成后回调
SoundManager.shared.speak(text: "太棒了！") {
    print("朗读完成")
}
```

### 方式 2：预加载（游戏开始前）

```swift
// 在游戏开始前预加载所有需要朗读的文本
let texts = ["苹果", "香蕉", "橙子", "葡萄"]
SoundManager.shared.preloadTexts(texts)

// 然后开始游戏...
```

### 方式 3：检查缓存

```swift
// 检查是否已缓存
if XunFeiTTSManager.shared.isCached(text: "你好") {
    print("已缓存，直接播放")
}
```

---

## ⚙️ 第五步：设置界面

在设置面板中添加 TTS 设置入口：

```swift
// 在 ContentView 或 SettingsPanel 中添加
NavigationLink("语音设置", destination: TTSSettingsView())
```

用户可以在设置中：
- 切换 系统 TTS / 讯飞 TTS
- 选择不同音色（小燕、小美等）
- 查看缓存大小
- 清除缓存

---

## 🎙️ 音色推荐

### 儿童教育场景推荐：

| 音色代码 | 名称 | 特点 | 适用场景 |
|---------|------|------|---------|
| `vimary` | 小美 | 甜美童声 | ⭐ 最适合儿童学习 |
| `xiaoyan` | 小燕 | 标准女声 | 通用场景 |
| `vixia` | 小夏 | 活力女声 | 互动游戏 |
| `xiaoyu` | 小宇 | 标准男声 | 男性角色 |

修改默认音色：
```swift
XunFeiTTSManager.shared.currentVoice = "vimary" // 改为小美童声
```

---

## 💰 费用说明

### 免费额度：
- **500 次/天**
- 合成时长 ≤ 100 秒
- 基础音色

### 付费方案（超出后）：
- **基础版**：¥80/万 次
- **高级版**：¥160/万 次
- **旗舰版**：¥320/万 次（超自然音色）

### 成本估算：
假设每天 1000 个孩子使用，每个孩子朗读 10 次：
- 每日调用：1000 × 10 = 10,000 次
- 免费额度：500 次
- 需付费：9,500 次 ≈ ¥76/天（高级版）
- **每月约 ¥2,280**

💡 **优化建议**：
1. 使用缓存后，相同内容只调用一次
2. 预加载常用词汇，减少实时调用
3. 默认使用系统 TTS，讯飞作为高级选项

---

## 📊 缓存效果示例

### 未使用缓存：
```
用户输入 "你好" → 调用 API → 等待 300ms → 播放
用户再次输入 "你好" → 调用 API → 等待 300ms → 播放
用户再次输入 "你好" → 调用 API → 等待 300ms → 播放
❌ 3 次 API 调用，成本高
```

### 使用缓存后：
```
用户输入 "你好" → 调用 API → 等待 300ms → 播放 → 保存到缓存
用户再次输入 "你好" → 读取缓存 → 立即播放 ✅
用户再次输入 "你好" → 读取缓存 → 立即播放 ✅
✅ 仅 1 次 API 调用，成本降低 67%
```

---

## 🧹 缓存管理

### 自动管理：
- 系统自动保留最近 100 个音频文件
- 超出时自动删除最旧的文件

### 手动清理：
```swift
// 清除所有缓存
XunFeiTTSManager.shared.clearCache()

// 或在设置界面点击"清除缓存"按钮
```

### 查看缓存大小：
```swift
let size = XunFeiTTSManager.shared.getCacheSize()
print("缓存大小：\(size) MB")
```

---

## 🔧 高级功能

### 1. 批量预加载示例

```swift
// 在游戏开始前（如加载界面）
func preloadGameAudio() {
    let allTexts = viewModel.words.map { $0.character }
    SoundManager.shared.preloadTexts(allTexts)
}
```

### 2. 智能降级策略

```swift
// 如果讯飞 API 调用失败，自动降级到系统 TTS
func speakWithFallback(text: String) {
    if !XunFeiTTSManager.shared.isCached(text: text) {
        // 尝试讯飞
        XunFeiTTSManager.shared.speak(text: text) {
            // 成功
        }
    } else {
        // 使用缓存
        SoundManager.shared.speak(text: text)
    }
}
```

### 3. 离线模式检测

```swift
import Network

func isNetworkAvailable() -> Bool {
    let network = NWPathMonitor()
    network.start(queue: DispatchQueue.global())
    return network.currentPath.status == .satisfied
}

// 离线时使用系统 TTS
if !isNetworkAvailable() {
    useSystemTTS = true
}
```

---

## 📈 性能优化建议

### 1. 分级缓存策略
```swift
// 高频词汇（成语、常用字）- 永久缓存
// 中频词汇（短文、歇后语）- 保留 30 天
// 低频词汇 - 保留 7 天
```

### 2. 后台预加载
```swift
// 在用户玩游戏时，后台预加载下一关的音频
func preloadNextLevel() {
    DispatchQueue.global(qos: .background).async {
        let nextLevelTexts = getWordsForLevel(nextLevelIndex)
        SoundManager.shared.preloadTexts(nextLevelTexts)
    }
}
```

### 3. 压缩音频
```swift
// 使用较低的比特率（64kbps vs 128kbps）
// 减少文件大小，节省流量和存储
```

---

## 🐛 常见问题

### Q1: 缓存文件在哪里？
A: `~/Library/Caches/TTSAudio/` 目录下

### Q2: 缓存会占用多少空间？
A: 每个 MP3 约 10-50KB，100 个文件约 1-5MB

### Q3: 如何调试缓存命中率？
A: 查看控制台日志，会显示"缓存命中"或"缓存未命中"

### Q4: 讯飞 API 调用失败怎么办？
A: 会自动降级到系统 TTS，不影响使用

### Q5: 可以在模拟器测试吗？
A: 可以，但建议使用真机测试音频播放

---

## 📞 技术支持

- 讯飞文档：https://www.xfyun.cn/doc/tts/online_tts.html
- 讯飞客服：4006-168-168

---

## ✅ 检查清单

- [ ] 注册讯飞账号
- [ ] 创建应用获取凭证
- [ ] 在 `XunFeiTTSManager.swift` 中配置凭证
- [ ] 测试系统 TTS
- [ ] 测试讯飞 TTS
- [ ] 测试缓存功能
- [ ] 测试预加载功能
- [ ] 添加设置界面入口
- [ ] 真机测试
- [ ] 监控 API 调用量

---

**祝集成顺利！🎉**

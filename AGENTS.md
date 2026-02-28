# AGENTS.md - Coding Agent Guidelines for xuedazi

## Project Overview

拼音大冒险 (Pinyin Adventure) - SwiftUI macOS app for kids to learn pinyin typing. Multiple difficulty levels, virtual keyboard with finger guidance, sound effects, dual TTS engines (system + XunFei), reward system.

**Target**: macOS 12.0+ | **Framework**: SwiftUI + AppKit | **Language**: Swift 5.9+

---

## Build & Run Commands

```bash
# Build (Debug/Release)
xcodebuild -project xuedazi.xcodeproj -scheme xuedazi -configuration Debug build
xcodebuild -project xuedazi.xcodeproj -scheme xuedazi -configuration Release build

# Clean build
xcodebuild -project xuedazi.xcodeproj -scheme xuedazi clean

# Open in Xcode
open xuedazi.xcodeproj

# Run tests (none currently)
xcodebuild -project xuedazi.xcodeproj -scheme xuedazi test
```

**No automated tests exist yet.** Verify functionality by running the app manually in Xcode.

---

## Code Style Guidelines

### Imports Order
```swift
import Foundation
import Combine
import AVFoundation
import SwiftUI
import AppKit
```

### Naming Conventions
| Type | Convention | Example |
|------|------------|---------|
| Classes/Structs/Enums | PascalCase | `GameViewModel`, `WordItem`, `Difficulty` |
| Properties/Methods | camelCase | `currentInput`, `checkInput()`, `speakWord()` |
| Static Instances | `.shared` | `SoundManager.shared`, `GameSettings.shared` |
| Protocols | PascalCase | `GameModeStrategy`, `TTSService` |
| UserDefaults Keys | camelCase strings | `"narratorSpeed"`, `"totalScore"` |

### File Header
```swift
//
//  FileName.swift
//  xuedazi
//
//  Created by up on YYYY/M/D.
//
```

### Comments
- Chinese comments are acceptable and encouraged
- Use `//` for single-line, `///` for documentation
- Avoid over-commenting obvious code

---

## SwiftUI Patterns

### ViewModel Pattern
```swift
class GameViewModel: ObservableObject {
    @Published var propertyName: Type = defaultValue
    private var privateProperty: Type
    private let constantProperty: Type
}
```

### View Pattern
```swift
struct SomeView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var localState: Type = defaultValue
    @FocusState private var isFocused: Bool
    @Binding var externalState: Type
    
    var body: some View { /* View content */ }
}
```

### Theme Colors
```swift
// Primary: Color.themeBgSky50, Color.themeSkyBlue, Color.themeAmberYellow
// Success: Color.themeSuccessGreen
// Keyboard: Color.themeKeyboardBg
// Finger hints: Color.fingerPink, Color.fingerOrange, Color.fingerYellow, Color.fingerGreen
// Utility: Color(hex: "#1f2a22"), color.darker(by: 0.2)
```

### Typography
```swift
.font(FontLoader.shared.pinyinFont(size: 60, weight: .medium))
.font(FontLoader.shared.chineseFont(size: 80))
.font(.system(size: 18, weight: .bold, design: .rounded))
```

### Animation
```swift
withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { state = newValue }
.animation(.spring(response: 0.4, dampingFraction: 0.7), value: someValue)
.transition(.opacity.animation(.easeInOut(duration: 0.5)))
```

---

## Architecture

### Design Patterns
- **MVVM**: Views observe ViewModels via `@ObservedObject`
- **Strategy**: `GameModeStrategy` protocol with `StandardModeStrategy` / `PracticeModeStrategy`
- **Singleton**: `SoundManager.shared`, `GameSettings.shared`, `NarratorManager.shared`
- **Protocol Abstraction**: `TTSService` for dual TTS engines
- **Event Bus**: `EventBus.shared` for global events (Combine pub/sub)

### Key Files
| File | Responsibility |
|------|----------------|
| `GameEngine.swift` | Core game loop, state management, timer logic |
| `GameViewModel.swift` | Connects view to engine, forwards state |
| `GameView.swift` | Main game UI, health bar, keyboard overlay |
| `LetterGameView.swift` | Letter falling game mode |
| `GameStrategy.swift` | `GameModeStrategy` protocol + implementations |
| `GameSettings.swift` | App settings persistence (UserDefaults) |
| `PlayerProgress.swift` | Player score, combo, reward tracking |
| `SoundManager.swift` | Audio playback, TTS queue management |
| `TTSService.swift` | Protocol abstraction for TTS engines |
| `XunFeiTTSManager.swift` | XunFei WebSocket TTS with caching |
| `NarratorManager.swift` | Persona-based narrator (10 characters) |
| `ScoreManager.swift` | Score calculation, combo, floating UI |
| `InputValidator.swift` | Pinyin input validation logic |
| `TimerManager.swift` | Centralized timer management |
| `EventBus.swift` | Global event bus (Combine pub/sub) |
| `WordRepository.swift` | Word data loading from JSON files |

### Game Modes
1. **Normal Mode** (`GameView`): Type pinyin for words/characters
2. **Letter Game Mode** (`LetterGameView`): Falling letters practice

Check: `viewModel.selectedDifficulty == .letterGame || .homeRow`

---

## Common Tasks

### Sound & TTS
```swift
// Sound effects
SoundManager.shared.playCorrectLetter()
SoundManager.shared.playWrongLetter()
SoundManager.shared.playSuccess()
SoundManager.shared.playGetSmallMoney()
SoundManager.shared.playGetBigMoney()

// TTS with completion
SoundManager.shared.speak(text: "你好") { /* completion */ }

// Stop all TTS
SoundManager.shared.stopSpeaking()

// Preload TTS (XunFei only)
SoundManager.shared.preloadTexts(["下一个词"])
```

### Persistence
```swift
// Read
let value = UserDefaults.standard.bool(forKey: "narratorEnabled")
let score = UserDefaults.standard.integer(forKey: "totalScore")

// Write
UserDefaults.standard.set(value, forKey: "narratorEnabled")
GameSettings.shared.save()  // For config values
PlayerProgress.shared.save()  // For player progress
```

### Adding a New Difficulty
1. Add case to `Difficulty` enum (`Difficulty.swift`)
2. Implement `icon`, `ageGroup`, `description`, `themeColor`, `cardColors`
3. Add words to `words.json` under matching key
4. Update `WordRepository.loadWords()` to parse the new key

### Adding a New View Component
1. Create Swift file in `xuedazi/`
2. **Add file to Xcode project** (required for build)
3. Use theme colors from `Color+Theme.swift`
4. Follow existing SwiftUI patterns

---

## Error Handling

### Result Types
```swift
// Use Result for async operations
func speak(text: String, completion: @escaping (Result<Void, Error>) -> Void)

// Use optional for simple failures
func findWord(id: String) -> WordItem?
```

### Guard Statements
```swift
guard let self = self else { return }
guard !words.isEmpty else { return }
guard gameState == .playing else { return }
```

### Do-Catch
```swift
do {
    let data = try Data(contentsOf: fileURL)
    let decoded = try JSONDecoder().decode([String: [WordItem]].self, from: data)
} catch {
    print("Error loading data: \(error)")
}
```

---

## Memory Management

### Closures
Always use `[weak self]` to avoid retain cycles:
```swift
Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
    self?.resetState()
}
```

### Combine
```swift
private var cancellables = Set<AnyCancellable>()
publisher
    .sink { [weak self] _ in self?.handle() }
    .store(in: &cancellables)
```

---

## Known Architecture Issues

> ⚠️ When refactoring, consider these improvements (see `ARCHITECTURE.md`):

1. **GameViewModel still large** (~270 lines) → Could extract more logic to engine
2. **Singletons hinder testability** → Consider dependency injection
3. **TTS queue management** → Currently in `SoundManager`, could be more robust
4. **Hardcoded strings** → Centralize in `AppConstants` or localization
5. **No unit tests** → Add XCTest targets for engine, validator, score logic

---

## Additional Resources

- `ARCHITECTURE.md` - Full system architecture documentation
- `GAME_RULES.md` - Game mechanics and TTS narration logic
- `xuedazi/words.json` - Main word database
- `xuedazi/tang_poetry.json` - Tang poetry content
- `xuedazi/tengwang_ge_xu.json` - Tengwang Ge Xu content

---

## Testing

**No automated tests exist yet.** Verify functionality by running the app manually in Xcode.

Future test structure (when tests are added):
```bash
# Run all tests
xcodebuild -project xuedazi.xcodeproj -scheme xuedazi test

# Run specific test
xcodebuild -project xuedazi.xcodeproj -scheme xuedazi test \
  -only-testing:xuedaziTests/ClassName/testMethodName
```

Test files should be placed in a `xuedaziTests/` directory with matching target in Xcode.

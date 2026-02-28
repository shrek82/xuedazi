import SwiftUI

struct AlignedInputView: View, Equatable {
    let character: String
    let displayPinyin: String
    let typedCount: Int
    let isWrong: Bool
    let teachingMode: TeachingMode
    let pinyinFontSize: CGFloat
    let hanziFontSize: CGFloat
    let showHanzi: Bool
    
    static func == (lhs: AlignedInputView, rhs: AlignedInputView) -> Bool {
        return lhs.character == rhs.character &&
               lhs.displayPinyin == rhs.displayPinyin &&
               lhs.typedCount == rhs.typedCount &&
               lhs.isWrong == rhs.isWrong &&
               lhs.teachingMode == rhs.teachingMode &&
               lhs.pinyinFontSize == rhs.pinyinFontSize &&
               lhs.hanziFontSize == rhs.hanziFontSize &&
               lhs.showHanzi == rhs.showHanzi
    }
    
    // Parsed data structure
    struct WordUnit: Identifiable {
        let id = UUID()
        let char: String
        let displayPinyin: String
        let inputPinyin: String
        let startIndex: Int
        let endIndex: Int
        let isPunctuation: Bool
    }
    
    struct LineUnit: Identifiable {
        let id: UUID
        let words: [WordUnit]
        let isPlaceholder: Bool
        
        init(id: UUID = UUID(), words: [WordUnit], isPlaceholder: Bool = false) {
            self.id = id
            self.words = words
            self.isPlaceholder = isPlaceholder
        }
        
        // Add helper properties for easy range checking
        var startIndex: Int { words.first?.startIndex ?? 0 }
        var endIndex: Int { words.last?.endIndex ?? 0 }
    }
    
    @State private var lines: [LineUnit] = []
    @State private var cachedCharacter: String = ""
    @State private var cachedPinyin: String = ""
    @State private var startPlaceholderID = UUID()
    @State private var endPlaceholderID = UUID()
    
    var body: some View {
        ZStack {
            if let activeLine = getActiveLine() {
                VStack(spacing: 30) {
                    ForEach(getVisibleLines(around: activeLine)) { line in
                        renderLine(line)
                            .id(line.id) // Keep ID to track identity across moves
                            .scaleEffect(line.id == activeLine.id ? 1.05 : 0.7)
                            .opacity(line.isPlaceholder ? 0 : (line.id == activeLine.id ? 1.0 : 0.4))
                            .allowsHitTesting(line.id == activeLine.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: activeLine.id)
                    }
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: activeLine.id)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Removed top padding to allow true vertical centering
        .onAppear {
            parseContentIfNeeded()
        }
        .onChange(of: character) { _, _ in parseContentIfNeeded() }
        .onChange(of: displayPinyin) { _, _ in parseContentIfNeeded() }
    }
    
    private func getVisibleLines(around activeLine: LineUnit) -> [LineUnit] {
        var visible: [LineUnit] = []
        
        // Previous line or placeholder
        if let prev = getPreviousLine(before: activeLine) {
            visible.append(prev)
        } else {
            visible.append(createPlaceholder(id: startPlaceholderID))
        }
        
        // Current line
        visible.append(activeLine)
        
        // Next line or placeholder
        if let next = getNextLine(after: activeLine) {
            visible.append(next)
        } else {
            visible.append(createPlaceholder(id: endPlaceholderID))
        }
        
        return visible
    }
    
    private func createPlaceholder(id: UUID) -> LineUnit {
        let dummyWord = WordUnit(
            char: " ",
            displayPinyin: "",
            inputPinyin: "",
            startIndex: -1,
            endIndex: -1,
            isPunctuation: false
        )
        return LineUnit(id: id, words: [dummyWord], isPlaceholder: true)
    }
    
    private func renderLine(_ line: LineUnit) -> some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(line.words) { word in
                renderWord(word)
                    .id(word.id)
            }
        }
    }
    
    private func getActiveLine() -> LineUnit? {
        // Handle empty case
        if lines.isEmpty { return nil }

        // Find the line that contains the current typed character index
        for (index, line) in lines.enumerated() {
            let isLastLine = (index == lines.count - 1)
            
            // For the last line, we include the endIndex (completed state)
            if isLastLine {
                if typedCount >= line.startIndex && typedCount <= line.endIndex {
                    return line
                }
            } else {
                // For other lines, we switch to next line immediately when endIndex is reached
                // So we use strict inequality for endIndex: [start, end)
                if typedCount >= line.startIndex && typedCount < line.endIndex {
                    return line
                }
            }
        }
        
        // Fallback: if typedCount exceeds all (completed), show last line
        if let last = lines.last, typedCount > last.endIndex {
            return last
        }
        
        return lines.first
    }
    
    private func getPreviousLine(before line: LineUnit) -> LineUnit? {
        if let index = lines.firstIndex(where: { $0.id == line.id }), index > 0 {
            return lines[index - 1]
        }
        return nil
    }
    
    private func getNextLine(after line: LineUnit) -> LineUnit? {
        if let index = lines.firstIndex(where: { $0.id == line.id }), index + 1 < lines.count {
            return lines[index + 1]
        }
        return nil
    }
    
    // 优化：只在内容真正改变时才重新解析
    private func parseContentIfNeeded() {
        if character != cachedCharacter || displayPinyin != cachedPinyin {
            cachedCharacter = character
            cachedPinyin = displayPinyin
            parseContent()
        }
    }
    
    private func renderWord(_ word: WordUnit) -> some View {
        VStack(spacing: 4) {
            // Pinyin part
            if !word.isPunctuation && !word.displayPinyin.isEmpty {
                renderPinyinText(word: word)
            } else {
                Text(" ") // Placeholder to maintain height if needed
                    .font(FontLoader.shared.pinyinFont(size: pinyinFontSize, weight: .medium))
                    .opacity(0)
            }
            
            // Character part
            if showHanzi {
                Text(word.char)
                    .font(FontLoader.shared.chineseFont(size: hanziFontSize))
                    .foregroundColor(getCharacterColor(word))
            }
        }
        .padding(.horizontal, 2)
    }
    
    // Advanced Pinyin Rendering with Character-level Coloring
    private func renderPinyinText(word: WordUnit) -> some View {
        HStack(spacing: 0) {
            let pinyinChars = Array(word.displayPinyin)
            ForEach(0..<pinyinChars.count, id: \.self) { idx in
                let range = getInputRangeForDisplayChar(word: word, charIndex: idx)
                let lastTypedIndex = typedCount - 1
                let relIndex = lastTypedIndex - word.startIndex
                // 只要当前字符已经被打过（或正在打），就保持 Overlay 存在，
                // 这样 TypingSparkleEffect 的 onAppear 动画完成后，View 仍然存在（只是不可见），
                // 避免快速打字时 View 被移除导致动画中断。
                let hasBeenTyped = (relIndex >= range.start)
                
                PinyinCharView(
                    char: String(pinyinChars[idx]),
                    fontSize: pinyinFontSize,
                    color: getPinyinCharColor(word: word, charIndex: idx),
                    hasBeenTyped: hasBeenTyped
                )
            }
        }
    }

    private func getPinyinCharColor(word: WordUnit, charIndex: Int) -> Color {
        // 全局 typedCount：当前已经正确输入的字符总数
        // word.startIndex：当前这个词（汉字）的拼音起始位置
        // word.endIndex：当前这个词（汉字）的拼音结束位置
        // charIndex：当前正在渲染的这个拼音字母在当前词中的索引（0, 1, 2...）
        
        let wordStart = word.startIndex
        let wordEnd = word.endIndex
        
        // 1. 已经完成的词 -> 绿色
        if typedCount >= wordEnd {
            return Color(red: 0.1, green: 0.9, blue: 0.5)
        }
        
        // 2. 还没开始打的词 -> 黄色（等待）
        if typedCount < wordStart {
            return Color(red: 1.0, green: 0.75, blue: 0.2)
        }
        
        // 3. 正在打的词
        // 计算当前字母在全局中的绝对索引
        // 例如 "nihao"，n=0, i=1, h=2...
        // 假设 word 是 "ni"，startIndex=0。 charIndex=0 -> globalIndex=0
        let range = getInputRangeForDisplayChar(word: word, charIndex: charIndex)
        // range.start 是该字母在 word 内部的相对偏移量
        // 该字母的全局索引 = wordStart + range.start
        
        let charGlobalIndex = wordStart + range.start
        
        // 如果这个字母已经被打过了 -> 绿色
        if typedCount > charGlobalIndex {
             return Color(red: 0.1, green: 0.9, blue: 0.5)
        }
        
        // 如果这个字母正是当前要打的 -> 检查是否错误
        if typedCount == charGlobalIndex {
            return isWrong ? Color(red: 1.0, green: 0.3, blue: 0.3) : Color(red: 1.0, green: 0.75, blue: 0.2)
        }
        
        // 还没打到的字母 -> 黄色
        return Color(red: 1.0, green: 0.75, blue: 0.2)
    }

    private func getCharacterColor(_ word: WordUnit) -> Color {
        if word.isPunctuation {
            return Color.white.opacity(0.8)
        }
        
        if typedCount >= word.endIndex {
            return Color(red: 0.1, green: 0.9, blue: 0.5) // Completed word
        } else if typedCount >= word.startIndex {
            return Color(red: 1.0, green: 0.75, blue: 0.2) // Current word
        } else {
            return Color.white.opacity(0.8) // Untouched word
        }
    }
    
    private func parseContent() {
        var newLines: [LineUnit] = []
        var globalInputIndex = 0
        
        // Split by logical lines first (from displayPinyin)
        let pinyinLines = displayPinyin.split(separator: "\n", omittingEmptySubsequences: false)
        
        // Handle Teaching Mode (Empty Character)
        if character.isEmpty {
            for pLine in pinyinLines {
                var lineWords: [WordUnit] = []
                let pinyins = pLine.split(separator: " ", omittingEmptySubsequences: true)
                for pinyinSub in pinyins {
                    let pinyinStr = String(pinyinSub)
                    let inputPinyin = pinyinStr.toInputPinyin()
                    let length = inputPinyin.count
                    
                    let word = WordUnit(
                        char: "",
                        displayPinyin: pinyinStr,
                        inputPinyin: inputPinyin,
                        startIndex: globalInputIndex,
                        endIndex: globalInputIndex + length,
                        isPunctuation: false
                    )
                    lineWords.append(word)
                    globalInputIndex += length
                }
                newLines.append(LineUnit(words: lineWords))
            }
            self.lines = newLines
            return
        }
        
        var charIndex = character.startIndex
        
        for pLine in pinyinLines {
            var lineWords: [WordUnit] = []
            // Split pinyins in this line
            let pinyins = pLine.split(separator: " ", omittingEmptySubsequences: true)
            var pinyinIdx = 0
            
            // Iterate until we consume all pinyins for this line
            // OR we run out of characters
            // Note: We must also consume punctuation that might appear before/between/after words
            
            while charIndex < character.endIndex {
                let char = String(character[charIndex])
                
                // Skip invisible controls if any
                if char.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                     charIndex = character.index(after: charIndex)
                     continue
                }

                if isPunctuation(char) {
                    let word = WordUnit(
                        char: char,
                        displayPinyin: "",
                        inputPinyin: "",
                        startIndex: globalInputIndex,
                        endIndex: globalInputIndex,
                        isPunctuation: true
                    )
                    lineWords.append(word)
                    charIndex = character.index(after: charIndex)
                    continue
                }
                
                // It is a Hanzi (presumably)
                // Do we have a pinyin for it in this line?
                if pinyinIdx < pinyins.count {
                    let pinyinStr = String(pinyins[pinyinIdx])
                    let inputPinyin = pinyinStr.toInputPinyin()
                    let length = inputPinyin.count
                    
                    let word = WordUnit(
                        char: char,
                        displayPinyin: pinyinStr,
                        inputPinyin: inputPinyin,
                        startIndex: globalInputIndex,
                        endIndex: globalInputIndex + length,
                        isPunctuation: false
                    )
                    lineWords.append(word)
                    
                    globalInputIndex += length
                    charIndex = character.index(after: charIndex)
                    pinyinIdx += 1
                } else {
                    // No more pinyins in this line, but we hit a Hanzi.
                    // This means this Hanzi belongs to the NEXT line.
                    // Stop processing this line.
                    break
                }
            }
            newLines.append(LineUnit(words: lineWords))
        }
        
        self.lines = newLines
    }
    
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
    
    private func isPunctuation(_ char: String) -> Bool {
        let punctuation = Set("，。、？！：；“”‘’（）【】《》…—,.?!:;\"'()[]<>")
        return !punctuation.isDisjoint(with: char)
    }
}

// MARK: - Helper Views

struct PinyinCharView: View {
    let char: String
    let fontSize: CGFloat
    let color: Color
    let hasBeenTyped: Bool
    
    var body: some View {
        // The text itself determines the size
        Text(char)
            .font(FontLoader.shared.pinyinFont(size: fontSize, weight: .medium))
            .foregroundColor(color)
            // Use background to avoid affecting layout size
            .background(
                ZStack {
                    if hasBeenTyped {
                        TypingSparkleEffect(color: .themeAmberYellow)
                            .offset(y: -15) // Move sparkles up
                            .allowsHitTesting(false)
                    }
                }
            )
    }
}

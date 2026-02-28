//
//  SpeechSynthesisView.swift
//  xuedazi
//
//  Created by up on 2026/2/23.
//

import SwiftUI
import Combine

class SpeechSynthesisViewModel: ObservableObject {
    @Published var selectedDifficulty: Difficulty?
    @Published var isGenerating: Bool = false
    @Published var progress: Double = 0.0
    @Published var currentText: String = ""
    @Published var currentSubTask: String = ""
    @Published var logs: [String] = []
    @Published var skipCached: Bool = true
    
    private var task: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    func startGeneration() {
        guard let difficulty = selectedDifficulty else { return }
        guard !isGenerating else { return }
        
        isGenerating = true
        progress = 0.0
        logs = []
        appendLog("开始生成任务：\(difficulty.rawValue)")
        
        let words = WordRepository.shared.getWords(for: difficulty)
        let totalWords = words.count
        
        if totalWords == 0 {
            appendLog("⚠️ 该模式下没有找到词汇")
            isGenerating = false
            return
        }
        
        task = Task { [weak self] in
            guard let self = self else { return }
            
            for (index, word) in words.enumerated() {
                if Task.isCancelled { break }
                
                let progressValue = Double(index) / Double(totalWords)
                await MainActor.run {
                    self.progress = progressValue
                    self.currentText = word.character
                    self.appendLog("处理: \(word.character)")
                }
                
                let voice = XunFeiTTSManager.shared.currentVoice
                
                // 1. 单字处理
                for char in word.character {
                    if Task.isCancelled { break }
                    let charStr = String(char)
                    
                    if !self.isPunctuation(charStr) && 
                       charStr.rangeOfCharacter(from: .whitespacesAndNewlines) == nil {
                        
                        let isCached = TTSCacheManager.shared.isFileCached(text: charStr, voice: voice)
                        
                        if self.skipCached && isCached {
                            await MainActor.run {
                                self.currentSubTask = "单字: \(charStr) (跳过)"
                                self.appendLog("跳过单字: \(charStr) ✅[已缓存]")
                            }
                            continue
                        }
                        
                        let statusStr = isCached ? "✅[已缓存]" : "🆕[新生成]"
                        
                        await MainActor.run {
                            self.currentSubTask = "单字: \(charStr)"
                            self.appendLog("处理单字: \(charStr) \(statusStr)")
                        }
                        await self.speak(text: charStr)
                    }
                }
                
                if Task.isCancelled { break }
                
                // 2. 完整朗读
                // 如果是单字词，已经在上面读过了，避免重复
                if word.character.count > 1 {
                    let isCached = TTSCacheManager.shared.isFileCached(text: word.character, voice: voice)
                    
                    if self.skipCached && isCached {
                        await MainActor.run {
                            self.currentSubTask = "完整: \(word.character) (跳过)"
                            self.appendLog("跳过词组: \(word.character) ✅[已缓存]")
                        }
                    } else {
                        let statusStr = isCached ? "✅[已缓存]" : "🆕[新生成]"
                        
                        await MainActor.run {
                            self.currentSubTask = "完整: \(word.character)"
                            self.appendLog("处理词组: \(word.character) \(statusStr)")
                        }
                        await self.speak(text: word.character)
                    }
                } else {
                    await MainActor.run {
                        self.currentSubTask = "完整: (单字跳过)"
                    }
                }
                
                // 稍微停顿一下
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            }
            
            await MainActor.run {
                self.isGenerating = false
                self.progress = 1.0
                self.currentText = "完成"
                self.currentSubTask = ""
                self.appendLog("✅ 所有任务完成")
            }
        }
    }
    
    func stopGeneration() {
        task?.cancel()
        task = nil
        SoundManager.shared.stopSpeaking()
        isGenerating = false
        appendLog("🛑 任务已停止")
    }
    
    private func isPunctuation(_ char: String) -> Bool {
        let punctuationChars: [String] = [
            "，", "。", "、", "？", "！", "：", "；",
            "\u{201C}", "\u{201D}", "\u{2018}", "\u{2019}",
            "（", "）", "【", "】", "《", "》", "…", "—",
            ",", ".", "?", "!", ":", ";",
            "\"", "'", "(", ")", "[", "]", "<", ">"
        ]
        return punctuationChars.contains(char) || char.rangeOfCharacter(from: .punctuationCharacters) != nil
    }

    private func speak(text: String) async {
        return await withCheckedContinuation { continuation in
            SoundManager.shared.speak(text: text) {
                continuation.resume()
            }
        }
    }
    
    private func appendLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logs.insert("[\(timestamp)] \(message)", at: 0)
        if logs.count > 100 {
            logs = Array(logs.prefix(100))
        }
    }
}

struct SpeechSynthesisView: View {
    @StateObject private var viewModel = SpeechSynthesisViewModel()
    @Environment(\.dismiss) var dismiss // If presented as sheet
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.themeSkyBlue)
                
                Text("语音合成管理")
                    .font(.system(size: 24, weight: .bold))
                
                Spacer()
            }
            .padding()
            .background(Color.black.opacity(0.2))
            
            // Content
            VStack(spacing: 24) {
                // 1. Mode Selection
                HStack {
                    Text("选择教学模式:")
                        .font(.headline)
                    
                    Picker("模式", selection: $viewModel.selectedDifficulty) {
                        Text("请选择").tag(nil as Difficulty?)
                        ForEach(Difficulty.allCases.filter { $0 != .letterGame && $0 != .homeRow }, id: \.self) { diff in
                                Text(diff.rawValue).tag(diff as Difficulty?)
                            }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 200)
                    .disabled(viewModel.isGenerating)
                    
                    Toggle("跳过已缓存", isOn: $viewModel.skipCached)
                        .toggleStyle(.checkbox)
                        .disabled(viewModel.isGenerating)
                    
                    Spacer()
                }
                
                // 2. Progress Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("当前进度:")
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.1f%%", viewModel.progress * 100))
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    ProgressView(value: viewModel.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(height: 8)
                    
                    if !viewModel.currentText.isEmpty {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading) {
                                Text("正在处理:")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(viewModel.currentText)
                                    .font(.title2)
                                    .bold()
                            }
                            
                            Spacer()
                            
                            if !viewModel.currentSubTask.isEmpty {
                                VStack(alignment: .trailing) {
                                    Text("当前操作:")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(viewModel.currentSubTask)
                                        .font(.title3)
                                        .foregroundColor(.themeSkyBlue)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.1))
                .cornerRadius(8)
                
                // 3. Logs
                VStack(alignment: .leading) {
                    Text("执行日志")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(viewModel.logs, id: \.self) { log in
                                Text(log)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(height: 150)
                    .padding(8)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(4)
                }
                
                Spacer()
                
                // 4. Actions
                HStack(spacing: 20) {
                    if viewModel.isGenerating {
                        Button {
                            viewModel.stopGeneration()
                        } label: {
                            HStack {
                                Image(systemName: "stop.fill")
                                Text("停止生成")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            viewModel.startGeneration()
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("开始批量生成")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.selectedDifficulty == nil ? Color.gray : Color.themeSkyBlue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.selectedDifficulty == nil)
                    }
                }
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 600)
        .background(Color.themeBgSky50)
        .onDisappear {
            viewModel.stopGeneration()
        }
    }
}

//
//  TTSCacheManager.swift
//  xuedazi
//
//  Created by up on 2026/2/21.
//

import Foundation
import CommonCrypto

/// TTS 缓存管理器 - 避免重复调用 API，缓存合成的音频
class TTSCacheManager {
    static let shared = TTSCacheManager()
    
    // 内存缓存（当前会话）
    private let audioCache = NSCache<NSString, NSData>()
    
    // 磁盘缓存路径
    private let cacheDirectory: URL
    
    // 缓存统计
    private var hitCount = 0
    private var missCount = 0
    
    // 线程安全锁
    private let lock = NSLock()
    
    private var memoryCacheLimitMB: Int
    
    var cacheDirectoryURL: URL {
        cacheDirectory
    }
    
    func updateMemoryCacheLimitMB(_ limit: Int) {
        guard limit > 0 else { return }
        memoryCacheLimitMB = limit
        audioCache.totalCostLimit = limit * 1024 * 1024
        UserDefaults.standard.set(limit, forKey: "ttsMemoryCacheLimitMB")
    }
    
    private init() {
        let savedLimit = UserDefaults.standard.integer(forKey: "ttsMemoryCacheLimitMB")
        let initialLimit = savedLimit > 0 ? savedLimit : 200
        self.memoryCacheLimitMB = initialLimit
        audioCache.totalCostLimit = initialLimit * 1024 * 1024
        // 尝试统一 Debug 和 Release 的缓存路径
        // 如果是在非沙盒环境（如 Debug），尝试访问沙盒容器路径以共享缓存
        var targetURL: URL?
        
        // 检查是否在沙盒中
        let isSandboxed = ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
        
        if !isSandboxed, let bundleID = Bundle.main.bundleIdentifier {
            // 非沙盒环境，手动构造沙盒路径
            // ~/Library/Containers/{BundleID}/Data/Library/Caches/TTSAudio
            let home = FileManager.default.homeDirectoryForCurrentUser
            let sandboxPath = home.appendingPathComponent("Library/Containers/\(bundleID)/Data/Library/Caches/TTSAudio")
            
            // 尝试创建目录以验证是否有权限
            do {
                try FileManager.default.createDirectory(at: sandboxPath, withIntermediateDirectories: true)
                targetURL = sandboxPath
                print("🔧 [TTS-DEBUG] 非沙盒模式，重定向至沙盒缓存：\(sandboxPath.path)")
            } catch {
                print("⚠️ [TTS-DEBUG] 无法访问沙盒路径，回退到标准缓存：\(error)")
            }
        }
        
        if let url = targetURL {
            self.cacheDirectory = url
        } else {
            // 标准逻辑（沙盒内或回退）
            let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            self.cacheDirectory = urls[0].appendingPathComponent("TTSAudio", isDirectory: true)
        }
        
        // 确保缓存目录存在
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        print("📂 [TTS-DEBUG] 最终缓存目录：\(cacheDirectory.path)")
        
    }
    
    /// 生成文本的唯一标识（SHA256）
    private func generateCacheKey(text: String, voice: String) -> String {
        let combined = "\(text)_\(voice)"
        let key = combined.sha256()
        // print("🔑 [TTS-DEBUG] Key: \(key.prefix(8))... (\(text))")
        return key
    }
    
    /// 从缓存获取音频
    func getCachedAudio(text: String, voice: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        
        let key = generateCacheKey(text: text, voice: voice)
        
        // 1. 先查内存缓存
        if let cachedData = audioCache.object(forKey: key as NSString) {
            hitCount += 1
            print("   💾 [TTS-CACHE] 内存命中 ✅")
            return cachedData as Data
        }
        
        // 2. 再查磁盘缓存
        let fileURL = cacheDirectory.appendingPathComponent("\(key).mp3")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let data = try? Data(contentsOf: fileURL) {
                audioCache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
                hitCount += 1
                print("   💾 [TTS-CACHE] 磁盘命中 ✅ (加载到内存)")
                return data
            } else {
                print("   ⚠️ [TTS-CACHE] 文件存在但读取失败: \(fileURL.path)")
            }
        } else {
            // print("   ⚪️ [TTS-CACHE] 文件不存在: \(fileURL.lastPathComponent)")
        }
        
        missCount += 1
        return nil
    }
    
    /// 保存音频到缓存
    func saveToCache(_ audioData: Data, text: String, voice: String) {
        let key = generateCacheKey(text: text, voice: voice)
        let fileURL = cacheDirectory.appendingPathComponent("\(key).mp3")
        
        // 内存操作加锁
        lock.lock()
        audioCache.setObject(audioData as NSData, forKey: key as NSString, cost: audioData.count)
        lock.unlock()
        
        // 磁盘操作不加锁，避免阻塞（但要注意并发写入同一文件的问题，不过 key 唯一一般没事）
        // 也可以选择加锁，简单点
        
        do {
            try audioData.write(to: fileURL)
            print("💾 [TTS-CACHE-SAVE] 已缓存音频到磁盘")
            print("   📝 文本：\"\(text)\"")
            print("   🎙️ 音色：\(voice)")
            print("   📁 路径：\(fileURL.path)")
            print("   📦 大小：\(audioData.count) bytes (\(String(format: "%.2f", Double(audioData.count) / 1024)) KB)")
        } catch {
            print("❌ [TTS-CACHE-ERROR] 保存缓存失败：\(error)")
        }
    }
    
    /// 检查是否已缓存
    func isCached(text: String, voice: String) -> Bool {
        let result = getCachedAudio(text: text, voice: voice) != nil
        print("🔍 [TTS-CHECK] 检查缓存：\"\(text)\" → \(result ? "✅ 已缓存" : "❌ 未缓存")")
        return result
    }
    
    /// 检查文件缓存是否存在（不经过内存）
    func isFileCached(text: String, voice: String) -> Bool {
        let key = generateCacheKey(text: text, voice: voice)
        let fileURL = cacheDirectory.appendingPathComponent("\(key).mp3")
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    /// 检查内存缓存是否存在
    func isMemoryCached(text: String, voice: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let key = generateCacheKey(text: text, voice: voice)
        return audioCache.object(forKey: key as NSString) != nil
    }
    
    /// 预加载一批文本的音频
    func preloadAudios(
        texts: [String],
        voice: String,
        synthesizer: @escaping (String, @escaping (Data?) -> Void) -> Void
    ) {
        print("🔄 [TTS-PRELOAD] 开始预加载任务...")
        print("   📋 总数量：\(texts.count)")
        
        let uncachedTexts = texts.filter { !isCached(text: $0, voice: voice) }
        
        guard !uncachedTexts.isEmpty else {
            print("✅ [TTS-PRELOAD] 所有音频已缓存，无需预加载")
            return
        }
        
        print("🔄 [TTS-PRELOAD] 需要加载：\(uncachedTexts.count) 个音频")
        
        // 串行队列处理预加载，避免并发请求过多
        let preloadQueue = DispatchQueue(label: "com.xuedazi.tts.preload")
        
        preloadQueue.async {
            for (index, text) in uncachedTexts.enumerated() {
                let semaphore = DispatchSemaphore(value: 0)
                
                print("⏳ [TTS-PRELOAD] 正在加载 (\(index + 1)/\(uncachedTexts.count)): \"\(text)\"")
                
                // 切回主线程调用 synthesizer (如果它不是线程安全的)
                DispatchQueue.main.async {
                    synthesizer(text) { [weak self] data in
                        if let data = data {
                            self?.saveToCache(data, text: text, voice: voice)
                            print("   ✅ 加载成功")
                        } else {
                            print("   ❌ 加载失败")
                        }
                        semaphore.signal()
                    }
                }
                
                // 等待当前请求完成，超时 10 秒
                _ = semaphore.wait(timeout: .now() + 10)
                
                // 简单的防抖延时
                Thread.sleep(forTimeInterval: 0.2)
            }
            print("✅ [TTS-PRELOAD] 预加载任务结束")
        }
    }
    
    /// 获取缓存大小（MB）
    func getCacheSize() -> Double {
        var totalSize: Int64 = 0
        
        if let enumerator = FileManager.default.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }
        
        let sizeMB = Double(totalSize) / 1024.0 / 1024.0
        print("💾 [TTS-DEBUG] 缓存总大小：\(String(format: "%.2f", sizeMB)) MB (\(totalSize) bytes)")
        return sizeMB
    }
    
    /// 删除指定文本的缓存
    func deleteCache(for text: String, voice: String) {
        lock.lock()
        defer { lock.unlock() }
        
        let key = generateCacheKey(text: text, voice: voice)
        
        // 1. 删除内存缓存
        if audioCache.object(forKey: key as NSString) != nil {
            audioCache.removeObject(forKey: key as NSString)
            print("   🗑️ [TTS-DELETE] 内存缓存已删除: \"\(text)\"")
        }
        
        // 2. 删除磁盘缓存
        let fileURL = cacheDirectory.appendingPathComponent("\(key).mp3")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("   🗑️ [TTS-DELETE] 磁盘缓存已删除: \"\(text)\"")
            } catch {
                print("   ❌ [TTS-DELETE] 删除失败: \(error)")
            }
        } else {
            print("   ⚠️ [TTS-DELETE] 文件不存在: \"\(text)\"")
        }
    }

    /// 清除所有缓存
    func clearCache() {
        print("🗑️ [TTS-CLEAR] 开始清除缓存...")
        
        lock.lock()
        defer { lock.unlock() }
        
        // 清空内存缓存
        audioCache.removeAllObjects()
        print("   ✅ 内存缓存已清空")
        
        // 删除磁盘缓存文件
        if let enumerator = FileManager.default.enumerator(at: cacheDirectory, includingPropertiesForKeys: nil) {
            var fileCount = 0
            for case let fileURL as URL in enumerator {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    fileCount += 1
                } catch {
                    print("   ❌ 删除失败：\(fileURL.lastPathComponent) - \(error)")
                }
            }
            print("   ✅ 已删除 \(fileCount) 个文件")
        }
        
        // 重置统计
        hitCount = 0
        missCount = 0
        
        print("✅ [TTS-CLEAR] 缓存已清空")
    }
    
    /// 清理旧缓存（保留最近 500 个文件）
    private func cleanupOldCache() {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🧹 [TTS-CLEANUP] 检查旧缓存...")
        
        var files: [(URL, Date)] = []
        
        if let enumerator = FileManager.default.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) {
            for case let fileURL as URL in enumerator {
                if let date = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate {
                    files.append((fileURL, date))
                }
            }
        }
        
        // 按修改日期排序 (最新在前)
        files.sort { $0.1 > $1.1 }
        
        print("   📊 当前缓存文件数：\(files.count)")
        
        // 保留最近 500 个
        let maxFiles = 500
        if files.count <= maxFiles {
             print("   ✅ 缓存数量正常 (<= \(maxFiles))")
             print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
             return
        }
        
        let toDelete = files.dropFirst(maxFiles)
        print("   ⚠️ 缓存超限 (\(files.count) > \(maxFiles))，将删除 \(toDelete.count) 个旧文件")
        
        var deletedCount = 0
        for (fileURL, _) in toDelete {
            do {
                try FileManager.default.removeItem(at: fileURL)
                deletedCount += 1
            } catch {
                print("   ❌ 删除失败：\(fileURL.lastPathComponent)")
            }
        }
        
        print("   ✅ 已清理 \(deletedCount) 个旧文件")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
}

// MARK: - String Extension for SHA256
extension String {
    func sha256() -> String {
        guard let data = data(using: .utf8) else { return "" }
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

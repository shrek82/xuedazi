import Foundation

// 私有缓存类，用于加速拼音转换
// 优化：使用 NSCache 实现 LRU 淘汰策略，限制内存占用
private class PinyinCache {
    static let shared = PinyinCache()
    
    // 使用 NSCache 而不是 Dictionary，自带线程安全和内存管理
    private let cache = NSCache<NSString, NSString>()
    
    private init() {
        cache.countLimit = 5000 // 最多缓存 5000 个词条
        cache.totalCostLimit = 50 * 1024 * 1024 // 最多使用 50MB 内存
    }
    
    func get(_ key: String) -> String? {
        return cache.object(forKey: key as NSString) as String?
    }
    
    func set(_ key: String, value: String) {
        cache.setObject(value as NSString, forKey: key as NSString)
    }
}

extension String {
    func strippingTones() -> String {
        let string = NSMutableString(string: self)
        CFStringTransform(string, nil, kCFStringTransformStripCombiningMarks, false)
        return String(string)
    }
    
    // 将显示用的拼音转换为输入用的纯字母拼音
    // 主要处理：去声调，ü -> v
    // 增加缓存机制，大幅优化 AlignedInputView 的渲染性能
    func toInputPinyin() -> String {
        // Check cache first
        if let cached = PinyinCache.shared.get(self) {
            return cached
        }
        
        var result = ""
        for char in self {
            // 处理 ü 的各种声调形式及原形
            if "üǖǘǚǜ".contains(char) {
                result.append("v")
            } else {
                // 其他字符去声调
                let s = String(char)
                let stripped = s.strippingTones()
                result.append(stripped)
            }
        }
        
        // Cache the result
        PinyinCache.shared.set(self, value: result)
        
        return result
    }
}

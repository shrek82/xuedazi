//
//  XunFeiTTSManager.swift
//  xuedazi
//
//  Created by up on 2026/2/21.
//

import Foundation
import Combine
import AVFoundation
import CommonCrypto

/// 讯飞超拟人 TTS 管理器 - 带缓存机制（WebSocket 版本）
class XunFeiTTSManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private var cancellables = Set<AnyCancellable>()
    static let shared = XunFeiTTSManager()
    
    // 播放完成回调
    private var completionHandler: ((Bool) -> Void)?
    
    // 配置信息
    private let appId = "d9048f87"
    private let apiKey = "05e0783c33c5be41a66cb859525e729a"
    private let apiSecret = "YWU1M2E5OGI3NzI1NmVkMGI2ZGMyMTdi"
    
    // API 地址（私有云超拟人语音合成 - WebSocket）
    private let apiUrl = "wss://cbm01.cn-huabei-1.xf-yun.com/v1/private/mcd9m97e6"
    
    // 缓存管理器
    private let cacheManager = TTSCacheManager.shared
    
    // 音频播放器
    private var audioPlayer: AVAudioPlayer?
    
    // 配置持久化开关
    private let persistSettings: Bool
    
    // 当前音色
    @Published var currentVoice: String {
        didSet {
            if persistSettings {
                UserDefaults.standard.set(currentVoice, forKey: "selectedVoice")
            }
        }
    }
    
    // 语音参数配置（0-100）
    @Published var speed: Int {
        didSet {
            if persistSettings {
                UserDefaults.standard.set(speed, forKey: "ttsSpeed")
            }
        }
    }
    
    @Published var volume: Int {
        didSet {
            if persistSettings {
                UserDefaults.standard.set(volume, forKey: "ttsVolume")
            }
        }
    }
    
    @Published var pitch: Int {
        didSet {
            if persistSettings {
                UserDefaults.standard.set(pitch, forKey: "ttsPitch")
            }
        }
    }
    
    // 可用音色列表（超拟人系列）
    enum VoiceType: String, CaseIterable {
        case lingxiaoxue = "x6_lingxiaoxue_pro"    // 聆小雪（成年女，角色配音）
        case lingxiaoli = "x6_lingxiaoli_pro"      // 聆小璃（成年女，交互聊天）
        case xiaoqiChat = "x6_xiaoqiChat_pro"      // 聆小琪（成年女，交互聊天）
        case lingfeiyi = "x6_lingfeiyi_pro"        // 聆飞逸（成年男，交互聊天）
        case feizheChat = "x6_feizheChat_pro"      // 聆飞哲（成年男，交互聊天）
        case lingxiaoyue = "x6_lingxiaoyue_pro"    // 聆小玥（成年女，交互聊天）
        case lingxiaoxuan = "x6_lingxiaoxuan_pro"  // 聆小璇（成年女，交互聊天）
        case lingyuyan = "x6_lingyuyan_pro"        // 聆玉言（成年女，交互聊天）
        case lingfeihan = "x6_lingfeihan_pro"      // 聆飞瀚（成年男，纪录片）
        case lingfeihao = "x6_lingfeihao_pro"      // 聆飞皓（成年男，广告促销）
        case lingyufei = "x6_lingyufei_pro"        // 聆玉菲（成年女，时政新闻）
        case lingxiaoshan = "x6_lingxiaoshan_pro"  // 聆小珊（成年女，时政新闻）
        case lingxiaoyun = "x6_lingxiaoyun_pro"    // 聆小芸（成年女，角色配音）
        case lingyouyou = "x6_lingyouyou_pro"      // 聆佑佑（童年女，交互聊天）
        case lingxiaoying = "x6_lingxiaoying_pro"  // 聆小颖（成年女，交互聊天）
        case lingxiaozhen = "x6_lingxiaozhen_pro"  // 聆小瑱（成年女，直播带货）
        case lingfeibo = "x6_lingfeibo_pro"        // 聆飞博（成年男，时政新闻）
        case lingxiaotang = "x5_lingxiaotang_flow" // 聆小糖（成年女，语音助手）
        case lingyuzhao = "x5_lingyuzhao_flow"     // 聆玉昭（成年女，交互聊天）
        case pangbainan = "x6_pangbainan1_pro"     // 旁白男声（成年男，旁白配音）
        case pangbainv = "x6_pangbainv1_pro"       // 旁白女声（成年女，旁白配音）
        case gufengpangbai = "x6_gufengpangbai_pro" // 古风旁白（成年男，旁白配音）
        case lingyuaner = "x6_lingyuaner_pro"      // 聆园儿（成年女，儿童绘本）
        case ganliannvxing = "x6_ganliannvxing_pro" // 干练女性（成年女，角色配音）
        case ruyadashu = "x6_ruyadashu_pro"        // 儒雅大叔（成年男，角色配音）
        case huanlemianbao = "x6_huanlemianbao_pro" // 海绵宝宝
        case yulexinwennvsheng = "x6_yulexinwennvsheng_mini" // 娱乐新闻女声
        case huoposhaonian = "x6_huoposhaonian_pro" // 活泼少年
        case lingbosong = "x6_lingbosong_pro" // 聆伯松
        case shibingnvsheng = "x6_shibingnvsheng_mini" // 士兵女声
        case tiexinnanyou = "x6_tiexinnanyou_mini" // 贴心男友
        case gaolengnanshen = "x6_gaolengnanshen_pro" // 高冷男神
        case xiaonaigoudidi = "x6_xiaonaigoudidi_mini" // 小奶狗弟弟
        case taiqiangnuannan = "x6_taiqiangnuannan_pro" // 台湾腔温柔男声
        case wumeinv = "x6_wumeinv_pro" // 妩媚姐姐
        case dongmanshaonv = "x6_dongmanshaonv_pro" // 动漫少女
        case dudulibao = "x6_dudulibao_pro" // 少女可莉
        case huajidama = "x6_huajidama_pro" // 滑稽大妈
        case yingxiaonv = "x6_yingxiaonv_pro" // 营销女声
        case wenrounansheng = "x6_wenrounansheng_mini" // 温柔男声
        case wennuancixingnansheng = "x6_wennuancixingnansheng_mini" // 温暖磁性男声
        case grant = "x5_EnUs_Grant_flow"          // Grant（成年女，英文美式口音）
        case lila = "x5_EnUs_Lila_flow"            // Lila（成年女，英文美式口音）
        
        var displayName: String {
            switch self {
            case .lingxiaoxue: return "聆小雪 (角色配音)"
            case .lingxiaoli: return "聆小璃 (交互聊天)"
            case .xiaoqiChat: return "聆小琪 (交互聊天)"
            case .lingfeiyi: return "聆飞逸 (交互聊天)"
            case .feizheChat: return "聆飞哲 (交互聊天)"
            case .lingxiaoyue: return "聆小玥 (交互聊天)"
            case .lingxiaoxuan: return "聆小璇 (交互聊天)"
            case .lingyuyan: return "聆玉言 (交互聊天)"
            case .lingfeihan: return "聆飞瀚 (纪录片)"
            case .lingfeihao: return "聆飞皓 (广告促销)"
            case .lingyufei: return "聆玉菲 (时政新闻)"
            case .lingxiaoshan: return "聆小珊 (时政新闻)"
            case .lingxiaoyun: return "聆小芸 (角色配音)"
            case .lingyouyou: return "聆佑佑 (童年女声)"
            case .lingxiaoying: return "聆小颖 (交互聊天)"
            case .lingxiaozhen: return "聆小瑱 (直播带货)"
            case .lingfeibo: return "聆飞博 (时政新闻)"
            case .lingxiaotang: return "聆小糖 (语音助手)"
            case .lingyuzhao: return "聆玉昭 (交互聊天)"
            case .pangbainan: return "旁白男声"
            case .pangbainv: return "旁白女声"
            case .gufengpangbai: return "古风旁白"
            case .lingyuaner: return "聆园儿 (儿童绘本)"
            case .ganliannvxing: return "干练女性"
            case .ruyadashu: return "儒雅大叔"
            case .huanlemianbao: return "海绵宝宝"
            case .yulexinwennvsheng: return "娱乐新闻女声"
            case .huoposhaonian: return "活泼少年"
            case .lingbosong: return "聆伯松"
            case .shibingnvsheng: return "士兵女声"
            case .tiexinnanyou: return "贴心男友"
            case .gaolengnanshen: return "高冷男神"
            case .xiaonaigoudidi: return "小奶狗弟弟"
            case .taiqiangnuannan: return "台湾腔温柔男声"
            case .wumeinv: return "妩媚姐姐"
            case .dongmanshaonv: return "动漫少女"
            case .dudulibao: return "少女可莉"
            case .huajidama: return "滑稽大妈"
            case .yingxiaonv: return "营销女声"
            case .wenrounansheng: return "温柔男声"
            case .wennuancixingnansheng: return "温暖磁性男声"
            case .grant: return "Grant (English)"
            case .lila: return "Lila (English)"
            }
        }
    }
    
    // 当前 WebSocket 任务
    private var currentTask: URLSessionWebSocketTask?
    
    init(persistSettings: Bool = true) {
        self.persistSettings = persistSettings
        
        if persistSettings {
            self.currentVoice = UserDefaults.standard.string(forKey: "selectedVoice") ?? "x6_lingyuaner_pro"
            self.speed = UserDefaults.standard.integer(forKey: "ttsSpeed") == 0 ? 60 : UserDefaults.standard.integer(forKey: "ttsSpeed")
            self.volume = UserDefaults.standard.integer(forKey: "ttsVolume") == 0 ? 50 : UserDefaults.standard.integer(forKey: "ttsVolume")
            self.pitch = UserDefaults.standard.integer(forKey: "ttsPitch") == 0 ? 50 : UserDefaults.standard.integer(forKey: "ttsPitch")
        } else {
            self.currentVoice = "x6_lingyuaner_pro"
            self.speed = 60
            self.volume = 50
            self.pitch = 50
        }
        
        super.init()
    }
    
    /// 朗读文本（优先使用缓存）
    func speak(text: String, rateMultiplier: Float = 1.0, completion: ((Bool) -> Void)? = nil) {
        // 取消之前的播放和合成任务
        stop()
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔊 [TTS-SPEAK] 请求朗读：\"\(text)\" (倍率: \(rateMultiplier))")
        print("   🎙️ 当前音色：\(currentVoice)")
        
        // 1. 检查缓存
        if let cachedData = cacheManager.getCachedAudio(text: text, voice: currentVoice) {
            print("   💾 [TTS-CACHE] ✅ 命中缓存 (无需联网)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            playAudioData(cachedData, text: text, rateMultiplier: rateMultiplier, completion: completion)
            return
        }
        
        // 1.5 检查是否允许自动调用在线 API
        let autoOnline = UserDefaults.standard.object(forKey: "autoOnlineTTS") as? Bool ?? true
        if !autoOnline {
            print("   ⚠️ [TTS-API] 自动在线语音已禁用且无本地缓存 -> 降级到系统语音")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            completion?(false)
            return
        }
        
        // 2. 缓存未命中，调用 API 合成
        print("   ☁️ [TTS-API] ❌ 缓存未命中 -> 发起网络请求")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // 使用默认 saveToCache=true，底层会自动缓存
        synthesizeSpeech(text: text) { [weak self] audioData in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let data = audioData {
                    print("   ✅ [TTS-API] 合成成功 (已自动缓存)")
                    // 播放
                    self.playAudioData(data, text: text, rateMultiplier: rateMultiplier, completion: completion)
                } else {
                    print("   ❌ [TTS-API] 合成失败")
                    completion?(false)
                }
            }
        }
    }
    
    /// 停止播放和合成
    func stop() {
        // Ensure UI updates and player operations are on Main Thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in self?.stop() }
            return
        }
        
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        
        // 清除回调，防止被调用
        completionHandler = nil
        
        if let task = currentTask {
            print("🛑 [TTS] 取消正在进行的合成任务")
            task.cancel(with: .normalClosure, reason: nil)
            currentTask = nil
        }
    }

    /// 尝试调用讯飞 WebSocket API 合成语音（带重试机制）
    func synthesizeSpeech(text: String, saveToCache: Bool = true, completion: @escaping (Data?) -> Void) {
        attemptSynthesis(text: text, retriesLeft: 2, saveToCache: saveToCache, completion: completion)
    }
    
    /// 预加载音频（批量缓存）
    func preload(texts: [String]) {
        // 使用 cacheManager.preloadAudios 进行串行加载
        // 传入 saveToCache=false 避免 synthesizeSpeech 再次保存（由 preloadAudios 负责保存）
        cacheManager.preloadAudios(texts: texts, voice: currentVoice) { [weak self] text, completion in
            self?.synthesizeSpeech(text: text, saveToCache: false, completion: completion)
        }
    }
    
    /// 尝试合成（带重试机制）
    private func attemptSynthesis(text: String, retriesLeft: Int, saveToCache: Bool, completion: @escaping (Data?) -> Void) {
        // 先检查缓存（虽然外部调用者可能已经检查过，但这里再次检查作为保险）
        if let cachedData = cacheManager.getCachedAudio(text: text, voice: currentVoice) {
            print("✅ [TTS-SYNTH] 内部重试逻辑命中缓存，直接返回")
            completion(cachedData)
            return
        }

        // 1.5 检查是否允许自动调用在线 API (覆盖所有调用入口，包括预加载)
        let autoOnline = UserDefaults.standard.object(forKey: "autoOnlineTTS") as? Bool ?? true
        if !autoOnline {
            print("⚠️ [TTS-SYNTH] 自动在线语音已禁用且无本地缓存 -> 跳过合成: \"\(text)\" (Config: \(autoOnline))")
            completion(nil)
            return
        } else {
            // Debug Log: Explicitly show that it is allowed
            // print("✅ [TTS-SYNTH] 允许在线合成 (Config: \(autoOnline))")
        }

        _synthesizeSpeech(text: text) { [weak self] data in
            if let data = data {
                // 合成成功，保存到缓存
                if saveToCache, let self = self {
                    self.cacheManager.saveToCache(data, text: text, voice: self.currentVoice)
                }
                completion(data)
            } else if retriesLeft > 0 {
                print("⚠️ [TTS] 合成失败，1秒后重试 (剩余次数: \(retriesLeft))")
                DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                    self?.attemptSynthesis(text: text, retriesLeft: retriesLeft - 1, saveToCache: saveToCache, completion: completion)
                }
            } else {
                completion(nil)
            }
        }
    }

    /// 实际执行 WebSocket API 调用
    private func _synthesizeSpeech(text: String, completion: @escaping (Data?) -> Void) {
        print("🌐 [TTS-SYNTH] 开始合成语音...")
        print("   📝 文本：\"\(text)\"")
        print("   🎙️ 音色：\(currentVoice)")
        print("   🔑 APPID: \(appId)")
        print("   🔑 APIKey: \(apiKey.prefix(16))...")
        print("   🌍 API URL: \(apiUrl)")
        
        // 构建鉴权 URL
        let authUrl = buildAuthUrl()
        
        guard let url = URL(string: authUrl) else {
            print("❌ [TTS-SYNTH] URL 构建失败：\(authUrl)")
            completion(nil)
            return
        }
        
        print("🔗 [TTS-SYNTH] WebSocket URL 长度：\(authUrl.count) 字符")
        print("🔍 [TTS-SYNTH] 主机名：\(url.host ?? "未知")")
        
        // DNS 诊断
        if let host = url.host {
            print("🔍 [TTS-DIAG] 正在诊断 DNS 解析：\(host)...")
            print("🔍 [TTS-DIAG] 请确认：")
            print("   1. 私有云域名是否正确")
            print("   2. 是否需要 VPN/内网访问")
            print("   3. 防火墙是否阻止了 WebSocket 连接")
            print("   4. 网络连接是否正常")
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        
        // 创建 WebSocket 任务
        print("🔌 [TTS-SYNTH] 正在连接 WebSocket...")
        let task = URLSession.shared.webSocketTask(with: request)
        currentTask = task
        task.resume()
        
        // 监听连接状态
        print("⏳ [TTS-SYNTH] 等待 WebSocket 连接...")
        
        // 接收音频数据（使用 AudioDataCollector 避免 inout 问题）
        let collector = AudioDataCollector()
        receiveAudioData(from: task, collector: collector, completion: completion)
        
        // 发送文本数据
        sendTextData(to: task, text: text)
    }
    
    /// 构建鉴权 URL（私有云版本）
    private func buildAuthUrl() -> String {
        // 私有云部署需要鉴权参数
        let date = Date().httpDate
        // 从 apiUrl 提取 host 和 path，确保签名一致
        guard let urlComponents = URLComponents(string: apiUrl),
              let host = urlComponents.host else {
            print("❌ [TTS-AUTH] URL 解析失败")
            return apiUrl
        }
        let path = urlComponents.path
        
        // 签名原始字符串（必须与请求行完全一致）
        let signatureOrigin = "host: \(host)\ndate: \(date)\nGET \(path) HTTP/1.1"
        print("📝 [TTS-AUTH] 签名原文：\n\(signatureOrigin)")
        
        // HMAC-SHA256 签名
        let signature = hmacSHA256(message: signatureOrigin, key: apiSecret)
        let signatureBase64 = signature.base64EncodedString()
        print("🔐 [TTS-AUTH] 签名结果：\(signatureBase64)")
        
        // 授权字符串（注意空格和引号格式）
        let authorization = "api_key=\"\(apiKey)\", algorithm=\"hmac-sha256\", headers=\"host date request-line\", signature=\"\(signatureBase64)\""
        
        // 关键修正：authorization 字符串本身需要先进行 Base64 编码
        let authorizationBase64 = Data(authorization.utf8).base64EncodedString()
        
        // 构建完整 URL（参数需要正确编码）
        // 使用严格的 RFC 3986 Unreserved 字符集，确保所有特殊字符（如 + = / , 空格）都被编码
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        
        let encodedAuth = authorizationBase64.addingPercentEncoding(withAllowedCharacters: allowed) ?? authorizationBase64
        let encodedDate = date.addingPercentEncoding(withAllowedCharacters: allowed) ?? date
        let encodedHost = host.addingPercentEncoding(withAllowedCharacters: allowed) ?? host
        
        let finalURL = "\(apiUrl)?authorization=\(encodedAuth)&date=\(encodedDate)&host=\(encodedHost)"
        print("🔗 [TTS-AUTH] 鉴权 URL: \(finalURL.prefix(200))...")
        return finalURL
    }
    
    /// 接收音频数据
    private func receiveAudioData(from task: URLSessionWebSocketTask, collector: AudioDataCollector, completion: @escaping (Data?) -> Void) {
        task.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self.handleResponseData(data, from: task, collector: collector, completion: completion)
                    
                case .string(let text):
                    // 讯飞 WebSocket 有时会以 Text Frame 返回 JSON
                    if let data = text.data(using: .utf8) {
                        self.handleResponseData(data, from: task, collector: collector, completion: completion)
                    } else {
                        print("❌ 无法将文本消息转换为 Data")
                        self.receiveAudioData(from: task, collector: collector, completion: completion)
                    }
                    
                @unknown default:
                    self.receiveAudioData(from: task, collector: collector, completion: completion)
                }
                
            case .failure(let error):
                print("❌ 接收失败：\(error)")
                if let urlError = error as? URLError, urlError.code == .cannotFindHost {
                    print("⚠️ [TTS-DIAG] DNS 解析失败！")
                    print("⚠️ [TTS-DIAG] 请检查项目是否启用了 App Sandbox 的网络权限：")
                    print("   👉 在 Xcode 中打开项目 -> Signing & Capabilities -> App Sandbox")
                    print("   👉 勾选 'Outgoing Connections (Client)'")
                }
                // 仅当不是正常的连接关闭错误时才视为失败
                // 如果 collector 中已有数据，尝试返回成功（应对某些断开连接的情况）
                if collector.count > 0 {
                    print("⚠️ 连接中断，但已接收 \(collector.count) 字节数据，尝试播放")
                    completion(collector.data)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    /// 处理响应数据（核心逻辑）
    private func handleResponseData(_ data: Data, from task: URLSessionWebSocketTask, collector: AudioDataCollector, completion: @escaping (Data?) -> Void) {
        do {
            // 解析响应 JSON (适配 header/payload 结构)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let header = json["header"] as? [String: Any],
               let code = header["code"] as? Int {
                
                if code != 0 {
                    print("❌ API 错误：\(header["message"] as? String ?? "未知错误") (Code: \(code))")
                    completion(nil)
                    return
                }
                
                // 提取音频数据
                if let payload = json["payload"] as? [String: Any],
                   let audioData = payload["audio"] as? [String: Any],
                   let audioBase64 = audioData["audio"] as? String,
                   let audioBytes = Data(base64Encoded: audioBase64) {
                    
                    collector.append(audioBytes)
                    
                    // 检查是否结束
                    if let status = audioData["status"] as? Int, status == 2 {
                        // 合成完成
                        print("✅ 音频合成完成，总大小：\(collector.count) bytes")
                        completion(collector.data)
                        // 任务完成，不再递归调用 receiveAudioData，避免 Socket is not connected 错误
                        return
                    }
                }
                
                // 继续接收下一帧
                self.receiveAudioData(from: task, collector: collector, completion: completion)
            } else {
                print("❌ 解析响应结构失败")
                // 尝试继续接收，避免因单次解析失败中断
                self.receiveAudioData(from: task, collector: collector, completion: completion)
            }
        } catch {
            print("❌ 解析 JSON 失败：\(error)")
            completion(nil)
        }
    }
    
    /// 发送文本数据
    private func sendTextData(to task: URLSessionWebSocketTask, text: String) {
        // 构建请求 JSON (严格对齐 Python 示例结构)
        let requestJson: [String: Any] = [
            "header": [
                "app_id": appId,
                "status": 2
            ],
            "parameter": [
                "tts": [
                    "vcn": currentVoice,
                    "volume": volume,
                    "speed": speed,
                    "pitch": pitch,
                    "rhy": 0,
                    "bgs": 0,
                    "reg": 0,
                    "rdn": 0,
                    "audio": [
                        "encoding": "lame",
                        "sample_rate": 24000,
                        "channels": 1,
                        "bit_depth": 16,
                        "frame_size": 0
                    ]
                ]
            ],
            "payload": [
                "text": [
                    "encoding": "utf8",
                    "compress": "raw",
                    "format": "plain",
                    "status": 2,
                    "seq": 0,
                    "text": Data(text.utf8).base64EncodedString()
                ]
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestJson)
            print("📤 [TTS-SEND] 发送请求 JSON: \(String(data: jsonData, encoding: .utf8) ?? "")")
            task.send(.data(jsonData)) { error in
                if let error = error {
                    print("❌ 发送失败：\(error)")
                    if let urlError = error as? URLError, urlError.code == .cannotFindHost {
                        print("⚠️ [TTS-DIAG] DNS 解析失败！请检查 macOS App Sandbox 设置中是否勾选了 'Outgoing Connections (Client)'")
                    }
                } else {
                    print("✅ 文本已发送")
                }
            }
        } catch {
            print("❌ 序列化失败：\(error)")
        }
    }
    
    /// 播放音频数据
    private func playAudioData(_ data: Data, text: String, rateMultiplier: Float, completion: ((Bool) -> Void)?) {
        do {
            // 停止之前的播放
            if let player = audioPlayer, player.isPlaying {
                player.stop()
            }
            
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.enableRate = true
            
            // 针对单字朗读，加快播放速度
            if text.count == 1 {
                // 单字基础速度由配置决定 (默认 2.0x)，乘以倍率
                let baseSpeed = Float(GameSettings.shared.singleCharSpeedMultiplier)
                let rate = baseSpeed * rateMultiplier
                // 上限放宽到 4.0 以支持更高的配置
                audioPlayer?.rate = max(0.5, min(rate, 4.0))
                print("   ⚡️ [TTS-PLAY] 单字朗读，速度: \(String(format: "%.2f", audioPlayer?.rate ?? 0))x (配置: \(baseSpeed)x)")
            } else {
                // 多字基础速度 1.0x，乘以倍率
                let rate = 1.0 * rateMultiplier
                audioPlayer?.rate = max(0.5, min(rate, 2.0))
            }
            
            self.completionHandler = completion
            audioPlayer?.prepareToPlay()
            if audioPlayer?.play() == true {
                // 播放成功
            } else {
                print("❌ [XUNFEI-TTS] audioPlayer.play() 返回 false")
                completion?(false)
                self.completionHandler = nil
            }
        } catch {
            print("❌ 播放失败：\(error)")
            completion?(false)
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("✅ [XUNFEI-TTS] 播放完成")
        // 必须先取出 handler，然后置空，最后调用
        // 否则如果 handler 中同步调用了 speak()，新的 completionHandler 会被这里的 nil 覆盖
        let handler = completionHandler
        completionHandler = nil
        handler?(true)
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ [XUNFEI-TTS] 播放解码错误：\(error?.localizedDescription ?? "未知")")
        let handler = completionHandler
        completionHandler = nil
        handler?(false)
    }
    
    /// 预加载一批文本（游戏开始前调用）
    func preloadTexts(_ texts: [String]) {
        cacheManager.preloadAudios(texts: texts, voice: currentVoice) { [weak self] text, completion in
            self?.synthesizeSpeech(text: text, completion: completion)
        }
    }
    
    /// 检查文本是否已缓存
    func isCached(text: String) -> Bool {
        return cacheManager.isCached(text: text, voice: currentVoice)
    }
    
    /// 清除缓存
    func clearCache() {
        cacheManager.clearCache()
    }
    
    /// 获取缓存大小
    func getCacheSize() -> Double {
        return cacheManager.getCacheSize()
    }
}



// MARK: - AudioDataCollector
class AudioDataCollector {
    private var audioData = Data()
    private let queue = DispatchQueue(label: "com.xuedazi.audiocollector")
    
    var count: Int {
        queue.sync { audioData.count }
    }
    
    var data: Data {
        queue.sync { Data(audioData) }
    }
    
    func append(_ newData: Data) {
        queue.async { [self] in
            audioData.append(newData)
        }
    }
}

// MARK: - Helper Functions
private extension XunFeiTTSManager {
    func hmacSHA256(message: String, key: String) -> Data {
        let messageData = Data(message.utf8)
        let keyData = Data(key.utf8)
        
        var result = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        result.withUnsafeMutableBytes { pointer in
            CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), (keyData as NSData).bytes, keyData.count, (messageData as NSData).bytes, messageData.count, pointer.baseAddress)
        }
        
        return result
    }
}

// MARK: - Date Extension
extension Date {
    var httpDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        return formatter.string(from: self)
    }
}

// MARK: - Data Extension
extension Data {
    var base64EncodedString: String {
        base64EncodedString()
    }
}

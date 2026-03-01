//
//  TypingSpeedView.swift
//  xuedazi
//
//  Created by up on 2026/3/1.
//

import SwiftUI

/// 汉字输入速度统计进度条
/// 显示当前轮游戏的实时输入速度（字/分钟）
/// 速度统计已排除 TTS 朗读和跳转等待时间，仅计算有效输入时间
/// 风格与其他进度条保持一致（彩色渐变进度条）
struct TypingSpeedProgressBar: View {
    let typingSpeedWPM: Double
    let isPausedForTTS: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon - 速度表图标，根据速度动态变化
            Image(systemName: speedIcon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(speedColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 6) {
                // Labels
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(speedLabel)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(speedColor)
                    
                    if isPausedForTTS {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.orange)
                            .transition(.opacity.combined(with: .scale))
                    }
                    
                    Spacer()
                }
                
                // Progress Bar (使用与其他进度条一致的样式)
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        // Track
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                            .frame(height: 8)
                        
                        // Fill - 彩色渐变进度条
                        Capsule()
                            .fill(LinearGradient(colors: [speedColor, speedColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, min(progressWidth * proxy.size.width, proxy.size.width)), height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: typingSpeedWPM)
                    }
                }
                .frame(height: 8)
                
                Text("输入速度")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }
    
    /// 根据速度返回合适的图标
    private var speedIcon: String {
        if typingSpeedWPM < 30 {
            return "tortoise.fill"  // 乌龟 - 慢速
        } else if typingSpeedWPM < 60 {
            return "hare.fill"  // 兔子 - 中速
        } else if typingSpeedWPM < 100 {
            return "bolt.fill"  // 闪电 - 快速
        } else {
            return "flame.fill"  // 火焰 - 极速
        }
    }
    
    /// 根据速度返回合适的颜色（与其他进度条颜色一致）
    private var speedColor: Color {
        if typingSpeedWPM < 30 {
            return .orange
        } else if typingSpeedWPM < 60 {
            return .themeSkyBlue
        } else if typingSpeedWPM < 100 {
            return .themeAmberYellow
        } else {
            return .themeSuccessGreen
        }
    }
    
    /// 格式化的速度标签
    private var speedLabel: String {
        if typingSpeedWPM < 10 {
            return String(format: "%.1f 字/分", typingSpeedWPM)
        } else {
            return String(format: "%.0f 字/分", typingSpeedWPM)
        }
    }
    
    /// 进度条宽度比例（0-1）
    /// 假设最高速度为 150 字/分，超过则保持满进度
    private var progressWidth: CGFloat {
        let maxSpeed: Double = 150.0
        return min(CGFloat(typingSpeedWPM / maxSpeed), 1.0)
    }
}

#if DEBUG
struct TypingSpeedProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TypingSpeedProgressBar(typingSpeedWPM: 25.5, isPausedForTTS: false)
                .previewDisplayName("慢速")
                .padding()
                .background(Color.themeBgSky50)
            
            TypingSpeedProgressBar(typingSpeedWPM: 55.0, isPausedForTTS: false)
                .previewDisplayName("中速")
                .padding()
                .background(Color.themeBgSky50)
            
            TypingSpeedProgressBar(typingSpeedWPM: 85.0, isPausedForTTS: false)
                .previewDisplayName("快速")
                .padding()
                .background(Color.themeBgSky50)
            
            TypingSpeedProgressBar(typingSpeedWPM: 120.0, isPausedForTTS: false)
                .previewDisplayName("极速")
                .padding()
                .background(Color.themeBgSky50)
            
            TypingSpeedProgressBar(typingSpeedWPM: 60.0, isPausedForTTS: true)
                .previewDisplayName("TTS 暂停中")
                .padding()
                .background(Color.themeBgSky50)
        }
    }
}
#endif

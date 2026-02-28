//
//  OverlayViews.swift
//  xuedazi
//
//  Created by up on 2026/2/12.
//

import SwiftUI
import Combine

struct SuccessOverlay: View {
    let onNext: () -> Void
    
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            
            if showConfetti {
                ConfettiView()
            }
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.themeSuccessGreen.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Text("🎉")
                        .font(.system(size: 60))
                        .scaleEffect(showConfetti ? 1.1 : 0.9)
                        .animation(.spring(response: 0.5, dampingFraction: 0.5).repeatForever(autoreverses: true), value: showConfetti)
                }
                
                VStack(spacing: 8) {
                    Text("太棒了!")
                        .font(FontLoader.shared.chineseFont(size: 36).weight(.black))
                        .foregroundColor(.themeSuccessGreen)
                    
                    Text("你真了不起！")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.gray)
                }
                
                Button(action: onNext) {
                    HStack {
                        Text("下一个")
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .font(FontLoader.shared.chineseFont(size: 20))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.themeSuccessGreen)
                            .shadow(color: Color.themeSuccessGreen.opacity(0.3), radius: 8, y: 4)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 40)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.themeSuccessGreen.opacity(0.15), lineWidth: 10)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 25, x: 0, y: 12)
            )
            .frame(width: 320)
            .scaleEffect(showConfetti ? 1.0 : 0.5)
            .opacity(showConfetti ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showConfetti)
        }
        .onAppear {
            showConfetti = true
        }
    }
}

// MARK: - Full Screen Confetti
struct FullScreenConfettiView: View {
    @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State private var particles: [ConfettiParticleData] = []
    
    struct ConfettiParticleData: Identifiable {
        let id = UUID()
        let color: Color
        let x: CGFloat
        let size: CGFloat
        let rotation: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiFallingParticle(data: particle, screenHeight: geometry.size.height)
                }
            }
            .onReceive(timer) { _ in
                // Add new particles
                if particles.count < 100 {
                    let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .orange, .purple]
                    let newParticle = ConfettiParticleData(
                        color: colors.randomElement()!,
                        x: CGFloat.random(in: 0...geometry.size.width),
                        size: CGFloat.random(in: 8...16),
                        rotation: Double.random(in: 0...360)
                    )
                    particles.append(newParticle)
                }
                
                // Remove old particles (handled by view logic or cleanup here)
                // For simplicity, we just keep adding until limit, but in real app we should remove off-screen
                if particles.count > 150 {
                    particles.removeFirst(50)
                }
            }
        }
        .drawingGroup() // Metal acceleration
        .ignoresSafeArea()
    }
}

struct ConfettiFallingParticle: View {
    let data: FullScreenConfettiView.ConfettiParticleData
    let screenHeight: CGFloat
    
    @State private var y: CGFloat = -20
    @State private var rotation: Double = 0
    
    var body: some View {
        Rectangle()
            .fill(data.color)
            .frame(width: data.size, height: data.size * 0.6)
            .rotationEffect(.degrees(rotation))
            .position(x: data.x, y: y)
            .onAppear {
                rotation = data.rotation
                withAnimation(.linear(duration: Double.random(in: 2...4))) {
                    y = screenHeight + 50
                    rotation += 360
                }
            }
    }
}

// MARK: - Success Sparkle Effect
struct SuccessSparkleView: View {
    @State private var particles: [SparkleParticle] = []
    
    struct SparkleParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var angle: Double
        var speed: CGFloat
        var scale: CGFloat
        var color: Color
        var opacity: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Image(systemName: "star.fill")
                        .font(.system(size: 20))
                        .foregroundColor(particle.color)
                        .scaleEffect(particle.scale)
                        .opacity(particle.opacity)
                        .position(x: particle.x, y: particle.y)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
            }
        }
        .drawingGroup() // Metal acceleration
        .allowsHitTesting(false)
    }
    
    private func createParticles(in size: CGSize) {
        // 向上偏移 20 点，使爆炸中心更接近文字视觉中心（因为文字通常有底部留白）
        let center = CGPoint(x: size.width / 2, y: size.height / 2 - 20)
        let colors: [Color] = [.yellow, .orange, .white, .themeSkyBlue, .pink]
        
        var newParticles: [SparkleParticle] = []
        for _ in 0..<20 {
            let angle = Double.random(in: 0...360)
            let speed = CGFloat.random(in: 100...300)
            let particle = SparkleParticle(
                x: center.x,
                y: center.y,
                angle: angle,
                speed: speed,
                scale: CGFloat.random(in: 0.5...1.5),
                color: colors.randomElement()!,
                opacity: 1.0
            )
            newParticles.append(particle)
        }
        particles = newParticles
        
        // Start animation immediately
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.8)) {
                for i in 0..<self.particles.count {
                    let angleRad = self.particles[i].angle * .pi / 180
                    self.particles[i].x += cos(angleRad) * self.particles[i].speed
                    self.particles[i].y += sin(angleRad) * self.particles[i].speed
                    self.particles[i].opacity = 0
                    self.particles[i].scale = 0.1
                }
            }
        }
    }
}

struct FireEffectView: View {
    @State private var particles: [FireParticleData] = []
    @State private var timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    struct FireParticleData: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let duration: Double
        let isLeft: Bool
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [.yellow, .orange, .red, .clear]),
                                center: .center,
                                startRadius: 0,
                                endRadius: particle.size
                            )
                        )
                        .frame(width: particle.size * 2, height: particle.size * 2)
                        .position(x: particle.x, y: particle.y)
                        .opacity(0.6)
                        .modifier(FireParticleModifier(duration: particle.duration, isLeft: particle.isLeft))
                }
            }
            .onReceive(timer) { _ in
                // Add new particles from sides
                for _ in 0..<3 {
                    let isLeft = Bool.random()
                    // 调整火焰粒子大小：从 20...60 减小到 10...35，避免过于遮挡
                    let size = CGFloat.random(in: 10...35)
                    
                    // Spawn at left or right edge
                    let startX = isLeft ? -size : geometry.size.width + size
                    // Spawn along the bottom 60% of the screen height
                    let startY = CGFloat.random(in: (geometry.size.height * 0.4)...geometry.size.height)
                    
                    let newParticle = FireParticleData(
                        x: startX,
                        y: startY,
                        size: size,
                        duration: Double.random(in: 0.8...1.8),
                        isLeft: isLeft
                    )
                    particles.append(newParticle)
                }
                
                if particles.count > 60 {
                    particles.removeFirst(5)
                }
            }
        }
        .drawingGroup() // Metal acceleration for performance
        .ignoresSafeArea()
        .allowsHitTesting(false) // Pass touches through
    }
}

struct FireParticleModifier: ViewModifier {
    let duration: Double
    let isLeft: Bool
    
    @State private var xOffset: CGFloat = 0
    @State private var yOffset: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .offset(x: xOffset, y: yOffset)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    // Move inward and upward
                    xOffset = isLeft ? CGFloat.random(in: 50...150) : -CGFloat.random(in: 50...150)
                    yOffset = -CGFloat.random(in: 50...150)
                    opacity = 0
                    scale = 0.2
                }
            }
    }
}

// MARK: - Damage Effect
struct DamageEffectView: View {
    var body: some View {
        Color.red
            .opacity(0.3)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .blendMode(.overlay)
    }
}

struct ConfettiView: View {
    var body: some View {
        ZStack {
            ForEach(0..<30, id: \.self) { index in
                ConfettiParticle(index: index)
            }
        }
        .drawingGroup() // Metal acceleration
    }
}

struct ConfettiParticle: View {
    let index: Int
    
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1.0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    private let color: Color
    private let size: CGFloat
    private let angle: Double
    private let distance: CGFloat
    private let duration: Double
    private let delay: Double
    
    init(index: Int) {
        self.index = index
        
        let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .orange, .purple]
        self.color = colors[index % colors.count]
        self.size = CGFloat.random(in: 6...12)
        self.angle = (Double(index) * 12.0) + Double.random(in: -10...10)
        self.distance = CGFloat.random(in: 150...300)
        self.duration = Double.random(in: 0.8...1.2)
        self.delay = Double.random(in: 0...0.15)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: size, height: size)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .offset(offset)
            .onAppear {
                let radians = angle * .pi / 180
                let targetX = cos(radians) * distance
                let targetY = sin(radians) * distance + 100
                
                withAnimation(.easeOut(duration: duration).delay(delay)) {
                    offset = CGSize(width: targetX, height: targetY)
                    scale = 0.5
                }
                
                withAnimation(.linear(duration: duration).delay(delay)) {
                    rotation = Double.random(in: 180...540)
                }
                
                withAnimation(.easeIn(duration: duration * 0.4).delay(delay + duration * 0.6)) {
                    opacity = 0
                }
            }
    }
}

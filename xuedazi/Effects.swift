//
//  Effects.swift
//  xuedazi
//
//  Created by up on 2026/2/12.
//

import SwiftUI

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit: Int = 3
    var animatableData: CGFloat

    init(clicks: Int) {
        self.animatableData = CGFloat(clicks)
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

// MARK: - Lucky Drop Effect (Falling Gifts)
struct LuckyDropView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<8, id: \.self) { _ in
                    FallingGift(containerSize: geometry.size)
                }
            }
            .drawingGroup() // Optimize rendering for multiple animated elements
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

struct FallingGift: View {
    let containerSize: CGSize
    
    @State private var offset: CGSize
    @State private var rotation: Double
    @State private var scale: CGFloat
    @State private var opacity: Double
    
    private let duration: Double
    private let delay: Double
    private let xWobble: CGFloat
    
    init(containerSize: CGSize) {
        self.containerSize = containerSize
        
        let startX = CGFloat.random(in: 20...containerSize.width - 20)
        let startY = CGFloat.random(in: -containerSize.height * 0.3 ... -50)
        
        _offset = State(initialValue: CGSize(width: startX, height: startY))
        _rotation = State(initialValue: Double.random(in: -30...30))
        _scale = State(initialValue: CGFloat.random(in: 0.8...1.2))
        _opacity = State(initialValue: 1.0) // Start visible (off-screen)
        
        self.duration = Double.random(in: 2.0...3.5)
        self.delay = Double.random(in: 0...0.5)
        self.xWobble = CGFloat.random(in: -30...30)
    }
    
    var body: some View {
        Image(systemName: "gift.fill")
            .font(.system(size: 48)) // Increased size
            .foregroundStyle(
                LinearGradient(
                    colors: [.pink, .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: .white.opacity(0.6), radius: 5, x: 0, y: 0)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                // Falling animation
                withAnimation(.linear(duration: duration).delay(delay).repeatForever(autoreverses: false)) {
                    self.offset = CGSize(
                        width: self.offset.width + xWobble,
                        height: self.offset.height + containerSize.height + 200
                    )
                    self.rotation += 360
                }
            }
    }
}

// MARK: - Key Press Particle Effect
struct KeyPressParticle: View {
    let color: Color
    let angle: Double
    
    @State private var distance: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(x: distance, y: 0)
            .rotationEffect(.degrees(angle))
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) {
                    distance = CGFloat.random(in: 20...40)
                    opacity = 0
                    scale = 0.2
                }
            }
    }
}

struct KeyPressEffect: View {
    let color: Color
    
    var body: some View {
        ZStack {
            ForEach(0..<12) { i in
                KeyPressParticle(color: color, angle: Double(i) * 30.0)
            }
        }
    }
}

// MARK: - Typing Sparkle Effect
struct TypingSparkle: View {
    let color: Color
    
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    
    var body: some View {
        Image(systemName: "sparkle")
        // ... (rest of the code remains same, just ensuring context)
            .font(.system(size: 12))
            .foregroundColor(color)
            .scaleEffect(scale)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .offset(offset)
            .onAppear {
                let angle = Double.random(in: -60...60) - 90 // Upwards
                let distance = CGFloat.random(in: 30...60)
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    offset = CGSize(
                        width: cos(angle * .pi / 180) * distance,
                        height: sin(angle * .pi / 180) * distance
                    )
                    scale = 1.5
                    rotation = Double.random(in: -90...90)
                }
                
                withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                    opacity = 0
                    scale = 0.5
                }
            }
    }
}

struct TypingSparkleEffect: View {
    let color: Color
    
    var body: some View {
        ZStack {
            ForEach(0..<5) { _ in
                TypingSparkle(color: color)
            }
        }
    }
}

// MARK: - Random Treasure Effect (Coin Rain)
struct TreasureRainView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Reduced count for better performance (50 -> 30)
                ForEach(0..<30, id: \.self) { _ in
                    FallingCoin(containerSize: geometry.size)
                }
            }
            .drawingGroup() // Optimize rendering for multiple animated elements
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

struct FallingCoin: View {
    let containerSize: CGSize
    
    @State private var offset: CGSize
    @State private var rotationY: Double = 0
    @State private var rotationZ: Double = 0
    @State private var scale: CGFloat
    @State private var opacity: Double = 1.0 // Start visible (off-screen)
    
    // Config properties
    private let duration: Double
    private let delay: Double
    private let xWobble: CGFloat
    
    init(containerSize: CGSize) {
        self.containerSize = containerSize
        
        let startX = CGFloat.random(in: 0...containerSize.width)
        let startY = CGFloat.random(in: -containerSize.height * 0.5 ... -50) // Start above screen
        
        _offset = State(initialValue: CGSize(width: startX, height: startY))
        
        // Randomize size for depth perception
        _scale = State(initialValue: CGFloat.random(in: 0.6...1.2))
        
        // Randomize dynamics - Faster fall speed
        self.duration = Double.random(in: 1.5...3.0)
        self.delay = Double.random(in: 0...0.8)
        self.xWobble = CGFloat.random(in: -30...30)
    }
    
    var body: some View {
        Image(systemName: "bitcoinsign.circle.fill")
            .font(.system(size: 28))
            .foregroundColor(.themeAmberYellow)
            // Removed overlay border for cleaner look
            .shadow(color: .orange.opacity(0.4), radius: 2, x: 0, y: 0)
            // Transformations
            .scaleEffect(scale)
            // Removed rotation/flip effects as requested
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                // Falling animation
                withAnimation(.linear(duration: duration).delay(delay).repeatForever(autoreverses: false)) {
                    offset.height += containerSize.height + 200 // Fall down past screen
                    offset.width += xWobble // Slight horizontal drift
                    
                    // No rotation animation
                }
            }
    }
}

// MARK: - Random Meteor Effect (Meteor Shower)
struct MeteorShowerView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background subtle flash or gradient could be added here
                
                ForEach(0..<20, id: \.self) { _ in
                    MeteorView(containerSize: geometry.size)
                }
            }
            .drawingGroup() // Optimize rendering for complex shadows and blurs
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

struct MeteorView: View {
    let containerSize: CGSize
    @State private var offset: CGSize
    @State private var opacity: Double = 1.0 // Start visible (off-screen)
    @State private var scale: CGFloat
    @State private var trailLength: CGFloat
    
    // Config
    private let duration: Double
    private let delay: Double
    
    init(containerSize: CGSize) {
        self.containerSize = containerSize
        
        // Start area: Top edge and Left edge
        // Aiming for a Top-Left -> Bottom-Right flow (Angle ~45 degrees)
        
        // Random start position logic:
        // We want them to cover the screen diagonally.
        // Source line: from (0, -height) to (width, -height) AND (-width, 0) to (-width, height) effectively
        // Simplified: Start somewhere above or to the left of the screen
        
        let isTopStart = Bool.random()
        let startX: CGFloat
        let startY: CGFloat
        
        if isTopStart {
            // Start from Top Edge (including some negative X)
            startX = CGFloat.random(in: -containerSize.width * 0.5 ... containerSize.width)
            startY = CGFloat.random(in: -200 ... -50)
        } else {
            // Start from Left Edge (including some negative Y)
            startX = CGFloat.random(in: -200 ... -50)
            startY = CGFloat.random(in: -containerSize.height * 0.2 ... containerSize.height * 0.8)
        }
        
        _offset = State(initialValue: CGSize(width: startX, height: startY))
        
        // Increased scale for better visibility (0.5...1.0)
        _scale = State(initialValue: CGFloat.random(in: 0.5...1.0))
        
        // Thicker/Longer trails
        _trailLength = State(initialValue: CGFloat.random(in: 120...250))
        
        self.duration = Double.random(in: 1.2...2.5) // Fast shooting stars
        self.delay = Double.random(in: 0...1.5) // Staggered start
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Tail (Gradient fading out)
            LinearGradient(
                colors: [
                    .clear, // End of tail (faded)
                    .white.opacity(0.4), // Increased opacity
                    .cyan.opacity(0.9) // Increased opacity
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: trailLength * scale, height: 4 * scale) // Thicker trail (2 -> 4)
            .mask(Capsule())
            
            // Head (Glowing Star)
            Image(systemName: "star.fill")
                .font(.system(size: 16 * scale)) // Larger star (10 -> 16)
                .foregroundColor(.white)
                .shadow(color: .cyan, radius: 6 * scale) // Increased shadow
                .shadow(color: .white, radius: 3 * scale) // Increased shadow
                .overlay(
                    Circle()
                        .fill(Color.white.opacity(0.8)) // Increased opacity
                        .frame(width: 20 * scale, height: 20 * scale) // Larger glow (14 -> 20)
                        .blur(radius: 3)
                )
        }
        // Rotate to point from Top-Left to Bottom-Right
        // 0 degrees is horizontal right.
        // We want diagonal down-right (approx 30-45 degrees)
        .rotationEffect(.degrees(35))
        .offset(offset)
        .opacity(opacity)
        .onAppear {
            // Move across screen
            // Calculate travel distance to ensure it clears the screen
            let travelDistance = containerSize.width + containerSize.height + 500
            
            // Movement vector for ~35 degrees
            let angleRad = 35.0 * .pi / 180.0
            let moveX = cos(angleRad) * travelDistance
            let moveY = sin(angleRad) * travelDistance
            
            // Use explicit state update for animation
            withAnimation(.linear(duration: duration).delay(delay).repeatForever(autoreverses: false)) {
                // Update offset directly in the animation block
                self.offset = CGSize(
                    width: self.offset.width + moveX,
                    height: self.offset.height + moveY
                )
            }
        }
    }
}

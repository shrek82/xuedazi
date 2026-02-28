//
//  CoinDropView.swift
//  xuedazi
//
//  Created by up on 2026/2/21.
//

import SwiftUI

struct CoinDropView: View {
    @ObservedObject var viewModel: GameViewModel
    
    struct Coin: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var speedY: CGFloat
        var rotation: Double
        var rotationSpeed: Double
        var scale: CGFloat
    }
    
    @State private var coins: [Coin] = []
    @State private var timer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Resolve the symbol once
                guard let symbol = context.resolveSymbol(id: "coin") else { return }
                
                for coin in coins {
                    // Create a copy of the context for each coin to apply transforms independently
                    var ctx = context
                    
                    // Move origin to coin position
                    ctx.translateBy(x: coin.x, y: coin.y)
                    
                    // Apply rotation and scale
                    ctx.rotate(by: Angle(degrees: coin.rotation))
                    ctx.scaleBy(x: coin.scale, y: coin.scale)
                    
                    // Draw symbol at local origin (0,0)
                    ctx.draw(symbol, at: .zero)
                }
            } symbols: {
                Image(systemName: "centsign.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.themeAmberYellow)
                    .tag("coin")
            }
            .onChange(of: viewModel.showCoinDrop) { show in
                if show {
                    triggerCoinDrop(in: geometry.size)
                    // Reset trigger immediately so it can be triggered again
                    DispatchQueue.main.async {
                        viewModel.showCoinDrop = false
                    }
                }
            }
            .onDisappear {
                stopTimer()
            }
        }
        .allowsHitTesting(false)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func triggerCoinDrop(in size: CGSize) {
        stopTimer()
        
        // Create coins
        let count = Int.random(in: 15...25)
        let width = size.width
        let height = size.height
        
        var newCoins: [Coin] = []
        for _ in 0..<count {
            newCoins.append(Coin(
                x: CGFloat.random(in: 0...width),
                y: -CGFloat.random(in: 50...200),
                speedY: CGFloat.random(in: 300...600), // Pixels per second
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: 90...360),
                scale: CGFloat.random(in: 0.8...1.2)
            ))
        }
        self.coins = newCoins
        
        // Start a timer to update physics
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [self] _ in
            guard !coins.isEmpty else {
                self.stopTimer()
                return
            }
            
            var activeCoins: [Coin] = []
            
            for i in 0..<coins.count {
                var coin = coins[i]
                coin.y += coin.speedY * 0.016
                coin.speedY += 1000 * 0.016 // Gravity
                coin.rotation += coin.rotationSpeed * 0.016
                
                if coin.y < height + 50 {
                    activeCoins.append(coin)
                }
            }
            
            coins = activeCoins
            
            if coins.isEmpty {
                self.stopTimer()
            }
        }
    }
}

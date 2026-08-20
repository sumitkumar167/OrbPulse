//
//  UIComponents.swift
//  OrbPulse
//
//  Created by Sumit Kumar on 16/08/26.
//
import SwiftUI

// MARK: - Zero-Stutter Space Background (With Dynamic Rising Game-Over Horizon)
struct AnimatedSpaceBackground: View {
    @ObservedObject var gameState: GameState
    @State private var starOffset: CGFloat = 0
    
    var isFever: Bool { gameState.isFeverActive }
    var isRecordRun: Bool { gameState.hasBeatenHighScoreThisRun }
    var isGameOver: Bool { gameState.isGameOver }
    var skinColor: Color { gameState.selectedSkin.primaryColor }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                // Base Cosmic Void
                Color(red: 0.03, green: 0.03, blue: 0.06)
                    .ignoresSafeArea()
                
                // Starfield Layer
                StarCanvas(isRecordRun: isRecordRun)
                    .offset(y: starOffset)
                
                // Pulse Rush Radiant Flare
                RadialGradient(
                    colors: [Color.yellow.opacity(0.4), Color.clear],
                    center: .bottom,
                    startRadius: 20,
                    endRadius: 400
                )
                .opacity(isFever ? 1.0 : 0.0)
                .animation(.linear(duration: 0.3), value: isFever)
                
                // ⚡️ Expanding Horizon Glow
                // Resting at bottom (260pt) -> Expands to full screen height on Game Over
                LinearGradient(
                    colors: [
                        Color.clear,
                        isGameOver ? skinColor.opacity(0.35) : skinColor.opacity(0.12),
                        isGameOver ? Color.purple.opacity(0.55) : Color.purple.opacity(0.20)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: isGameOver ? proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom : 260)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isGameOver)
                .ignoresSafeArea()
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                starOffset = 400
            }
        }
    }
}

private struct StarCanvas: View {
    var isRecordRun: Bool
    
    var body: some View {
        Canvas { ctx, size in
            for i in 0..<32 {
                let px = Double((i * 97) % 1000) / 1000.0 * size.width
                let py = Double((i * 137) % 1000) / 1000.0 * (size.height + 400) - 200
                let s = Double((i % 2) + 1)
                let rect = CGRect(x: px, y: py, width: s, height: s)
                
                let starColor: Color
                if isRecordRun && (i % 3 == 0) {
                    starColor = Color(red: 1.0, green: 0.88, blue: 0.45).opacity(0.85)
                } else {
                    starColor = Color.white.opacity(0.65)
                }
                
                ctx.fill(Path(ellipseIn: rect), with: .color(starColor))
            }
        }
    }
}

// MARK: - Landing Page View (Refined Retro Spacecraft)
struct LandingView: View {
    @ObservedObject var gameState: GameState
    @State private var orbFloat = false
    @State private var glowPulse = false
    @State private var currentSkinIndex = 0
    
    private let allSkins = PaddleSkin.allCases
    
    var currentSkin: PaddleSkin {
        allSkins[currentSkinIndex]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar: Stardust Bank
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.yellow)
                    Text("\(gameState.stardust)")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.white.opacity(0.08)))
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 56)
            
            // Retro Title
            VStack(spacing: 6) {
                Text("ORB PULSE")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: currentSkin.primaryColor.opacity(glowPulse ? 0.9 : 0.4), radius: glowPulse ? 22 : 12)
                
                Text("REFLEX ARCADE")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .tracking(4)
                    .foregroundColor(currentSkin.primaryColor.opacity(0.85))
            }
            .padding(.top, 14)
            
            Spacer()
            
            // Hero Showcase: Retro Spacecraft Paddle
            VStack(spacing: 24) {
                ZStack {
                    // Ambient Halo
                    Circle()
                        .fill(RadialGradient(colors: [currentSkin.primaryColor.opacity(0.35), .clear], center: .center, startRadius: 10, endRadius: 120))
                        .frame(width: 240, height: 240)
                    
                    // Luminous Target Orb
                    Circle()
                        .fill(currentSkin.primaryColor)
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                        .shadow(color: currentSkin.primaryColor, radius: 16)
                        .offset(y: orbFloat ? -22 : 4)
                    
                    // Spacecraft Paddle Visual
                    VStack(spacing: 0) {
                        ZStack {
                            // Dark Carbon Chassis with Cyber Bevel
                            CyberPaddleShape()
                                .fill(Color(red: 0.08, green: 0.09, blue: 0.14))
                                .frame(width: 120, height: 20)
                                .overlay(
                                    CyberPaddleShape()
                                        .stroke(currentSkin.primaryColor, lineWidth: 2)
                                        .shadow(color: currentSkin.primaryColor.opacity(0.8), radius: 8)
                                )
                            
                            // Luminous Plasma Core
                            Capsule()
                                .fill(currentSkin.primaryColor)
                                .frame(width: 86, height: 4)
                                .overlay(Capsule().stroke(Color.white, lineWidth: 1))
                                .shadow(color: currentSkin.primaryColor, radius: 6)
                        }
                        
                        // Unified Under-Engine Plasma Exhaust Plume
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [currentSkin.primaryColor.opacity(0.8), currentSkin.primaryColor.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 80, height: 14)
                            .blur(radius: 2)
                            .offset(y: -1)
                    }
                    .offset(y: 44)
                }
                .frame(height: 140)
                
                // Interactive Selector (< Skin Name >)
                HStack(spacing: 20) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            currentSkinIndex = (currentSkinIndex - 1 + allSkins.count) % allSkins.count
                            syncSkinSelection()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    
                    VStack(spacing: 4) {
                        Text(currentSkin.rawValue)
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        
                        let isUnlocked = gameState.unlockedSkins.contains(currentSkin.rawValue)
                        let isEquipped = gameState.selectedSkin == currentSkin
                        
                        if isEquipped {
                            Text("EQUIPPED")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.green.opacity(0.2)))
                        } else if isUnlocked {
                            Button(action: {
                                gameState.equipSkin(currentSkin)
                            }) {
                                Text("TAP TO EQUIP")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.white.opacity(0.18)))
                            }
                        } else {
                            Button(action: {
                                _ = gameState.unlockSkin(currentSkin)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "lock.fill").font(.system(size: 9))
                                    Text("UNLOCK • ✦ \(currentSkin.cost)")
                                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                }
                                .foregroundColor(gameState.stardust >= currentSkin.cost ? .black : .white.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill(gameState.stardust >= currentSkin.cost ? Color.yellow : Color.white.opacity(0.1))
                                )
                            }
                            .disabled(gameState.stardust < currentSkin.cost)
                        }
                    }
                    .frame(minWidth: 160)
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            currentSkinIndex = (currentSkinIndex + 1) % allSkins.count
                            syncSkinSelection()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                }
                
                // Pagination Dots
                HStack(spacing: 8) {
                    ForEach(0..<allSkins.count, id: \.self) { idx in
                        Circle()
                            .fill(idx == currentSkinIndex ? currentSkin.primaryColor : Color.white.opacity(0.2))
                            .frame(width: idx == currentSkinIndex ? 8 : 6, height: idx == currentSkinIndex ? 8 : 6)
                            .animation(.spring(), value: currentSkinIndex)
                    }
                }
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 25)
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if value.translation.width < -30 {
                                currentSkinIndex = (currentSkinIndex + 1) % allSkins.count
                            } else if value.translation.width > 30 {
                                currentSkinIndex = (currentSkinIndex - 1 + allSkins.count) % allSkins.count
                            }
                            syncSkinSelection()
                        }
                    }
            )
            
            Spacer()
            
            // Best Score Banner
            if gameState.highScore > 0 {
                HStack(spacing: 18) {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("BEST: \(gameState.highScore)")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    if gameState.lastScore > 0 {
                        Text("•").foregroundColor(.gray)
                        Text("LAST: \(gameState.lastScore)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 16)
            }
            
            // Play Button
            Button(action: {
                gameState.isInMenu = false
                gameState.restartTrigger.toggle()
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                    Text("PLAY")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(currentSkin.primaryColor)
                        .shadow(color: currentSkin.primaryColor.opacity(0.6), radius: 14, y: 4)
                )
            }
            .padding(.horizontal, 36)
            .padding(.bottom, 36)
        }
        .onAppear {
            if let idx = allSkins.firstIndex(of: gameState.selectedSkin) {
                currentSkinIndex = idx
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                orbFloat = true
                glowPulse = true
            }
        }
    }
    
    private func syncSkinSelection() {
        if gameState.unlockedSkins.contains(currentSkin.rawValue) {
            gameState.equipSkin(currentSkin)
        }
    }
}

// MARK: - Cyberpunk Beveled Polygon
private struct CyberPaddleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let b: CGFloat = 6.0
        path.move(to: CGPoint(x: rect.minX + b, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - b, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + b))
        path.addLine(to: CGPoint(x: rect.maxX - (b * 0.75), y: rect.maxY - b))
        path.addLine(to: CGPoint(x: rect.maxX - b * 2, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + b * 2, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + (b * 0.75), y: rect.maxY - b))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + b))
        path.closeSubpath()
        return path
    }
}


private struct ThrusterFlame: View {
    let color: Color
    
    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(LinearGradient(colors: [color, color.opacity(0)], startPoint: .top, endPoint: .bottom))
                .frame(width: 8, height: 16)
                .blur(radius: 1)
        }
    }
}

// MARK: - Paddle Cosmetic Locker Sheet
struct PaddleLockerModal: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.06, blue: 0.12).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PADDLE LOCKER")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("Customize your arcade aesthetic")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                        Text("\(gameState.stardust)")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.1)))
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Skin Cards
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(PaddleSkin.allCases) { skin in
                            skinCard(for: skin)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                }
                
                Button(action: { dismiss() }) {
                    Text("DONE")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.12)))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func skinCard(for skin: PaddleSkin) -> some View {
        let isUnlocked = gameState.unlockedSkins.contains(skin.rawValue)
        let isSelected = gameState.selectedSkin == skin
        
        return HStack(spacing: 16) {
            // Paddle Visual Preview
            RoundedRectangle(cornerRadius: 6)
                .fill(skin.primaryColor)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white, lineWidth: 1.5))
                .frame(width: 60, height: 14)
                .shadow(color: skin.primaryColor.opacity(0.7), radius: 6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(skin.rawValue)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                
                if isUnlocked {
                    Text(isSelected ? "EQUIPPED" : "UNLOCKED")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(isSelected ? .green : .gray)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text("\(skin.cost) STARDUST")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.yellow)
                }
            }
            
            Spacer()
            
            // Action Button
            if isUnlocked {
                Button(action: {
                    gameState.equipSkin(skin)
                }) {
                    Text(isSelected ? "IN USE" : "EQUIP")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(isSelected ? .black : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(isSelected ? skin.primaryColor : Color.white.opacity(0.15))
                        )
                }
                .disabled(isSelected)
            } else {
                Button(action: {
                    _ = gameState.unlockSkin(skin)
                }) {
                    Text("UNLOCK")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(gameState.stardust >= skin.cost ? .black : .gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(gameState.stardust >= skin.cost ? Color.yellow : Color.white.opacity(0.08))
                        )
                }
                .disabled(gameState.stardust < skin.cost)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(isSelected ? 0.08 : 0.03))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(isSelected ? skin.primaryColor.opacity(0.6) : Color.white.opacity(0.06), lineWidth: 1.5))
        )
    }
}

// MARK: - Game Over Modal (Clean, Cohesive Cyberpunk Summary)
struct GameOverModal: View {
    @ObservedObject var gameState: GameState
    var scene: GameScene
    
    @State private var glowPulse = false
    
    var isNewHigh: Bool {
        gameState.score >= gameState.highScore && gameState.score > 0
    }
    
    var skinColor: Color {
        gameState.selectedSkin.primaryColor
    }
    
    var body: some View {
        ZStack {
            // Transparent tap area to capture background replay taps
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture {
                    triggerReplay()
                }
            
            // Focused Arcade Card
            VStack(spacing: 16) {
                // Header Status
                VStack(spacing: 4) {
                    if isNewHigh {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 11))
                            Text("NEW RECORD")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .tracking(1.5)
                        }
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.yellow.opacity(0.18)))
                    }
                    
                    Text(isNewHigh ? "RECORD BREAKER" : "ROUND OVER")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: (isNewHigh ? Color.yellow : skinColor).opacity(0.8), radius: 10)
                }
                .padding(.top, 4)
                
                // Score Display
                VStack(spacing: 2) {
                    Text("FINAL SCORE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("\(gameState.score)")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: skinColor, radius: 12)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.04))
                )
                
                // Telemetry Badges
                HStack(spacing: 10) {
                    // Personal Best
                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.yellow)
                            Text("BEST")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Text("\(gameState.highScore)")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.04))
                    )
                    
                    // Total Stardust
                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 8))
                                .foregroundColor(.yellow)
                            Text("STARDUST")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Text("\(gameState.stardust)")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(.yellow)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.04))
                    )
                }
                
                // Action Controls
                HStack(spacing: 10) {
                    Button(action: {
                        gameState.lastScore = gameState.score
                        gameState.isGameOver = false
                        gameState.isInMenu = true
                        scene.clearScene()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "house.fill")
                            Text("MENU")
                        }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.08))
                        )
                    }
                    
                    Button(action: {
                        triggerReplay()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("PLAY AGAIN")
                        }
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            Capsule()
                                .fill(skinColor)
                                .shadow(color: skinColor.opacity(glowPulse ? 0.9 : 0.4), radius: glowPulse ? 12 : 6)
                        )
                    }
                }
                .padding(.top, 4)
                
                Text("TAP ANYWHERE TO REPLAY")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.bottom, 2)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.08, green: 0.08, blue: 0.14).opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(skinColor.opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 24)
            )
            .padding(.horizontal, 28)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
    
    private func triggerReplay() {
        gameState.isGameOver = false
        gameState.restartTrigger = true
    }
}

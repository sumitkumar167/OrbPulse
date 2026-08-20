//
//  UIComponents.swift
//  OrbPulse
//
//  Created by Sumit Kumar on 16/08/26.
//
import SwiftUI

// MARK: - Zero-Stutter Space Background (With Subtle Record-Breaker Horizon)
struct AnimatedSpaceBackground: View {
    @ObservedObject var gameState: GameState
    @State private var starOffset: CGFloat = 0
    
    var isFever: Bool { gameState.isFeverActive }
    var isRecordRun: Bool { gameState.hasBeatenHighScoreThisRun }
    
    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.03, blue: 0.06)
            
            RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.82, blue: 0.28).opacity(isRecordRun ? 0.15 : 0.0),
                    Color.clear
                ],
                center: .bottom,
                startRadius: 10,
                endRadius: 450
            )
            .animation(.easeInOut(duration: 1.2), value: isRecordRun)
            
            RadialGradient(
                colors: [Color.yellow.opacity(0.35), Color.clear],
                center: .bottom,
                startRadius: 20,
                endRadius: 400
            )
            .opacity(isFever ? 1.0 : 0.0)
            .animation(.linear(duration: 0.3), value: isFever)
            
            LinearGradient(
                colors: [
                    Color.clear,
                    isRecordRun ? Color.yellow.opacity(0.12) : Color.cyan.opacity(0.12),
                    isRecordRun ? Color(red: 0.85, green: 0.45, blue: 0.15).opacity(0.18) : Color.purple.opacity(0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 260)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .opacity(isFever ? 0.0 : 1.0)
            .animation(.easeInOut(duration: 0.8), value: isRecordRun)
            .animation(.linear(duration: 0.3), value: isFever)
            
            StarCanvas(isRecordRun: isRecordRun)
                .offset(y: starOffset)
                .animation(.easeInOut(duration: 1.0), value: isRecordRun)
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

// MARK: - Game Over Modal (With Next Skin Unlock Progress Bar)
struct GameOverModal: View {
    @ObservedObject var gameState: GameState
    var scene: GameScene
    
    var isNewHigh: Bool {
        gameState.score >= gameState.highScore && gameState.score > 0
    }
    
    var nextLockedSkin: PaddleSkin? {
        PaddleSkin.allCases.first { !gameState.unlockedSkins.contains($0.rawValue) }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    gameState.restartTrigger.toggle()
                }
            
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("GAME OVER")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    if isNewHigh {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                            Text("NEW HIGH SCORE")
                        }
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.yellow.opacity(0.2)))
                    }
                }
                
                // Score Box
                VStack(spacing: 14) {
                    VStack(spacing: 2) {
                        Text("FINAL SCORE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        Text("\(gameState.score)")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(gameState.selectedSkin.primaryColor)
                            .shadow(color: gameState.selectedSkin.primaryColor.opacity(0.5), radius: 12)
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    HStack(spacing: 28) {
                        VStack(spacing: 2) {
                            Text("BEST")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray)
                            Text("\(gameState.highScore)")
                                .font(.system(size: 17, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 2) {
                            Text("TOTAL STARDUST")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray)
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.caption2)
                                Text("\(gameState.stardust)")
                                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.yellow)
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.white.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.1), lineWidth: 1))
                )
                
                // ⚡️ Psychological Hook: Skin Unlock Progress Bar
                if let next = nextLockedSkin {
                    let progress = min(1.0, Double(gameState.stardust) / Double(next.cost))
                    VStack(spacing: 6) {
                        HStack {
                            Text("UNLOCK \(next.rawValue.uppercased())")
                                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                .foregroundColor(next.primaryColor)
                            Spacer()
                            Text("✦ \(gameState.stardust)/\(next.cost)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.1))
                                Capsule()
                                    .fill(next.primaryColor)
                                    .frame(width: g.size.width * CGFloat(progress))
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04)))
                }
                
                // Action Buttons
                HStack(spacing: 12) {
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
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.12)))
                    }
                    
                    Button(action: {
                        gameState.restartTrigger.toggle()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("RETRY")
                        }
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(gameState.selectedSkin.primaryColor).shadow(color: gameState.selectedSkin.primaryColor.opacity(0.5), radius: 10))
                    }
                }
                
                Text("TAP ANYWHERE TO REPLAY")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.top, -4)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(red: 0.08, green: 0.07, blue: 0.14))
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    .shadow(color: .black.opacity(0.6), radius: 30)
            )
            .padding(.horizontal, 22)
        }
    }
}
